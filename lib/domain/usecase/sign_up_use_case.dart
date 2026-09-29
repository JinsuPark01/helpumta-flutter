import '../../core/result.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<User>> call({
    required String email,
    required String password,
    required String nickname,
  }) =>
      _authRepository.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );
}