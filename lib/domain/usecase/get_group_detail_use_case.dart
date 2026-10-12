import '../../core/result.dart';
import '../entity/group.dart';
import '../repository/group_repository.dart';

class GetGroupDetailUseCase {
  const GetGroupDetailUseCase(this._groupRepository);

  final GroupRepository _groupRepository;

  Future<Result<Group>> call(String groupId) =>
      _groupRepository.getGroupById(groupId);
}