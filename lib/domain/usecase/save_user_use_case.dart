import '../../core/result.dart';
import '../repository/auth_repository.dart';
import '../repository/user_repository.dart';

class SaveUserUseCase {
  const SaveUserUseCase(this._authRepository, this._userRepository);

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  /// 현재 로그인된 사용자 정보를 users에 upsert.
  /// [nickname]을 넘기면 displayName 대신 그 값을 저장한다.
  Future<Result<void>> call({String? nickname}) async {
    final uid = _authRepository.getCurrentUserId();
    if (uid == null) {
      return Result.error(Exception('로그인 상태가 아닙니다'));
    }
    final resolvedNickname =
        nickname ?? _authRepository.getCurrentUserName() ?? '사용자';
    final email = _authRepository.getCurrentUserEmail() ?? '';
    return _userRepository.saveUser(
      uid: uid,
      nickname: resolvedNickname,
      email: email,
    );
  }
}