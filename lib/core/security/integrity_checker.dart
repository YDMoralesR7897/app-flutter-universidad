import 'package:flutter/foundation.dart';

/// Verifica que el dispositivo no esté comprometido antes de desbloquear la
/// sesión. En este scaffold académico se deja como no-op; para producción
/// enchufar un plugin de root/jailbreak detection compatible con AGP 8+
/// (p. ej. `freerasp`) y devolver `false` cuando se detecten indicadores.
class IntegrityChecker {
  IntegrityChecker._();
  static final instance = IntegrityChecker._();

  Future<bool> isDeviceSafe() async {
    if (kDebugMode) return true;
    return true; // TODO: integrar detector de root/jailbreak en producción.
  }

  Future<void> assertSafe() async {
    if (!await isDeviceSafe()) {
      throw StateError('device_integrity_compromised');
    }
  }
}
