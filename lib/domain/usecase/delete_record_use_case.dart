import '../../core/result.dart';
import '../repository/auth_repository.dart';
import '../repository/record_repository.dart';

class DeleteRecordUseCase {
  const DeleteRecordUseCase(this._recordRepository, this._authRepository);

  final RecordRepository _recordRepository;
  final AuthRepository _authRepository;

  Future<Result<void>> call(String recordId) async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인이 필요합니다'));
    }
    return _recordRepository.deleteRecord(
      recordId: recordId,
      currentUserId: userId,
    );
  }
}