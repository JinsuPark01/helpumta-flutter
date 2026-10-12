import '../../core/result.dart';
import '../entity/group.dart';

abstract interface class GroupRepository {
  Future<Result<List<Group>>> getGroups(String userId);

  Future<Result<Group>> getGroupById(String groupId);

  /// 성공 시 생성된 그룹 ID 반환.
  /// [imagePath]는 기기 내 이미지 파일 경로 (없으면 이미지 없는 그룹)
  Future<Result<String>> createGroup({
    required String userId,
    required String name,
    required String description,
    String? imagePath,
  });

  /// 마지막 멤버면 그룹 자체를 삭제
  Future<Result<void>> leaveGroup({
    required String groupId,
    required String userId,
  });
}