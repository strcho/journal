import 'auth_token_store.dart';
import 'journal_api_client.dart';

class AuthSession {
  AuthSession({
    required this.client,
    AuthTokenStore? tokenStore,
  }) : tokenStore = tokenStore ?? const AuthTokenStore();

  final JournalApiClient client;
  final AuthTokenStore tokenStore;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final tokens = await client.login(email: email, password: password);
    await tokenStore.save(tokens);
    return tokens;
  }

  Future<AuthTokens> refresh() async {
    final tokens = await tokenStore.read();
    if (tokens == null) {
      throw StateError('No stored auth tokens.');
    }
    try {
      final refreshed = await client.refresh(
        refreshToken: tokens.refreshToken,
        deviceId: tokens.deviceId,
      );
      await tokenStore.save(refreshed);
      return refreshed;
    } on ApiException {
      await tokenStore.clear();
      rethrow;
    }
  }

  Future<void> clear() async {
    await tokenStore.clear();
  }

  Future<T> withAccessToken<T>(Future<T> Function(String token) action) async {
    final tokens = await tokenStore.read();
    if (tokens == null) {
      throw StateError('No stored auth tokens.');
    }
    try {
      return await action(tokens.accessToken);
    } on ApiException catch (error) {
      if (error.statusCode != 401) {
        rethrow;
      }
      final refreshed = await refresh();
      return action(refreshed.accessToken);
    }
  }
}
