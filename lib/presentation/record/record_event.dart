sealed class RecordEvent {
  const RecordEvent();
}

/// 진입 시: 수정 모드면 기존 기록 로딩
final class RecordStarted extends RecordEvent {
  const RecordStarted();
}

final class RecordWorkoutTypeChanged extends RecordEvent {
  const RecordWorkoutTypeChanged(this.workoutType);

  final String workoutType;
}

/// 숫자·최대값 제한은 화면의 inputFormatters에서 처리된 값
final class RecordDurationChanged extends RecordEvent {
  const RecordDurationChanged(this.duration);

  final String duration;
}

final class RecordImagePicked extends RecordEvent {
  const RecordImagePicked(this.path);

  final String path;
}

final class RecordImageRemoved extends RecordEvent {
  const RecordImageRemoved();
}

final class RecordCommentChanged extends RecordEvent {
  const RecordCommentChanged(this.comment);

  final String comment;
}

final class RecordSubmitted extends RecordEvent {
  const RecordSubmitted();
}