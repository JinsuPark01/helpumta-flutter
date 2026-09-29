import '../../core/result.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';
import 'save_user_use_case.dart';

class SignUpUseCase {
  const SignUpUseCase(this._authRepository, this._saveUserUseCase);

  final AuthRepository _authRepository;
  final SaveUserUseCase _saveUserUseCase;

  /// 회원가입 후 users 문서 생성.
  /// 문서 저장이 실패해도 계정은 생성됐으므로 가입은 성공으로 본다.
  /// (다음 로그인 시 upsert로 복구 가능)
  Future<Result<User>> call({
    required String email,
    required String password,
    required String nickname,
  }) async {
    final result = await _authRepository.signUp(
      email: email,
      password: password,
      nickname: nickname,
    );
    if (result is Ok<User>) {
      await _saveUserUseCase(nickname: nickname);
    }
    return result;
  }
}