import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/campus_repository.dart';
import '../../domain/entities/classroom.dart';

sealed class CampusEvent extends Equatable {
  const CampusEvent();
  @override
  List<Object?> get props => [];
}

class CampusLoaded extends CampusEvent {
  const CampusLoaded();
}

class CampusCheckInRequested extends CampusEvent {
  final Classroom classroom;
  const CampusCheckInRequested(this.classroom);
  @override
  List<Object?> get props => [classroom];
}

class CampusState extends Equatable {
  final bool loading;
  final List<Classroom> classes;
  final List<CheckIn> history;
  final String? error;
  final String? info;
  final int? checkingInId;

  const CampusState({
    this.loading = false,
    this.classes = const [],
    this.history = const [],
    this.error,
    this.info,
    this.checkingInId,
  });

  CampusState copyWith({
    bool? loading,
    List<Classroom>? classes,
    List<CheckIn>? history,
    String? error,
    String? info,
    int? checkingInId,
  }) =>
      CampusState(
        loading: loading ?? this.loading,
        classes: classes ?? this.classes,
        history: history ?? this.history,
        error: error,
        info: info,
        checkingInId: checkingInId,
      );

  @override
  List<Object?> get props =>
      [loading, classes, history, error, info, checkingInId];
}

class CampusBloc extends Bloc<CampusEvent, CampusState> {
  final CampusRepository _repo;

  CampusBloc(this._repo) : super(const CampusState()) {
    on<CampusLoaded>(_onLoad);
    on<CampusCheckInRequested>(_onCheckIn);
  }

  Future<void> _onLoad(CampusLoaded e, Emitter<CampusState> emit) async {
    emit(state.copyWith(loading: true, error: null, info: null));
    try {
      final classes = await _repo.listClasses();
      final history = await _repo.history();
      emit(state.copyWith(
        loading: false,
        classes: classes,
        history: history,
      ));
    } on DioException catch (err) {
      emit(state.copyWith(loading: false, error: _humanize(err)));
    }
  }

  Future<void> _onCheckIn(
    CampusCheckInRequested e,
    Emitter<CampusState> emit,
  ) async {
    emit(state.copyWith(
      checkingInId: e.classroom.id,
      error: null,
      info: null,
    ));
    try {
      final perm = await _ensurePermission();
      if (!perm) {
        emit(state.copyWith(
          checkingInId: null,
          error: 'Permiso de ubicación denegado',
        ));
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      await _repo.checkIn(
        classroomId: e.classroom.id,
        lat: pos.latitude,
        lng: pos.longitude,
      );
      final history = await _repo.history();
      emit(state.copyWith(
        checkingInId: null,
        history: history,
        info: 'Asistencia registrada en ${e.classroom.name}',
      ));
    } on DioException catch (err) {
      emit(state.copyWith(checkingInId: null, error: _humanize(err)));
    } catch (err) {
      emit(state.copyWith(
        checkingInId: null,
        error: 'No se pudo obtener la ubicación',
      ));
    }
  }

  Future<bool> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var status = await Geolocator.checkPermission();
    if (status == LocationPermission.denied) {
      status = await Geolocator.requestPermission();
    }
    return status == LocationPermission.always ||
        status == LocationPermission.whileInUse;
  }

  String _humanize(DioException err) {
    final detail = err.response?.data;
    if (detail is Map && detail['detail'] is String) {
      final d = detail['detail'] as String;
      if (d.startsWith('out_of_geofence:')) {
        final meters = d.split(':').last;
        return 'Estás fuera del área del aula ($meters de distancia)';
      }
      if (d == 'invalid_credentials') return 'Credenciales inválidas';
      return d;
    }
    return err.message ?? 'Error de red';
  }
}
