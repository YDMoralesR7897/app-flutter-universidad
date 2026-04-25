import 'package:dio/dio.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Inyecta el access token (en memoria) en cada request autenticado.
/// Endpoints públicos marcan `extra['public'] = true` para saltarse esto.
class AuthInterceptor extends Interceptor {
  final AuthRepository _auth;
  AuthInterceptor(this._auth);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = options.extra['public'] == true;
    final token = _auth.currentAccessToken;
    if (!isPublic && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
