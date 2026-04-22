/// Custom API exception hierarchy for DKC HandyApp.
class ApiException implements Exception {
  const ApiException({required this.code, required this.message});

  final int code;
  final String message;

  @override
  String toString() => 'ApiException($code): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({String message = 'Nicht autorisiert'})
      : super(code: 401, message: message);
}

class ForbiddenException extends ApiException {
  const ForbiddenException({String message = 'Zugriff verweigert'})
      : super(code: 403, message: message);
}

class NotFoundException extends ApiException {
  const NotFoundException({String message = 'Nicht gefunden'})
      : super(code: 404, message: message);
}

class RateLimitException extends ApiException {
  const RateLimitException({required this.retryAfterSeconds})
      : super(
          code: 429,
          message: 'Zu viele Anfragen – bitte warten',
        );

  final int retryAfterSeconds;

  @override
  String toString() =>
      'RateLimitException: Bitte warten Sie $retryAfterSeconds Sekunden';
}

class NetworkException extends ApiException {
  const NetworkException({String message = 'Keine Netzwerkverbindung'})
      : super(code: 0, message: message);
}

class ServerException extends ApiException {
  const ServerException({int code = 500, String message = 'Serverfehler'})
      : super(code: code, message: message);
}
