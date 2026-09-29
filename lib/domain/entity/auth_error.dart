enum AuthError {
  invalidCredential, // 이메일/비번 틀림 (보안상 합침)
  emailAlreadyInUse, // 이미 가입된 이메일
  weakPassword, // 비번 6자 미만
  network, // 네트워크 오류
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;
}