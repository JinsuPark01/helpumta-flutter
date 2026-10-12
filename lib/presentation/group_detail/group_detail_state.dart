import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../core/date_utils.dart';
import '../../domain/entity/group.dart';
import '../../domain/entity/workout_record.dart';

/// 그룹 정보 로딩 상태 (화면 전체)
enum GroupDetailStatus { loading, success, failure }

/// 삭제·탈퇴 같은 일회성 액션 상태
enum GroupDetailActionStatus { idle, inProgress, success, failure }

class GroupDetailState extends Equatable {
  const GroupDetailState({
    required this.groupId,
    required this.selectedDate,
    this.currentUserId,
    this.status = GroupDetailStatus.loading,
    this.group,
    this.records = const [],
    this.isRecordsLoading = false,
    this.recordsErrorMessage,
    this.hasWroteToday = false,
    this.deleteStatus = GroupDetailActionStatus.idle,
    this.leaveStatus = GroupDetailActionStatus.idle,
    this.actionErrorMessage,
  });

  final String groupId;

  /// 선택된 날짜 (로컬 00:00)
  final DateTime selectedDate;
  final String? currentUserId;
  final GroupDetailStatus status;
  final Group? group;
  final List<WorkoutRecord> records;
  final bool isRecordsLoading;
  final String? recordsErrorMessage;
  final bool hasWroteToday;
  final GroupDetailActionStatus deleteStatus;
  final GroupDetailActionStatus leaveStatus;

  /// 삭제·탈퇴 실패 시 스낵바 문구
  final String? actionErrorMessage;

  bool get isSelectedToday => selectedDate.isSameDay(DateTime.now());

  GroupDetailState copyWith({
    DateTime? selectedDate,
    ValueGetter<String?>? currentUserId,
    GroupDetailStatus? status,
    ValueGetter<Group?>? group,
    List<WorkoutRecord>? records,
    bool? isRecordsLoading,
    ValueGetter<String?>? recordsErrorMessage,
    bool? hasWroteToday,
    GroupDetailActionStatus? deleteStatus,
    GroupDetailActionStatus? leaveStatus,
    ValueGetter<String?>? actionErrorMessage,
  }) {
    return GroupDetailState(
      groupId: groupId,
      selectedDate: selectedDate ?? this.selectedDate,
      currentUserId:
      currentUserId != null ? currentUserId() : this.currentUserId,
      status: status ?? this.status,
      group: group != null ? group() : this.group,
      records: records ?? this.records,
      isRecordsLoading: isRecordsLoading ?? this.isRecordsLoading,
      recordsErrorMessage: recordsErrorMessage != null
          ? recordsErrorMessage()
          : this.recordsErrorMessage,
      hasWroteToday: hasWroteToday ?? this.hasWroteToday,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      leaveStatus: leaveStatus ?? this.leaveStatus,
      actionErrorMessage: actionErrorMessage != null
          ? actionErrorMessage()
          : this.actionErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
    groupId,
    selectedDate,
    currentUserId,
    status,
    group,
    records,
    isRecordsLoading,
    recordsErrorMessage,
    hasWroteToday,
    deleteStatus,
    leaveStatus,
    actionErrorMessage,
  ];
}