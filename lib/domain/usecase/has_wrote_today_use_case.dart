import '../../core/date_utils.dart';
import '../../core/result.dart';
import '../repository/auth_repository.dart';
import '../repository/record_repository.dart';

class HasWroteTodayUseCase {
  const HasWroteTodayUseCase(this._recordRepository, this._authRepository);

  final RecordRepository _recordRepository;
  final AuthRepository _authRepository;

  Future<Result<bool>> call(String groupId) async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인이 필요합니다'));
    }
    return _recordRepository.hasRecordSince(
      groupId: groupId,
      userId: userId,
      since: DateTime.now().startOfDay,
    );
  }
}