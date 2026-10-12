import '../../core/date_utils.dart';
import '../../core/result.dart';
import '../entity/record_exception.dart';
import '../entity/record_image.dart';
import '../repository/auth_repository.dart';
import '../repository/record_repository.dart';

class UpdateRecordUseCase {
  const UpdateRecordUseCase(this._recordRepository, this._authRepository);

  final RecordRepository _recordRepository;
  final AuthRepository _authRepository;

  Future<Result<void>> call({
    required String recordId,
    required String workoutType,
    required int workoutDuration,
    required RecordImage image,
    required String comment,
  }) async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인이 필요합니다'));
    }

    // 당일 수정 규칙: 수정 화면을 연 사이에 날짜가 바뀌는 경우까지 차단
    final recordResult = await _recordRepository.getRecordById(recordId);
    switch (recordResult) {
      case Error(:final error):
        return Result.error(error);
      case Ok(value: final record):
        if (!record.createdAt.isSameDay(DateTime.now())) {
          return const Result.error(RecordEditExpiredException());
        }
    }

    return _recordRepository.updateRecord(
      recordId: recordId,
      currentUserId: userId,
      workoutType: workoutType,
      workoutDuration: workoutDuration,
      image: image,
      comment: comment,
    );
  }
}