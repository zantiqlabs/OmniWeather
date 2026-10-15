import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

class XweatherCredentials {
  const XweatherCredentials({
    required this.clientId,
    required this.clientSecret,
  });
  final String clientId;
  final String clientSecret;
}

/// Manages API credentials stored in the platform's secure keychain.
///
/// Credentials are only written by the Settings screen and are never
/// included in source control.
class AppSecrets {
  AppSecrets(this._storage);

  final FlutterSecureStorage _storage;

  Future<XweatherCredentials?> get xweatherCredentials async {
    final id     = await _storage.read(key: AppConstants.keyXweatherClientId);
    final secret = await _storage.read(key: AppConstants.keyXweatherClientSecret);
    if (id == null || secret == null || id.isEmpty || secret.isEmpty) {
      return null;
    }
    return XweatherCredentials(clientId: id, clientSecret: secret);
  }

  Future<void> saveXweatherCredentials({
    required String clientId,
    required String clientSecret,
  }) async {
    await _storage.write(
      key: AppConstants.keyXweatherClientId,
      value: clientId,
    );
    await _storage.write(
      key: AppConstants.keyXweatherClientSecret,
      value: clientSecret,
    );
  }

  Future<void> clearXweatherCredentials() async {
    await _storage.delete(key: AppConstants.keyXweatherClientId);
    await _storage.delete(key: AppConstants.keyXweatherClientSecret);
  }

  Future<bool> get hasXweatherCredentials async {
    return (await xweatherCredentials) != null;
  }
}

final appSecretsProvider = Provider<AppSecrets>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  return AppSecrets(storage);
});
