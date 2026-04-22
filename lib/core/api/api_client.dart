import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';

/// Dio-based API client for DK-Control API v2.0.
/// All requests go to: https://<server>/api.php?action=<endpoint>
class ApiClient {
  ApiClient({required String baseUrl, required String? Function() tokenGetter})
      : _baseUrl = baseUrl,
        _tokenGetter = tokenGetter {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(tokenGetter: _tokenGetter),
      _ErrorInterceptor(),
      LogInterceptor(requestBody: false, responseBody: false),
    ]);
  }

  final String _baseUrl;
  final String? Function() _tokenGetter;
  late final Dio _dio;

  /// Perform a GET request.
  /// [action] is the value of the `action` query parameter.
  /// [queryParams] are additional query parameters.
  Future<dynamic> get(
    String action, {
    Map<String, dynamic>? queryParams,
  }) async {
    final params = <String, dynamic>{'action': action, ...?queryParams};
    final response = await _dio.get('/api.php', queryParameters: params);
    return response.data;
  }

  /// Perform a POST request.
  Future<dynamic> post(
    String action, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.post(
      '/api.php',
      queryParameters: {'action': action},
      data: body,
    );
    return response.data;
  }

  /// Perform a DELETE (via POST with body) request.
  Future<dynamic> delete(
    String action, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _dio.delete(
      '/api.php',
      queryParameters: {'action': action},
      data: body,
    );
    return response.data;
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required this.tokenGetter});

  final String? Function() tokenGetter;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenGetter();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final response = err.response;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      handler.reject(
        DioException(
          requestOptions: err.requestOptions,
          error: const NetworkException(),
          type: err.type,
        ),
      );
      return;
    }

    if (response != null) {
      final statusCode = response.statusCode ?? 0;
      switch (statusCode) {
        case 401:
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const UnauthorizedException(),
              response: response,
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        case 403:
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const ForbiddenException(),
              response: response,
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        case 404:
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: const NotFoundException(),
              response: response,
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        case 429:
          final retryAfter = _parseRetryAfter(response);
          handler.reject(
            DioException(
              requestOptions: err.requestOptions,
              error: RateLimitException(retryAfterSeconds: retryAfter),
              response: response,
              type: DioExceptionType.badResponse,
            ),
          );
          return;
        default:
          if (statusCode >= 500) {
            handler.reject(
              DioException(
                requestOptions: err.requestOptions,
                error: ServerException(
                  code: statusCode,
                  message: _extractMessage(response),
                ),
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
      }
    }

    handler.next(err);
  }

  int _parseRetryAfter(Response<dynamic> response) {
    try {
      final header = response.headers.value('Retry-After');
      if (header != null) return int.tryParse(header) ?? 60;
      final body = response.data;
      if (body is Map) {
        return (body['retry_after'] as num?)?.toInt() ?? 60;
      }
    } catch (_) {}
    return 60;
  }

  String _extractMessage(Response<dynamic> response) {
    try {
      final body = response.data;
      if (body is Map) {
        return body['message']?.toString() ?? 'Serverfehler';
      }
    } catch (_) {}
    return 'Serverfehler';
  }
}

/// Helper to extract the real exception from a DioException.
ApiException dioExceptionToApiException(DioException e) {
  if (e.error is ApiException) return e.error as ApiException;
  return NetworkException(message: e.message ?? 'Unbekannter Fehler');
}

/// Provider placeholder – actual provider is in core/providers.dart.
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('Override apiClientProvider with actual implementation');
});
