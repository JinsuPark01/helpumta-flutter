/// 계정 삭제 전 본인 확인 방법
sealed class ReauthMethod {
  const ReauthMethod();
}

final class PasswordReauth extends ReauthMethod {
  const PasswordReauth(this.password);

  final String password;
}

final class GoogleReauth extends ReauthMethod {
  const GoogleReauth();
}