import '../repository/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> call() => _authRepository.logout();
}