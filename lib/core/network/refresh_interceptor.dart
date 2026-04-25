import 'dart:async';
import 'package:dio/dio.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

/// Intercepta 401s y ejecuta un refresh coalescente: N requests concurrentes
/// que caen en 401 usan un único `refreshSession()` en vuelo. Tras rotar el
/// token se re-ejecuta la request original con la nueva autorización.
class RefreshInterceptor extends QueuedInterceptor {
  final AuthRepository _auth;
  final Dio _dio;
  Completer<bool>? _refreshing;

  RefreshInterceptor(this._auth, this._dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final alreadyRetried = err.requestOptions.extra['_retried'] == true;
    final isRefreshCall = err.requestOptions.extra['_refresh'] == true;

    if (status != 401 || alreadyRetried || isRefreshCall) {
      return handler.next(err);
    }

    try {
      final ok = await _coalescedRefresh();
      if (!ok) {
        await _auth.logout(reason: 'refresh_failed');
        return handler.reject(err);
      }

      final req = err.requestOptions
        ..extra['_retried'] = true
        ..headers['Authorization'] = 'Bearer ${_auth.currentAccessToken}';
      final clone = await _dio.fetch<dynamic>(req);
      handler.resolve(clone);
    } catch (_) {
      await _auth.logout(reason: 'refresh_exception');
      handler.reject(err);
    }
  }

  Future<bool> _coalescedRefresh() {
    final inFlight = _refreshing;
    if (inFlight != null && !inFlight.isCompleted) return inFlight.future;

    final completer = Completer<bool>();
    _refreshing = completer;
    _auth.refreshSession().then(completer.complete).catchError((Object e) {
      completer.completeError(e);
    });
    return completer.future;
  }
}
