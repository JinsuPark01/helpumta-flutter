import '../../core/date_utils.dart';
import '../../core/result.dart';
import '../entity/record_exception.dart';
import '../repository/auth_repository.dart';
import '../repository/record_repository.dart';

class CreateRecordUseCase {
  const CreateRecordUseCase(this._recordRepository, this._authRepository);

  final RecordRepository _recordRepository;
  final AuthRepository _authRepository;

  Future<Result<String>> call({
    required String groupId,
    required String workoutType,
    required int workoutDuration,
    String? imagePath,
    required String comment,
  }) async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인이 필요합니다'));
    }

    // 하루 한 번 규칙: 화면(FAB)에만 맡기지 않고 저장 직전에 다시 확인
    final wroteResult = await _recordRepository.hasRecordSince(
      groupId: groupId,
      userId: userId,
      since: DateTime.now().startOfDay,
    );
    switch (wroteResult) {
      case Ok(value: true):
        return const Result.error(AlreadyWroteTodayException());
      case Error(:final error):
        return Result.error(error);
      case Ok():
        break;
    }

    return _recordRepository.createRecord(
      groupId: groupId,
      userId: userId,
      userName: _authRepository.getCurrentUserName() ?? '',
      workoutType: workoutType,
      workoutDuration: workoutDuration,
      imagePath: imagePath,
      comment: comment,
    );
  }
}