import '../../core/result.dart';

abstract interface class UserRepository {
  /// 있으면 갱신, 없으면 생성 (createdAt은 최초 생성 시만)
  Future<Result<void>> saveUser({
    required String uid,
    required String nickname,
    required String email,
  });

  /// uid 목록 → uid:nickname 맵 (닉네임이 없는 uid는 결과에서 빠짐)
  Future<Result<Map<String, String>>> getNicknames(List<String> uids);

  Future<Result<void>> deleteUser(String uid);
}