import '../../core/result.dart';
import '../entity/record_image.dart';
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

  Future<Result<WorkoutRecord>> getRecordById(String recordId);

  /// 성공 시 생성된 기록 ID 반환
  Future<Result<String>> createRecord({
    required String groupId,
    required String userId,
    required String userName,
    required String workoutType,
    required int workoutDuration,
    String? imagePath,
    required String comment,
  });

  /// 본인 기록만 수정 가능
  Future<Result<void>> updateRecord({
    required String recordId,
    required String currentUserId,
    required String workoutType,
    required int workoutDuration,
    required RecordImage image,
    required String comment,
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