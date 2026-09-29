import '../../core/result.dart';
import '../entity/user.dart';
import '../repository/auth_repository.dart';

class GoogleLoginUseCase {
  const GoogleLoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<User>> call(String idToken) =>
      _authRepository.googleLogin(idToken);
}