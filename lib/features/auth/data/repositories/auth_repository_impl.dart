import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/security/secure_storage.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_ds.dart';
import '../models/token_pair_model.dart';


class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureSessionStorage _storage;

  // Access token exclusivamente en memoria. Se pierde al matar el proceso,
  // forzando a usar el refresh token (persistido seguro) en el siguiente arranque.
  String? _accessToken;
  Session? _session;

  AuthRepositoryImpl(this._remote, this._storage);

  @override
  String? get currentAccessToken => _accessToken;

  @override
  Future<Either<Failure, Session>> login({
    required String email,
    required String password,
  }) =>
      _auth(() => _remote.login(email, password));

  @override
  Future<Either<Failure, Session>> register({
    required String email,
    required String password,
  }) =>
      _auth(() => _remote.register(email, password));

  @override
  Future<Either<Failure, Session>> bootstrap() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh == null) return const Left(SessionExpiredFailure());
    return _auth(() => _remote.refresh(refresh));
  }

  @override
  Future<bool> refreshSession() async {
    final refresh = await _storage.readRefreshToken();
    if (refresh == null) return false;
    try {
      final pair = await _remote.refresh(refresh);
      await _apply(pair);
      return true;
    } on RefreshReuseException {
      await logout(reason: 'refresh_reuse');
      return false;
    } on UnauthorizedException {
      await logout(reason: 'refresh_unauthorized');
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> logout({String reason = 'user'}) async {
    final refresh = await _storage.readRefreshToken();
    if (refresh != null) await _remote.revoke(refresh);
    _accessToken = null;
    _session = null;
    await _storage.wipe();
  }

  Future<Either<Failure, Session>> _auth(
    Future<TokenPair> Function() call,
  ) async {
    try {
      final pair = await call();
      await _apply(pair);
      return Right(_session!);
    } on UnauthorizedException {
      return const Left(AuthFailure());
    } on RefreshReuseException {
      await logout(reason: 'refresh_reuse');
      return const Left(SessionExpiredFailure());
    } on ServerException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (_) {
      return const Left(UnknownFailure());
    }
  }

  Future<void> _apply(TokenPair pair) async {
    _accessToken = pair.accessToken;
    _session = Session(userId: pair.userId, email: pair.email);
    await _storage.persistRefreshToken(pair.refreshToken, pair.userId);
  }
}
