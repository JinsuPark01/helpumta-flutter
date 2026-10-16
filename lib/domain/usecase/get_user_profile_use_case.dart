import '../entity/user_profile.dart';
import '../repository/auth_repository.dart';

class GetUserProfileUseCase {
  const GetUserProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  UserProfile? call() {
    final email = _authRepository.getCurrentUserEmail();
    if (email == null) return null;
    final nickname = _authRepository.getCurrentUserName() ?? '사용자';
    return UserProfile(nickname: nickname, email: email);
  }
}