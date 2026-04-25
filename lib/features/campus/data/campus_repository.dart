import 'package:dio/dio.dart';

import '../domain/entities/classroom.dart';

class CampusRepository {
  final Dio _dio;
  CampusRepository(this._dio);

  Future<List<Classroom>> listClasses() async {
    final res = await _dio.get<List<dynamic>>('/classes');
    return res.data!
        .map((e) => Classroom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Devuelve el check-in creado. Propaga `DioException` cuando el servidor
  /// responde 400 (fuera de la geocerca) para que la UI muestre la distancia.
  Future<CheckIn> checkIn({
    required int classroomId,
    required double lat,
    required double lng,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/checkins',
      data: {
        'classroom_id': classroomId,
        'lat': lat,
        'lng': lng,
      },
    );
    return CheckIn.fromJson(res.data!);
  }

  Future<List<CheckIn>> history() async {
    final res = await _dio.get<List<dynamic>>('/checkins');
    return res.data!
        .map((e) => CheckIn.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
