import '../../core/result.dart';
import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';

class SaveUserUseCase {
  const SaveUserUseCase(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  /// 현재 로그인된 사용자 정보를 users에 upsert
  Future<Result<void>> call() async {
    final uid = _authRepository.getCurrentUserId();
    if (uid == null) {
      return Result.error(Exception('로그인 상태가 아닙니다'));
    }
    final nickname = _authRepository.getCurrentUserName() ?? '사용자';
    final email = _authRepository.getCurrentUserEmail() ?? '';
    return _userRepository.saveUser(
      uid: uid,
      nickname: nickname,
      email: email,
    );
  }
}