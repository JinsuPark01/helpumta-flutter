import '../../core/result.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';
import 'save_user_use_case.dart';

class GoogleLoginUseCase {
  const GoogleLoginUseCase(this._authRepository, this._saveUserUseCase);

  final AuthRepository _authRepository;
  final SaveUserUseCase _saveUserUseCase;

  /// 구글 로그인 후 users 문서 upsert.
  /// 문서 저장 실패는 로그인 성공에 영향을 주지 않는다.
  Future<Result<User>> call() async {
    final result = await _authRepository.googleLogin();
    if (result is Ok<User>) {
      await _saveUserUseCase();
    }
    return result;
  }
}