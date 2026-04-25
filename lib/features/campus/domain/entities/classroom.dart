import 'package:equatable/equatable.dart';

class Classroom extends Equatable {
  final int id;
  final String code;
  final String name;
  final double lat;
  final double lng;
  final int radiusM;

  const Classroom({
    required this.id,
    required this.code,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusM,
  });

  factory Classroom.fromJson(Map<String, dynamic> j) => Classroom(
        id: j['id'] as int,
        code: j['code'] as String,
        name: j['name'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        radiusM: j['radius_m'] as int,
      );

  @override
  List<Object?> get props => [id, code, name, lat, lng, radiusM];
}

class CheckIn extends Equatable {
  final int id;
  final int classroomId;
  final String classroomName;
  final double distanceM;
  final DateTime createdAt;

  const CheckIn({
    required this.id,
    required this.classroomId,
    required this.classroomName,
    required this.distanceM,
    required this.createdAt,
  });

  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        id: j['id'] as int,
        classroomId: j['classroom_id'] as int,
        classroomName: j['classroom_name'] as String,
        distanceM: (j['distance_m'] as num).toDouble(),
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  @override
  List<Object?> get props => [id, classroomId, createdAt];
}
