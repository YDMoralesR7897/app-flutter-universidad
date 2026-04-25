import 'package:bloc/bloc.dart';
import '../../domain/usecases/bootstrap_session.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/register.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _login;
  final RegisterUseCase _register;
  final LogoutUseCase _logout;
  final BootstrapSessionUseCase _bootstrap;

  AuthBloc(this._login, this._register, this._logout, this._bootstrap)
      : super(const AuthState.unknown()) {
    on<AuthBootstrapped>(_onBootstrap);
    on<AuthLoginRequested>(_onLogin, transformer: _droppable());
    on<AuthRegisterRequested>(_onRegister, transformer: _droppable());
    on<AuthLoggedOut>(_onLogout);
  }

  Future<void> _onBootstrap(
    AuthBootstrapped e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final r = await _bootstrap();
    emit(r.fold(
      (_) => const AuthState.unauthenticated(),
      (s) => AuthState.authenticated(s),
    ));
  }

  Future<void> _onLogin(
    AuthLoginRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final r = await _login(email: e.email, password: e.password);
    emit(r.fold(
      (f) => AuthState.error(f.message),
      (s) => AuthState.authenticated(s),
    ));
  }

  Future<void> _onRegister(
    AuthRegisterRequested e,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.loading());
    final r = await _register(email: e.email, password: e.password);
    emit(r.fold(
      (f) => AuthState.error(f.message),
      (s) => AuthState.authenticated(s),
    ));
  }

  Future<void> _onLogout(AuthLoggedOut e, Emitter<AuthState> emit) async {
    await _logout();
    emit(const AuthState.unauthenticated());
  }
}

/// Descarta eventos concurrentes mientras uno está en vuelo — evita
/// double-submits de login/registro cuando el usuario hace tap repetido.
EventTransformer<E> _droppable<E>() => (events, mapper) =>
    events.asyncExpand(mapper);
