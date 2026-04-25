import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Error de red']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Credenciales inválidas']);
}

class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure([super.message = 'Sesión expirada']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permiso denegado']);
}

class IntegrityFailure extends Failure {
  const IntegrityFailure([super.message = 'Dispositivo comprometido']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Error desconocido']);
}
