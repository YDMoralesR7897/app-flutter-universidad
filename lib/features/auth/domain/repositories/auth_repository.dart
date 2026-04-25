import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/session.dart';

/// Contrato del repositorio de autenticación. La implementación expone el
/// access token en memoria vía `currentAccessToken` para que los
/// interceptores HTTP puedan leerlo sin tocar almacenamiento persistente.
abstract class AuthRepository {
  String? get currentAccessToken;

  Future<Either<Failure, Session>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, Session>> register({
    required String email,
    required String password,
  });

  /// Intenta rehidratar la sesión usando el refresh token persistido.
  /// Rota el refresh token en cada llamada (detección de reuso = logout).
  Future<Either<Failure, Session>> bootstrap();

  /// Usado por el RefreshInterceptor. Devuelve true si el access token
  /// quedó renovado y el siguiente retry debería tener éxito.
  Future<bool> refreshSession();

  Future<void> logout({String reason = 'user'});
}
