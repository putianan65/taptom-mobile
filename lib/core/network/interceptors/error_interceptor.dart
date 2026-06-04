import 'package:dio/dio.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Log error
    print(
      '❌ API Error: [${err.response?.statusCode}] ${err.requestOptions.path}',
    );
    print('Messaging: ${err.message}');
    if (err.response?.data != null) {
      print('Data: ${err.response?.data}');
    }

    // You could wrap errors here, or just pass them through
    // For now, we pass through but ensure helpful logging
    return handler.next(err);
  }
}
