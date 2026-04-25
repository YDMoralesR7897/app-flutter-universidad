import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/session.dart';
import '../repositories/auth_repository.dart';

class BootstrapSessionUseCase {
  final AuthRepository _repo;
  BootstrapSessionUseCase(this._repo);

  Future<Either<Failure, Session>> call() => _repo.bootstrap();
}
