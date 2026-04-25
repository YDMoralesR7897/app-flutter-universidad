/// Configuración de red. Los valores reales deben inyectarse vía
/// `--dart-define` en CI para no vivir en el repo.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// SHA-256 de la clave pública del certificado del servidor.
  /// Se inyecta vía `--dart-define=API_CERT_SHA256=...`.
  static const String certSha256 = String.fromEnvironment(
    'API_CERT_SHA256',
    defaultValue: '',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
