import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/date_utils.dart';
import '../../core/result.dart';
import '../../domain/entity/network_exception.dart';
import '../../domain/entity/workout_record.dart';
import '../../domain/usecase/delete_record_use_case.dart';
import '../../domain/usecase/get_current_user_id_use_case.dart';
import '../../domain/usecase/get_group_detail_use_case.dart';
import '../../domain/usecase/get_records_by_group_use_case.dart';
import '../../domain/usecase/has_wrote_today_use_case.dart';
import '../../domain/usecase/leave_group_use_case.dart';
import 'group_detail_event.dart';
import 'group_detail_state.dart';

class GroupDetailBloc extends Bloc<GroupDetailEvent, GroupDetailState> {
  GroupDetailBloc({
    required String groupId,
    required GetGroupDetailUseCase getGroupDetailUseCase,
    required GetRecordsByGroupUseCase getRecordsByGroupUseCase,
    required HasWroteTodayUseCase hasWroteTodayUseCase,
    required GetCurrentUserIdUseCase getCurrentUserIdUseCase,
    required DeleteRecordUseCase deleteRecordUseCase,
    required LeaveGroupUseCase leaveGroupUseCase,
  })  : _getGroupDetailUseCase = getGroupDetailUseCase,
        _getRecordsByGroupUseCase = getRecordsByGroupUseCase,
        _hasWroteTodayUseCase = hasWroteTodayUseCase,
        _getCurrentUserIdUseCase = getCurrentUserIdUseCase,
        _deleteRecordUseCase = deleteRecordUseCase,
        _leaveGroupUseCase = leaveGroupUseCase,
        super(GroupDetailState(
        groupId: groupId,
        selectedDate: DateTime.now().startOfDay,
      )) {
    on<GroupDetailStarted>(_onStarted);
    // 날짜를 빠르게 바꾸면 이전 요청 결과는 버리고 마지막 날짜만 반영
    on<GroupDetailDateChanged>(_onDateChanged, transformer: restartable());
    on<GroupDetailRefreshedToToday>(
      _onRefreshedToToday,
      transformer: restartable(),
    );
    // 처리 중 들어온 중복 요청은 무시 (네이티브 isLeaving 가드 역할)
    on<GroupDetailRecordDeleteRequested>(
      _onRecordDeleteRequested,
      transformer: droppable(),
    );
    on<GroupDetailLeaveRequested>(_onLeaveRequested, transformer: droppable());
  }

  final GetGroupDetailUseCase _getGroupDetailUseCase;
  final GetRecordsByGroupUseCase _getRecordsByGroupUseCase;
  final HasWroteTodayUseCase _hasWroteTodayUseCase;
  final GetCurrentUserIdUseCase _getCurrentUserIdUseCase;
  final DeleteRecordUseCase _deleteRecordUseCase;
  final LeaveGroupUseCase _leaveGroupUseCase;

  static const _recordsErrorMessage = '기록을 불러오지 못했습니다';

  Future<void> _onStarted(
      GroupDetailStarted event,
      Emitter<GroupDetailState> emit,
      ) async {
    final today = DateTime.now().startOfDay;
    emit(state.copyWith(
      status: GroupDetailStatus.loading,
      currentUserId: () => _getCurrentUserIdUseCase(),
      selectedDate: today,
    ));

    // 세 요청을 병렬 실행 (네이티브 supervisorScope + async 3개)
    final (groupResult, recordsResult, wroteResult) = await (
    _getGroupDetailUseCase(state.groupId),
    _getRecordsByGroupUseCase(groupId: state.groupId, date: today),
    _hasWroteTodayUseCase(state.groupId),
    ).wait;

    switch (groupResult) {
      case Ok(value: final group):
        emit(state.copyWith(
          status: GroupDetailStatus.success,
          group: () => group,
          records: _recordsOrEmpty(recordsResult),
          recordsErrorMessage: () =>
          recordsResult is Error ? _recordsErrorMessage : null,
          hasWroteToday: _boolOrFalse(wroteResult),
        ));
      case Error():
        emit(state.copyWith(status: GroupDetailStatus.failure));
    }
  }

  Future<void> _onDateChanged(
      GroupDetailDateChanged event,
      Emitter<GroupDetailState> emit,
      ) async {
    final date = event.date.startOfDay;
    // 미래 차단
    if (date.isAfter(DateTime.now().startOfDay)) return;

    // 날짜를 바꾸는 즉시 이전 날짜 기록은 지우고 로딩 표시
    emit(state.copyWith(
      selectedDate: date,
      records: const [],
      isRecordsLoading: true,
      recordsErrorMessage: () => null,
    ));

    final result = await _getRecordsByGroupUseCase(
      groupId: state.groupId,
      date: date,
    );

    emit(state.copyWith(
      records: _recordsOrEmpty(result),
      isRecordsLoading: false,
      recordsErrorMessage: () => result is Error ? _recordsErrorMessage : null,
    ));
  }

  Future<void> _onRefreshedToToday(
      GroupDetailRefreshedToToday event,
      Emitter<GroupDetailState> emit,
      ) async {
    final today = DateTime.now().startOfDay;
    emit(state.copyWith(
      selectedDate: today,
      records: const [],
      isRecordsLoading: true,
      recordsErrorMessage: () => null,
    ));

    final (recordsResult, wroteResult) = await (
    _getRecordsByGroupUseCase(groupId: state.groupId, date: today),
    _hasWroteTodayUseCase(state.groupId),
    ).wait;

    emit(state.copyWith(
      records: _recordsOrEmpty(recordsResult),
      isRecordsLoading: false,
      recordsErrorMessage: () =>
      recordsResult is Error ? _recordsErrorMessage : null,
      hasWroteToday: _boolOrFalse(wroteResult),
    ));
  }

  Future<void> _onRecordDeleteRequested(
      GroupDetailRecordDeleteRequested event,
      Emitter<GroupDetailState> emit,
      ) async {
    final target =
        state.records.where((record) => record.id == event.recordId).firstOrNull;

    emit(state.copyWith(
      deleteStatus: GroupDetailActionStatus.inProgress,
      actionErrorMessage: () => null,
    ));

    final result = await _deleteRecordUseCase(event.recordId);

    switch (result) {
      case Ok():
      // 오늘 기록을 지웠으면 다시 작성 가능
        final wasToday =
            target != null && target.createdAt.isSameDay(DateTime.now());
        emit(state.copyWith(
          deleteStatus: GroupDetailActionStatus.success,
          records: state.records
              .where((record) => record.id != event.recordId)
              .toList(),
          hasWroteToday: wasToday ? false : state.hasWroteToday,
        ));
      case Error(:final error):
        emit(state.copyWith(
          deleteStatus: GroupDetailActionStatus.failure,
          actionErrorMessage: () => error is NetworkUnavailableException
              ? '네트워크 연결을 확인해주세요'
              : '기록 삭제에 실패했어요. 다시 시도해주세요.',
        ));
    }
  }

  Future<void> _onLeaveRequested(
      GroupDetailLeaveRequested event,
      Emitter<GroupDetailState> emit,
      ) async {
    emit(state.copyWith(
      leaveStatus: GroupDetailActionStatus.inProgress,
      actionErrorMessage: () => null,
    ));

    final result = await _leaveGroupUseCase(state.groupId);

    switch (result) {
      case Ok():
        emit(state.copyWith(leaveStatus: GroupDetailActionStatus.success));
      case Error(:final error):
        emit(state.copyWith(
          leaveStatus: GroupDetailActionStatus.failure,
          actionErrorMessage: () => error is NetworkUnavailableException
              ? '네트워크 연결을 확인해주세요'
              : '그룹 나가기에 실패했어요. 다시 시도해주세요.',
        ));
    }
  }

  static List<WorkoutRecord> _recordsOrEmpty(
      Result<List<WorkoutRecord>> result,
      ) =>
      switch (result) {
        Ok(:final value) => value,
        Error() => const [],
      };

  static bool _boolOrFalse(Result<bool> result) => switch (result) {
    Ok(:final value) => value,
    Error() => false,
  };
}