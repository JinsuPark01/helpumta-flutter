import '../repository/auth_repository.dart';

class GetCurrentUserIdUseCase {
  const GetCurrentUserIdUseCase(this._authRepository);

  final AuthRepository _authRepository;

  String? call() => _authRepository.getCurrentUserId();
}