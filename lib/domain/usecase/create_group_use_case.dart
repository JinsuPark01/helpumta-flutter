import '../../core/result.dart';
import '../repository/auth_repository.dart';
import '../repository/group_repository.dart';

class CreateGroupUseCase {
  const CreateGroupUseCase(this._groupRepository, this._authRepository);

  final GroupRepository _groupRepository;
  final AuthRepository _authRepository;

  Future<Result<String>> call({
    required String name,
    required String description,
    String? imagePath,
  }) async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인이 필요합니다'));
    }
    return _groupRepository.createGroup(
      userId: userId,
      name: name,
      description: description,
      imagePath: imagePath,
    );
  }
}