import '../../core/result.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';

class EmailLoginUseCase {
  const EmailLoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<User>> call({
    required String email,
    required String password,
  }) =>
      _authRepository.emailLogin(email: email, password: password);
}