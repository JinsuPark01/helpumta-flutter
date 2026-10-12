import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entity/workout_record.dart';

extension WorkoutRecordMapper on DocumentSnapshot<Map<String, dynamic>> {
  /// groupId, userId가 없으면 잘못된 문서로 보고 null 반환
  WorkoutRecord? toWorkoutRecord() {
    final data = this.data();
    if (data == null) return null;

    final groupId = data['groupId'];
    final userId = data['userId'];
    if (groupId is! String || userId is! String) return null;

    String stringOf(String key) {
      final value = data[key];
      return value is String ? value : '';
    }

    final duration = data['workoutDuration'];
    final createdAt = data['createdAt'];

    return WorkoutRecord(
      id: id,
      groupId: groupId,
      userId: userId,
      userName: stringOf('userName'),
      workoutType: stringOf('workoutType'),
      workoutDuration: duration is num ? duration.toInt() : 0,
      imageUrl: stringOf('imageUrl'),
      comment: stringOf('comment'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        createdAt is num ? createdAt.toInt() : 0,
      ),
    );
  }
}