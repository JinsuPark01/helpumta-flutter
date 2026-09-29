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

  Future<Result<User>> googleLogin(String idToken);

  String? getCurrentUserId();

  String? getCurrentUserName();

  String? getCurrentUserEmail();

  Future<void> logout();
}