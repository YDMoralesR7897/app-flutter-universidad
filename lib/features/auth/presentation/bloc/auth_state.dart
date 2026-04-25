import 'package:equatable/equatable.dart';
import '../../domain/entities/session.dart';

enum AuthStatus { unknown, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final Session? session;
  final String? error;

  const AuthState._(this.status, {this.session, this.error});

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.loading() : this._(AuthStatus.loading);
  const AuthState.authenticated(Session s)
      : this._(AuthStatus.authenticated, session: s);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated);
  const AuthState.error(String message)
      : this._(AuthStatus.error, error: message);

  @override
  List<Object?> get props => [status, session, error];
}
