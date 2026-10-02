/// Error raised by [ApiClient] for any failed request. [message] is already
/// localised and safe to show to users.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.data,
    this.serverMessage,
  });

  /// HTTP status, or 0 when the request never reached the server.
  final int statusCode;

  /// User-facing Thai message.
  final String message;

  /// Raw `message` field from the server, if any.
  final String? serverMessage;

  final dynamic data;

  bool get isNetwork => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}
