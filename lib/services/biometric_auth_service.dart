import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../models/user_model.dart';
import 'auth_service.dart';

class BiometricStatus {
  const BiometricStatus({
    required this.isSupported,
    required this.availableBiometrics,
    required this.hasStoredCredentials,
  });

  final bool isSupported;
  final List<BiometricType> availableBiometrics;
  final bool hasStoredCredentials;
}

class BiometricCredentials {
  const BiometricCredentials({
    required this.email,
    required this.password,
    this.provider = 'email',
  });

  final String email;
  final String password;
  /// 'email' for email/password accounts, 'google' for Google Sign-In accounts.
  final String provider;
}

class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _emailKey    = 'biometric_email';
  static const _passwordKey = 'biometric_password';
  static const _providerKey = 'biometric_provider';

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  Future<BiometricStatus> getStatus() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      final biometrics = await _localAuth.getAvailableBiometrics();
      final credentials = await readCredentials();

      return BiometricStatus(
        isSupported: canCheck || isSupported,
        availableBiometrics: biometrics,
        hasStoredCredentials: credentials != null,
      );
    } catch (_) {
      return BiometricStatus(
        isSupported: false,
        availableBiometrics: const [],
        hasStoredCredentials: false,
      );
    }
  }

  Future<bool> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// Save email/password credentials for accounts that use email+password auth.
  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _emailKey,    value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(key: _providerKey, value: 'email');
  }

  /// Save credentials for Google Sign-In accounts (no password stored).
  Future<void> saveGoogleCredential({required String email}) async {
    await _secureStorage.write(key: _emailKey,    value: email);
    await _secureStorage.delete(key: _passwordKey);
    await _secureStorage.write(key: _providerKey, value: 'google');
  }

  Future<BiometricCredentials?> readCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    if (email == null || email.trim().isEmpty) return null;

    final provider = await _secureStorage.read(key: _providerKey) ?? 'email';

    if (provider == 'google') {
      return BiometricCredentials(email: email, password: '', provider: 'google');
    }

    final password = await _secureStorage.read(key: _passwordKey);
    if (password == null || password.isEmpty) return null;

    return BiometricCredentials(email: email, password: password);
  }

  Future<bool> hasStoredCredentials() async {
    return await readCredentials() != null;
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  Future<UserModel?> signInWithStoredCredentials(
    AuthService authService,
  ) async {
    final credentials = await readCredentials();
    if (credentials == null) return null;

    if (credentials.provider == 'google') {
      return authService.signInWithGoogleSilent();
    }

    return authService.login(
      email: credentials.email,
      password: credentials.password,
    );
  }
}
