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
  const BiometricCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class BiometricAuthService {
  BiometricAuthService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  }) : _localAuth = localAuth ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _emailKey = 'biometric_email';
  static const _passwordKey = 'biometric_password';

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

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _emailKey, value: email);
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  Future<BiometricCredentials?> readCredentials() async {
    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);

    if (email == null ||
        email.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

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

    return authService.login(
      email: credentials.email,
      password: credentials.password,
    );
  }
}
