import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../security/secure_storage.dart';
import '../api_endpoints.dart';
import '../../config/env.dart';

/// AuthInterceptor handles token attachment and automatic refresh
///
/// Backend specs:
/// - Access Token lifetime: 15 minutes
/// - Refresh Token lifetime: 7 days
/// - Refresh endpoint: POST /auth/refresh (Body only, no Auth header needed)
/// - Backend rotates refresh tokens (returns new refresh token on each refresh)
class AuthInterceptor extends Interceptor {
  final SecureStorage _storage = SecureStorage();
  final Dio _dio;
  
  // Prevent concurrent refresh requests
  bool _isRefreshing = false;
  final List<Function(String)> _refreshQueue = [];

  AuthInterceptor(this._dio);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Don't add token for login/signup/refresh
    if (options.path.contains('/auth/signin') ||
        options.path.contains('/auth/signup') ||
        options.path.contains('/auth/refresh')) {
      return handler.next(options);
    }

    // Check if token needs proactive refresh (within 2 min of expiry)
    final shouldRefresh = await _storage.shouldRefreshToken();
    if (shouldRefresh && !_isRefreshing) {
      print('⏰ Token expiring soon - proactive refresh...');
      final refreshed = await _performRefresh();
      if (refreshed != null) {
        options.headers['Authorization'] = 'Bearer $refreshed';
        return handler.next(options);
      }
    }

    final accessToken = await _storage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      print('🔑 Got 401 - attempting refresh token...');

      // If refresh token request fails, logout
      if (err.requestOptions.path.contains('/auth/refresh')) {
        print('❌ Refresh token request itself failed - clearing tokens');
        await _storage.clearTokens();
        _isRefreshing = false;
        // TODO: Trigger navigation to login
        return handler.next(err);
      }

      // Try refresh
      final refreshToken = await _storage.getRefreshToken();
      print('🔑 Refresh token exists: ${refreshToken != null}');

      if (refreshToken != null && refreshToken.isNotEmpty) {
        final newToken = await _performRefresh();
        if (newToken != null) {
          // Retry original request
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          try {
            final clonedResponse = await _dio.fetch(opts);
            print('✅ Retried original request successfully');
            return handler.resolve(clonedResponse);
          } catch (retryError) {
            print('❌ Retry failed: $retryError');
            return handler.next(err);
          }
        }
      } else {
        print('❌ No refresh token found - clearing tokens');
        await _storage.clearTokens();
      }
    }
    return handler.next(err);
  }

  /// Perform token refresh - returns new access token or null if failed
  Future<String?> _performRefresh() async {
    if (_isRefreshing) {
      // Wait for ongoing refresh
      print('⏳ Waiting for ongoing refresh...');
      return await _waitForRefresh();
    }

    _isRefreshing = true;
    final refreshToken = await _storage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      print('❌ No refresh token available');
      _isRefreshing = false;
      return null;
    }

    try {
      print('🔄 Calling refresh endpoint...');
      // Create new Dio instance to avoid infinite loops
      // Note: Backend only accepts refreshToken from body, not header
      final refreshDio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
      final response = await refreshDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
        // No Authorization header needed - /auth/refresh is @Public()
      );

      print('🔄 Refresh response status: ${response.statusCode}');

      // 🔍 DEBUG: Log RAW Refresh Response
      try {
        print('🔍 RAW Refresh Response: ${jsonEncode(response.data)}');
      } catch (e) {
        print('🔍 RAW Refresh Response (ToString): ${response.data}');
      }


      if (response.statusCode == 200 || response.statusCode == 201) {
        final newAccessToken = response.data['accessToken'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;

        print('✅ Got new access token: ${newAccessToken != null}');
        print('✅ Got new refresh token: ${newRefreshToken != null}');

        if (newAccessToken != null) {
          await _storage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken ?? refreshToken,
          );
          
          // Notify queued requests
          for (final callback in _refreshQueue) {
            callback(newAccessToken);
          }
          _refreshQueue.clear();
          _isRefreshing = false;
          return newAccessToken;
        }
      }
    } on DioException catch (e) {
      print('❌ Refresh failed with DioError: ${e.response?.statusCode} - ${e.message}');
      if (e.response?.statusCode == 401) {
        print('❌ Refresh token expired or invalid - clearing tokens');
        await _storage.clearTokens();
      }
    } catch (e) {
      print('❌ Refresh failed with error: $e');
    }

    _refreshQueue.clear();
    _isRefreshing = false;
    return null;
  }

  /// Wait for ongoing refresh to complete
  Future<String?> _waitForRefresh() async {
    final completer = Completer<String?>();
    _refreshQueue.add((token) => completer.complete(token));
    return await completer.future;
  }
}
