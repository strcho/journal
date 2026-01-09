import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  AppLockService._(this._auth);

  static const _storage = FlutterSecureStorage();
  static const _enabledKey = 'app_lock_enabled';
  static const _timeoutKey = 'app_lock_timeout_seconds';

  final LocalAuthentication _auth;
  final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> timeout =
      ValueNotifier<Duration>(const Duration(minutes: 5));

  static Future<AppLockService> create() async {
    final service = AppLockService._(LocalAuthentication());
    await service._load();
    return service;
  }

  Future<void> _load() async {
    final value = await _storage.read(key: _enabledKey);
    enabled.value = value == 'true';
    final timeoutValue = await _storage.read(key: _timeoutKey);
    final seconds = int.tryParse(timeoutValue ?? '');
    if (seconds != null) {
      timeout.value = Duration(seconds: seconds);
    }
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _storage.write(key: _enabledKey, value: value.toString());
  }

  Future<void> setTimeout(Duration value) async {
    timeout.value = value;
    await _storage.write(
      key: _timeoutKey,
      value: value.inSeconds.toString(),
    );
  }

  Future<bool> canAuthenticate() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported || canCheck;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
