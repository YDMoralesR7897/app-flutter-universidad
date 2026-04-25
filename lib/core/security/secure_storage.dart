import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento seguro de la sesión persistente.
///
/// Solo el refresh token y metadatos mínimos se persisten. El access token
/// vive exclusivamente en memoria (ver `AuthRepositoryImpl`) para reducir la
/// ventana de exposición ante un compromiso del almacenamiento.
class SecureSessionStorage {
  static const _kRefreshToken = 'auth.refresh_token';
  static const _kUserId = 'auth.user_id';

  final FlutterSecureStorage _storage;

  SecureSessionStorage()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            keyCipherAlgorithm:
                KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
            storageCipherAlgorithm:
                StorageCipherAlgorithm.AES_GCM_NoPadding,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
            synchronizable: false,
          ),
        );

  Future<void> persistRefreshToken(String token, String userId) async {
    await Future.wait([
      _storage.write(key: _kRefreshToken, value: token),
      _storage.write(key: _kUserId, value: userId),
    ]);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);
  Future<String?> readUserId() => _storage.read(key: _kUserId);

  Future<void> wipe() => _storage.deleteAll();
}
