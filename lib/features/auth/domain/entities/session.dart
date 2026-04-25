import 'package:equatable/equatable.dart';

class Session extends Equatable {
  final String userId;
  final String email;

  const Session({required this.userId, required this.email});

  @override
  List<Object?> get props => [userId, email];
}
