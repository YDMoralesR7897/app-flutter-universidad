import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_ds.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/bootstrap_session.dart';
import '../../features/auth/domain/usecases/login.dart';
import '../../features/auth/domain/usecases/logout.dart';
import '../../features/auth/domain/usecases/register.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/campus/data/campus_repository.dart';
import '../../features/campus/presentation/bloc/campus_bloc.dart';
import '../network/api_config.dart';
import '../network/auth_interceptor.dart';
import '../network/cert_pinning.dart';
import '../network/refresh_interceptor.dart';
import '../security/secure_storage.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Infraestructura
  getIt.registerLazySingleton(() => SecureSessionStorage());

  // Dio + repo de auth tienen dependencia circular (el refresh interceptor
  // llama al repo, y el repo usa Dio). Se rompe construyendo Dio primero y
  // registrando los interceptores una vez que el repo está disponible.
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: ApiConfig.connectTimeout,
    receiveTimeout: ApiConfig.receiveTimeout,
    contentType: 'application/json',
  ));
  getIt.registerSingleton<Dio>(dio);

  getIt.registerLazySingleton(() => AuthRemoteDataSource(getIt<Dio>()));
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<SecureSessionStorage>(),
    ),
  );

  final auth = getIt<AuthRepository>();
  dio.interceptors.addAll([
    CertPinningInterceptor(),
    AuthInterceptor(auth),
    RefreshInterceptor(auth, dio),
  ]);

  // Casos de uso
  getIt.registerFactory(() => LoginUseCase(getIt()));
  getIt.registerFactory(() => RegisterUseCase(getIt()));
  getIt.registerFactory(() => LogoutUseCase(getIt()));
  getIt.registerFactory(() => BootstrapSessionUseCase(getIt()));

  // Campus
  getIt.registerLazySingleton(() => CampusRepository(getIt<Dio>()));

  // Blocs
  getIt.registerFactory(
    () => AuthBloc(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerFactory(() => CampusBloc(getIt()));
}
