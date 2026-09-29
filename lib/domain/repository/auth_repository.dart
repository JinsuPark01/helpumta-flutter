import '../../core/result.dart';
import '../entity/user.dart';

abstract interface class AuthRepository {
  Future<Result<User>> emailLogin({
    required String email,
    required String password,
  });

  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  /// 구글 계정 선택 + Firebase 로그인까지 처리
  Future<Result<User>> googleLogin();

  String? getCurrentUserId();

  String? getCurrentUserName();

  String? getCurrentUserEmail();

  Future<void> logout();
}