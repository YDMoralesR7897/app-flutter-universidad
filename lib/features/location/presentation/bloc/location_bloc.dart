import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/services/location_service.dart';
import '../../domain/entities/location_point.dart';

sealed class LocationEvent extends Equatable {
  const LocationEvent();
  @override
  List<Object?> get props => [];
}

class LocationStartRequested extends LocationEvent {
  final TrackingMode mode;
  final bool background;
  const LocationStartRequested({
    required this.mode,
    this.background = false,
  });
  @override
  List<Object?> get props => [mode, background];
}

class LocationStopRequested extends LocationEvent {
  const LocationStopRequested();
}

class _LocationReceived extends LocationEvent {
  final LocationPoint point;
  const _LocationReceived(this.point);
  @override
  List<Object?> get props => [point];
}

enum LocationStatus { idle, permissionDenied, tracking, error }

class LocationState extends Equatable {
  final LocationStatus status;
  final TrackingMode mode;
  final LocationPoint? last;
  final String? error;

  const LocationState({
    this.status = LocationStatus.idle,
    this.mode = TrackingMode.idle,
    this.last,
    this.error,
  });

  LocationState copyWith({
    LocationStatus? status,
    TrackingMode? mode,
    LocationPoint? last,
    String? error,
  }) =>
      LocationState(
        status: status ?? this.status,
        mode: mode ?? this.mode,
        last: last ?? this.last,
        error: error,
      );

  @override
  List<Object?> get props => [status, mode, last, error];
}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationService _service;
  StreamSubscription<LocationPoint>? _sub;

  LocationBloc(this._service) : super(const LocationState()) {
    on<LocationStartRequested>(_onStart);
    on<LocationStopRequested>(_onStop);
    on<_LocationReceived>(_onReceived);
  }

  Future<void> _onStart(
    LocationStartRequested e,
    Emitter<LocationState> emit,
  ) async {
    final ok = await _service.ensurePermissions(background: e.background);
    if (!ok) {
      emit(state.copyWith(status: LocationStatus.permissionDenied));
      return;
    }
    await _service.start(e.mode);
    await _sub?.cancel();
    _sub = _service.stream.listen((p) => add(_LocationReceived(p)));
    emit(state.copyWith(status: LocationStatus.tracking, mode: e.mode));
  }

  Future<void> _onStop(
    LocationStopRequested e,
    Emitter<LocationState> emit,
  ) async {
    await _sub?.cancel();
    _sub = null;
    await _service.stop();
    emit(state.copyWith(status: LocationStatus.idle, mode: TrackingMode.idle));
  }

  void _onReceived(_LocationReceived e, Emitter<LocationState> emit) {
    emit(state.copyWith(last: e.point, status: LocationStatus.tracking));
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _service.stop();
    return super.close();
  }
}
