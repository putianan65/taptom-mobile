import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../features/auth/auth_provider.dart';
import '../config/env.dart';
import 'api_exception.dart';
import 'demo/demo_interceptor.dart';

export 'api_exception.dart';

/// Single HTTP client for the app.
///
/// * Injects the bearer token on every request.
/// * On 401, refreshes the access token once (concurrent requests wait on the
///   same refresh) and replays the request; signs out if the refresh fails.
/// * Retries 429 responses with a short back-off.
/// * Converts every failure into an [ApiException] with a Thai message, so
///   callers only ever need to catch one type.
class ApiClient {
  factory ApiClient() => _instance;

  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        // Long enough for rural 3G, short enough not to feel frozen.
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
      if (Env.demoMode) DemoInterceptor(),
      if (kDebugMode && !Env.demoMode)
        PrettyDioLogger(
          requestBody: true,
          responseBody: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
    ]);
  }

  static final ApiClient _instance = ApiClient._();

  late final Dio _dio;

  /// Shared in-flight refresh, so parallel 401s trigger a single refresh.
  static Future<void>? _refreshing;

  static const _authPaths = [
    '/auth/refresh',
    '/auth/signin',
    '/auth/signup',
    '/auth/verify-pin',
    '/auth/set-pin',
  ];

  AuthProvider? get _auth =>
      GetIt.I.isRegistered<AuthProvider>() ? GetIt.I<AuthProvider>() : null;

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _auth?.accessToken;
    if (token != null && !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final path = error.requestOptions.path;
    final auth = _auth;
    final alreadyRetried = error.requestOptions.extra['retried'] == true;

    if (error.response?.statusCode != 401 ||
        auth == null ||
        alreadyRetried ||
        _authPaths.any(path.contains)) {
      return handler.next(error);
    }

    try {
      _refreshing ??= auth.refreshAccessToken().whenComplete(() {
        _refreshing = null;
      });
      await _refreshing;
    } catch (_) {
      // AuthProvider signs out on refresh failure; the router then returns
      // the user to sign-in.
      return handler.next(error);
    }

    final token = auth.accessToken;
    if (token == null) return handler.next(error);

    final request = error.requestOptions
      ..headers['Authorization'] = 'Bearer $token'
      ..extra['retried'] = true;
    try {
      handler.resolve(await _dio.fetch(request));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<Response> _send(
    Future<Response> Function() request, {
    int attempt = 0,
  }) async {
    try {
      return await request();
    } on DioException catch (e) {
      final status = e.response?.statusCode ?? 0;
      if (status == 429 && attempt < 2) {
        await Future.delayed(Duration(milliseconds: 800 * (attempt + 1)));
        return _send(request, attempt: attempt + 1);
      }
      throw _toApiException(e);
    }
  }

  static ApiException _toApiException(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final data = e.response?.data;

    String? server;
    if (data is Map && data['message'] != null) {
      final m = data['message'];
      server = m is List ? m.join(', ') : m.toString();
    }

    final String message;
    if (status == 0) {
      message = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง',
        DioExceptionType.cancel => 'ยกเลิกคำขอแล้ว',
        _ => 'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบสัญญาณ',
      };
    } else {
      message = switch (status) {
        400 => server ?? 'ข้อมูลไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง',
        401 => 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
        403 => 'คุณไม่มีสิทธิ์ทำรายการนี้',
        404 => 'ไม่พบข้อมูลที่ต้องการ',
        409 => server ?? 'ข้อมูลนี้มีอยู่ในระบบแล้ว',
        429 => 'ทำรายการถี่เกินไป กรุณารอสักครู่แล้วลองใหม่',
        >= 500 => 'ระบบขัดข้องชั่วคราว กรุณาลองใหม่ภายหลัง',
        _ => server ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง',
      };
    }

    return ApiException(
      statusCode: status,
      message: message,
      serverMessage: server,
      data: data,
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(() => _dio.get(path, queryParameters: queryParameters, options: options));

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(() => _dio.post(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(() => _dio.put(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(() => _dio.patch(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _send(() => _dio.delete(
            path,
            data: data,
            queryParameters: queryParameters,
            options: options,
          ));

  /// Raw GET for binary downloads (PDF reports).
  Future<Response<List<int>>> getBytes(String path) async {
    try {
      return await _dio.get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }
}
