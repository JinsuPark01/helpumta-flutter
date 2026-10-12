import '../../core/result.dart';
import '../entity/workout_record.dart';

abstract interface class RecordRepository {
  /// [start] 이상 [end] 미만, 최신순
  Future<Result<List<WorkoutRecord>>> getRecordsByGroup({
    required String groupId,
    required DateTime start,
    required DateTime end,
  });

  /// [since] 이후 해당 유저의 기록이 하나라도 있는지
  Future<Result<bool>> hasRecordSince({
    required String groupId,
    required String userId,
    required DateTime since,
  });

  /// 본인 기록만 삭제 가능
  Future<Result<void>> deleteRecord({
    required String recordId,
    required String currentUserId,
  });

  /// 그룹 내 해당 유저의 기록 전체 삭제 (그룹 탈퇴 시)
  Future<Result<void>> deleteRecordsByUserInGroup({
    required String groupId,
    required String userId,
  });
}