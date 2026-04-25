import 'dart:async';
import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/location_point.dart';

/// Modos de tracking. La app arranca en `passiveBalanced` y solo escala a
/// `activeHighAccuracy` cuando hay una pantalla/tarea activa que lo requiera.
enum TrackingMode { idle, activeHighAccuracy, passiveBalanced }

class LocationService {
  StreamSubscription<Position>? _sub;
  final _controller = StreamController<LocationPoint>.broadcast();
  TrackingMode _mode = TrackingMode.idle;

  Stream<LocationPoint> get stream => _controller.stream;
  TrackingMode get mode => _mode;

  /// Flujo escalado: whenInUse primero, background SOLO tras rationale.
  /// Requisito de Google Play: la UI debe explicar el uso antes de pedirlo.
  Future<bool> ensurePermissions({required bool background}) async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;

    final whenInUse = await Permission.locationWhenInUse.request();
    if (!whenInUse.isGranted) return false;

    if (background) {
      final always = await Permission.locationAlways.request();
      if (!always.isGranted) return false;
    }
    return true;
  }

  Future<void> start(TrackingMode mode) async {
    if (mode == TrackingMode.idle) {
      await stop();
      return;
    }
    if (_mode == mode && _sub != null) return;
    await stop();
    _mode = mode;

    final settings = _buildSettings(mode);
    _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (p) => _controller.add(LocationPoint(
        lat: p.latitude,
        lng: p.longitude,
        accuracy: p.accuracy,
        timestamp: p.timestamp,
      )),
      onError: (_) => stop(),
      cancelOnError: false,
    );
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _mode = TrackingMode.idle;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  LocationSettings _buildSettings(TrackingMode mode) {
    final high = mode == TrackingMode.activeHighAccuracy;
    final accuracy =
        high ? LocationAccuracy.high : LocationAccuracy.medium;
    final distanceFilter = high ? 10 : 50;
    final interval = high
        ? const Duration(seconds: 5)
        : const Duration(minutes: 2);

    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        intervalDuration: interval,
        foregroundNotificationConfig: high
            ? const ForegroundNotificationConfig(
                notificationTitle: 'Ubicación activa',
                notificationText: 'Registrando tu ruta',
                enableWakeLock: false,
              )
            : null,
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: true,
        showBackgroundLocationIndicator: high,
      );
    }
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }
}
