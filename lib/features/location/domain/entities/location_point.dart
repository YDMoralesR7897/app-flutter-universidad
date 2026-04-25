import 'package:equatable/equatable.dart';

class LocationPoint extends Equatable {
  final double lat;
  final double lng;
  final double accuracy;
  final DateTime timestamp;

  const LocationPoint({
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [lat, lng, accuracy, timestamp];
}
