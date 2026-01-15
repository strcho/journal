import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'journal_api_client.dart';

class AuthTokenStore {
  const AuthTokenStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _deviceIdKey = 'auth_device_id';

  final FlutterSecureStorage _storage;

  Future<AuthTokens?> read() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final deviceId = await _storage.read(key: _deviceIdKey);
    if (accessToken == null || refreshToken == null || deviceId == null) {
      return null;
    }
    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      deviceId: deviceId,
    );
  }

  Future<void> save(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(key: _deviceIdKey, value: tokens.deviceId);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _deviceIdKey);
  }
}
