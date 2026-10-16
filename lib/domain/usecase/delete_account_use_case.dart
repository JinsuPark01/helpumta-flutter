import '../../core/result.dart';
import '../entity/account_exception.dart';
import '../entity/auth_error.dart';
import '../entity/group.dart';
import '../entity/reauth_method.dart';
import '../repository/auth_repository.dart';
import '../repository/group_repository.dart';
import '../repository/user_repository.dart';
import 'leave_group_use_case.dart';

class DeleteAccountUseCase {
  const DeleteAccountUseCase(
      this._authRepository,
      this._groupRepository,
      this._leaveGroupUseCase,
      this._userRepository,
      );

  final AuthRepository _authRepository;
  final GroupRepository _groupRepository;
  final LeaveGroupUseCase _leaveGroupUseCase;
  final UserRepository _userRepository;

  /// 본인 확인 → 모든 그룹 탈퇴(내 기록 삭제 포함) → users 문서 삭제 → Auth 계정 삭제
  Future<Result<void>> call(ReauthMethod method) async {
    final userId = _authRepository.getCurrentUserId();
    if (userId == null) {
      return Result.error(Exception('로그인 상태가 아닙니다'));
    }

    // 0. 본인 확인은 데이터를 지우기 전에 먼저
    final reauthResult = switch (method) {
      PasswordReauth(:final password) =>
      await _authRepository.reauthenticateWithPassword(password),
      GoogleReauth() => await _authRepository.reauthenticateWithGoogle(),
    };
    if (reauthResult case Error(:final error)) {
      // 구글 계정 선택 취소는 실패가 아니라 그대로 전달
      if (error is AuthException &&
          error.error == AuthError.googleSignInCancelled) {
        return Result.error(error);
      }
      return Result.error(ReauthenticationFailedException(error));
    }

    // 1. 가입한 모든 그룹
    final List<Group> groups;
    switch (await _groupRepository.getGroups(userId)) {
      case Ok(:final value):
        groups = value;
      case Error(:final error):
        return Result.error(error);
    }

    // 2. 그룹마다 내 기록·이미지 삭제 → 탈퇴 (마지막 멤버면 그룹 삭제)
    for (final group in groups) {
      final leaveResult = await _leaveGroupUseCase(group.id);
      if (leaveResult case Error(:final error)) return Result.error(error);
    }

    // 3. users 문서 삭제 (Auth 삭제 후엔 권한이 없어지므로 먼저)
    final userResult = await _userRepository.deleteUser(userId);
    if (userResult case Error(:final error)) return Result.error(error);

    // 4. 마지막에 Auth 계정 삭제
    return _authRepository.deleteAccount();
  }
}