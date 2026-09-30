import '../../core/result.dart';
import '../entity/group.dart';
import '../repository/auth_repository.dart';
import '../repository/group_repository.dart';

class GetGroupsUseCase {
  const GetGroupsUseCase(this._groupRepository, this._authRepository);

  final GroupRepository _groupRepository;
  final AuthRepository _authRepository;

  Future<Result<List<Group>>> call() async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인이 필요합니다'));
    }
    return _groupRepository.getGroups(userId);
  }
}