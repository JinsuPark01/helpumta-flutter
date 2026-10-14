import 'package:equatable/equatable.dart';

/// 추출 카드의 한 칸: 기록한 멤버 / 기록하지 않은 멤버
sealed class ExtractSlot extends Equatable {
  const ExtractSlot({required this.nickname});

  final String nickname;
}

final class RecordedSlot extends ExtractSlot {
  const RecordedSlot({
    required super.nickname,
    required this.workoutType,
    required this.workoutDuration,
    required this.comment,
    required this.imageUrl,
  });

  final String workoutType;
  final int workoutDuration;
  final String comment;
  final String imageUrl;

  @override
  List<Object?> get props =>
      [nickname, workoutType, workoutDuration, comment, imageUrl];
}

final class EmptySlot extends ExtractSlot {
  const EmptySlot({required super.nickname});

  @override
  List<Object?> get props => [nickname];
}