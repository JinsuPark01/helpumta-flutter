import '../entity/auth_provider.dart';
import '../repository/auth_repository.dart';

class GetAuthProviderUseCase {
  const GetAuthProviderUseCase(this._authRepository);

  final AuthRepository _authRepository;

  AuthProvider call() => _authRepository.getAuthProvider();
}