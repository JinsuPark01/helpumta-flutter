import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entity/record_image.dart';

/// 수정 모드에서 기존 기록 로딩 상태 (작성 모드는 바로 ready)
enum RecordLoadStatus { loading, ready, failure }

enum RecordSubmitStatus { idle, inProgress, success, failure }

class RecordState extends Equatable {
  const RecordState({
    required this.groupId,
    this.recordId,
    required this.loadStatus,
    this.workoutType = '',
    this.workoutDuration = '',
    this.image = const NoRecordImage(),
    this.comment = '',
    this.submitStatus = RecordSubmitStatus.idle,
    this.errorMessage,
  });

  final String groupId;

  /// null이면 작성 모드, 있으면 수정 모드
  final String? recordId;
  final RecordLoadStatus loadStatus;
  final String workoutType;

  /// 입력창 문자열 그대로 (빈 값 허용)
  final String workoutDuration;
  final RecordImage image;
  final String comment;
  final RecordSubmitStatus submitStatus;

  /// 저장 실패 시 스낵바 문구
  final String? errorMessage;

  bool get isEditMode => recordId != null;

  bool get isSubmitting => submitStatus == RecordSubmitStatus.inProgress;

  bool get isSubmitEnabled =>
      workoutType.trim().isNotEmpty && (int.tryParse(workoutDuration) ?? 0) > 0;

  RecordState copyWith({
    RecordLoadStatus? loadStatus,
    String? workoutType,
    String? workoutDuration,
    RecordImage? image,
    String? comment,
    RecordSubmitStatus? submitStatus,
    ValueGetter<String?>? errorMessage,
  }) {
    return RecordState(
      groupId: groupId,
      recordId: recordId,
      loadStatus: loadStatus ?? this.loadStatus,
      workoutType: workoutType ?? this.workoutType,
      workoutDuration: workoutDuration ?? this.workoutDuration,
      image: image ?? this.image,
      comment: comment ?? this.comment,
      submitStatus: submitStatus ?? this.submitStatus,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    groupId,
    recordId,
    loadStatus,
    workoutType,
    workoutDuration,
    image,
    comment,
    submitStatus,
    errorMessage,
  ];
}