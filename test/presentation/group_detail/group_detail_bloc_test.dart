import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpumta_flutter/core/date_utils.dart';
import 'package:helpumta_flutter/core/result.dart';
import 'package:helpumta_flutter/domain/entity/workout_record.dart';
import 'package:helpumta_flutter/domain/usecase/delete_record_use_case.dart';
import 'package:helpumta_flutter/domain/usecase/get_current_user_id_use_case.dart';
import 'package:helpumta_flutter/domain/usecase/get_group_detail_use_case.dart';
import 'package:helpumta_flutter/domain/usecase/get_records_by_group_use_case.dart';
import 'package:helpumta_flutter/domain/usecase/has_wrote_today_use_case.dart';
import 'package:helpumta_flutter/domain/usecase/leave_group_use_case.dart';
import 'package:helpumta_flutter/presentation/group_detail/group_detail_bloc.dart';
import 'package:helpumta_flutter/presentation/group_detail/group_detail_event.dart';
import 'package:helpumta_flutter/presentation/group_detail/group_detail_state.dart';

/// 삭제는 항상 성공
class FakeDeleteRecordUseCase extends Fake implements DeleteRecordUseCase {
  @override
  Future<Result<void>> call(String recordId) async => const Result.ok(null);
}

// 이 테스트에서 쓰지 않는 UseCase들 (호출되면 Fake가 에러를 던져 알려줌)
class UnusedGetGroupDetailUseCase extends Fake
    implements GetGroupDetailUseCase {}

class UnusedGetRecordsByGroupUseCase extends Fake
    implements GetRecordsByGroupUseCase {}

class UnusedHasWroteTodayUseCase extends Fake implements HasWroteTodayUseCase {}

class UnusedGetCurrentUserIdUseCase extends Fake
    implements GetCurrentUserIdUseCase {}

class UnusedLeaveGroupUseCase extends Fake implements LeaveGroupUseCase {}

void main() {
  const groupId = 'group1';
  const myUserId = 'user1';

  WorkoutRecord recordCreatedAt(DateTime createdAt) => WorkoutRecord(
    id: 'record1',
    groupId: groupId,
    userId: myUserId,
    userName: '진수',
    workoutType: '헬스',
    workoutDuration: 60,
    imageUrl: '',
    comment: '',
    createdAt: createdAt,
  );

  GroupDetailBloc buildBloc() => GroupDetailBloc(
    groupId: groupId,
    getGroupDetailUseCase: UnusedGetGroupDetailUseCase(),
    getRecordsByGroupUseCase: UnusedGetRecordsByGroupUseCase(),
    hasWroteTodayUseCase: UnusedHasWroteTodayUseCase(),
    getCurrentUserIdUseCase: UnusedGetCurrentUserIdUseCase(),
    deleteRecordUseCase: FakeDeleteRecordUseCase(),
    leaveGroupUseCase: UnusedLeaveGroupUseCase(),
  );

  GroupDetailState loadedStateWith(WorkoutRecord record) => GroupDetailState(
    groupId: groupId,
    selectedDate: record.createdAt.startOfDay,
    currentUserId: myUserId,
    status: GroupDetailStatus.success,
    records: [record],
    hasWroteToday: true,
  );

  group('기록 삭제', () {
    final todayState = loadedStateWith(recordCreatedAt(DateTime.now()));

    blocTest<GroupDetailBloc, GroupDetailState>(
      '오늘 기록을 삭제하면 목록에서 빠지고 다시 작성할 수 있게 된다',
      build: buildBloc,
      seed: () => todayState,
      act: (bloc) => bloc.add(const GroupDetailRecordDeleteRequested('record1')),
      expect: () => [
        todayState.copyWith(deleteStatus: GroupDetailActionStatus.inProgress),
        todayState.copyWith(
          deleteStatus: GroupDetailActionStatus.success,
          records: const [],
          hasWroteToday: false,
        ),
      ],
    );

    final yesterdayState = loadedStateWith(
      recordCreatedAt(DateTime.now().addDays(-1)),
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      '지난 날짜 기록을 삭제해도 오늘 작성 여부는 그대로다',
      build: buildBloc,
      seed: () => yesterdayState,
      act: (bloc) => bloc.add(const GroupDetailRecordDeleteRequested('record1')),
      expect: () => [
        yesterdayState.copyWith(
          deleteStatus: GroupDetailActionStatus.inProgress,
        ),
        yesterdayState.copyWith(
          deleteStatus: GroupDetailActionStatus.success,
          records: const [],
          // 어제 기록이라 오늘 작성 여부는 바뀌지 않음
          hasWroteToday: true,
        ),
      ],
    );
  });
}