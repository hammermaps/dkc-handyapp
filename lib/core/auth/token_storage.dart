import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure storage for auth token, user info, and server URL.
class TokenStorage {
  TokenStorage() : _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );

  final FlutterSecureStorage _storage;

  static const _keyToken = 'auth_token';
  static const _keyUserInfo = 'user_info';
  static const _keyServerUrl = 'server_url';

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> deleteToken() => _storage.delete(key: _keyToken);

  Future<void> saveUserInfo(String json) =>
      _storage.write(key: _keyUserInfo, value: json);

  Future<String?> getUserInfo() => _storage.read(key: _keyUserInfo);

  Future<void> deleteUserInfo() => _storage.delete(key: _keyUserInfo);

  Future<void> saveServerUrl(String url) =>
      _storage.write(key: _keyServerUrl, value: url);

  Future<String?> getServerUrl() => _storage.read(key: _keyServerUrl);

  Future<void> clearAll() => _storage.deleteAll();
}
