import '../../core/result.dart';
import '../entity/group.dart';

abstract interface class GroupRepository {
  Future<Result<List<Group>>> getGroups(String userId);
}