import 'package:equatable/equatable.dart';

class WorkoutRecord extends Equatable {
  const WorkoutRecord({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.userName,
    required this.workoutType,
    required this.workoutDuration,
    required this.imageUrl,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String userId;
  final String userName;
  final String workoutType;

  /// 분 단위
  final int workoutDuration;
  final String imageUrl;
  final String comment;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    groupId,
    userId,
    userName,
    workoutType,
    workoutDuration,
    imageUrl,
    comment,
    createdAt,
  ];
}