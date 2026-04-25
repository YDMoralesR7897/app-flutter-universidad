import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/session.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repo;
  RegisterUseCase(this._repo);

  Future<Either<Failure, Session>> call({
    required String email,
    required String password,
  }) =>
      _repo.register(email: email, password: password);
}
