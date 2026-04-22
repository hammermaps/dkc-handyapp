import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/token_storage.dart';
import '../../../shared/models/permissions_model.dart';
import '../../../shared/models/user_model.dart';

/// Repository handling authentication and user account operations.
class AuthRepository {
  AuthRepository({
    required TokenStorage tokenStorage,
    required ApiClient Function(String baseUrl) apiClientFactory,
  })  : _tokenStorage = tokenStorage,
        _apiClientFactory = apiClientFactory;

  final TokenStorage _tokenStorage;
  final ApiClient Function(String baseUrl) _apiClientFactory;

  ApiClient? _client;

  Future<ApiClient> _getClient() async {
    if (_client != null) return _client!;
    final url = await _tokenStorage.getServerUrl();
    if (url == null || url.isEmpty) {
      throw const NetworkException(message: 'Server-URL nicht konfiguriert');
    }
    _client = _apiClientFactory(url);
    return _client!;
  }

  /// Log in with [username] and [password] against [serverUrl].
  /// Saves the token and user info on success.
  Future<UserModel> login({
    required String username,
    required String password,
    required String serverUrl,
  }) async {
    final normalizedUrl =
        serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;

    await _tokenStorage.saveServerUrl(normalizedUrl);
    _client = _apiClientFactory(normalizedUrl);

    try {
      final data = await _client!.post('auth_login', body: {
        'username': username,
        'password': password,
        'token_name': 'DKC HandyApp',
        'ttl_days': 30,
      });

      final token = data['token'] as String?;
      if (token == null) {
        throw const ApiException(code: 0, message: 'Kein Token erhalten');
      }
      await _tokenStorage.saveToken(token);

      // Re-create client with token
      final String? currentToken = await _tokenStorage.getToken();
      _client = ApiClient(
        baseUrl: normalizedUrl,
        tokenGetter: () => currentToken,
      );

      // Load user info
      final user = await getUserInfo();
      return user;
    } on DioException catch (e) {
      throw dioExceptionToApiException(e);
    }
  }

  /// Log out by calling the API and clearing local storage.
  Future<void> logout() async {
    try {
      final client = await _getClient();
      await client.post('auth_logout');
    } catch (_) {
      // Always clear local state even if the API call fails
    } finally {
      await _tokenStorage.clearAll();
      _client = null;
    }
  }

  /// Check if the current token is valid.
  Future<bool> getAuthStatus() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final client = await _getClient();
      final data = await client.get('auth_status');
      return data['authenticated'] == true;
    } on UnauthorizedException {
      return false;
    } on DioException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Fetch current user info (including permissions).
  Future<UserModel> getUserInfo() async {
    final client = await _getClient();
    try {
      final data = await client.get('user_info');
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _tokenStorage.saveUserInfo(jsonEncode(data));
      return user;
    } on DioException catch (e) {
      throw dioExceptionToApiException(e);
    }
  }

  /// Returns user info from secure storage without API call.
  Future<Map<String, dynamic>?> getCachedUserData() async {
    final raw = await _tokenStorage.getUserInfo();
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Returns permissions from cached user data.
  Future<PermissionsModel?> getCachedPermissions() async {
    final data = await getCachedUserData();
    if (data == null) return null;
    final perms = data['permissions'];
    if (perms is Map<String, dynamic>) {
      return PermissionsModel.fromJson(perms);
    }
    return null;
  }

  /// List all tokens for the current user.
  Future<List<Map<String, dynamic>>> getUserTokens() async {
    final client = await _getClient();
    try {
      final data = await client.get('user_tokens_list');
      final list = data['tokens'] as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw dioExceptionToApiException(e);
    }
  }

  /// Delete a specific token by [tokenId].
  Future<void> deleteToken(int tokenId) async {
    final client = await _getClient();
    try {
      await client.post('user_token_delete', body: {'token_id': tokenId});
    } on DioException catch (e) {
      throw dioExceptionToApiException(e);
    }
  }
}
