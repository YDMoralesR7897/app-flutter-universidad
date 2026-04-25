import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/token_pair_model.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  AuthRemoteDataSource(this._dio);

  Future<TokenPair> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<TokenPair> register(String email, String password) =>
      _post('/auth/register', {'email': email, 'password': password});

  Future<TokenPair> refresh(String refreshToken) => _post(
        '/auth/refresh',
        {'refresh_token': refreshToken},
        extra: {'_refresh': true},
      );

  Future<void> revoke(String refreshToken) async {
    try {
      await _dio.post<dynamic>(
        '/auth/logout',
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'public': true}),
      );
    } on DioException {
      // Logout best-effort: si falla la red, el wipe local ya invalida
      // la sesión en el dispositivo.
    }
  }

  Future<TokenPair> _post(
    String path,
    Map<String, dynamic> body, {
    Map<String, dynamic>? extra,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        options: Options(extra: {'public': true, ...?extra}),
      );
      return TokenPair.fromJson(res.data!);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) throw UnauthorizedException();
      if (code == 409 || code == 410) throw RefreshReuseException();
      throw ServerException(e.message ?? 'network_error', statusCode: code);
    }
  }
}
