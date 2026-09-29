import '../../core/result.dart';

abstract interface class UserRepository {
  /// 있으면 갱신, 없으면 생성 (createdAt은 최초 생성 시만)
  Future<Result<void>> saveUser({
    required String uid,
    required String nickname,
    required String email,
  });
}