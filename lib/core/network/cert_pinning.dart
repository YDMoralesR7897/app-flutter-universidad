import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import 'api_config.dart';

/// SSL pinning: valida el SHA-256 de la clave pública del certificado del
/// servidor antes de enviar el request. Si no hay pin configurado (dev), no
/// se instala el interceptor y el cliente opera con validación TLS estándar.
class CertPinningInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final pin = ApiConfig.certSha256;
    if (pin.isEmpty) return handler.next(options);

    try {
      await HttpCertificatePinning.check(
        serverURL: options.uri.origin,
        headerHttp: const {},
        sha: SHA.SHA256,
        allowedSHAFingerprints: [pin],
        timeout: 10,
      );
      handler.next(options);
    } catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: 'cert_pinning_failed',
          type: DioExceptionType.badCertificate,
        ),
      );
    }
  }
}
