import '../../core/result.dart';
import '../repository/auth_repository.dart';
import '../repository/group_repository.dart';
import '../repository/record_repository.dart';

class LeaveGroupUseCase {
  const LeaveGroupUseCase(
      this._authRepository,
      this._groupRepository,
      this._recordRepository,
      );

  final AuthRepository _authRepository;
  final GroupRepository _groupRepository;
  final RecordRepository _recordRepository;

  /// 내 기록·이미지 먼저 삭제 → 그룹에서 나가기 (0명이면 그룹 삭제)
  Future<Result<void>> call(String groupId) async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인 상태가 아닙니다'));
    }

    final deleteResult = await _recordRepository.deleteRecordsByUserInGroup(
      groupId: groupId,
      userId: userId,
    );
    if (deleteResult is Error<void>) return deleteResult;

    return _groupRepository.leaveGroup(groupId: groupId, userId: userId);
  }
}