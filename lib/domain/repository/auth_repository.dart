import '../../core/result.dart';
import '../entity/auth_provider.dart';
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

  AuthProvider getAuthProvider();

  Future<Result<void>> reauthenticateWithPassword(String password);

  /// 구글 계정 선택 + 재인증까지 처리
  Future<Result<void>> reauthenticateWithGoogle();

  /// Auth 계정 삭제 (재인증 직후 호출해야 함)
  Future<Result<void>> deleteAccount();

  Future<void> logout();
}