enum AuthError {
  invalidCredential, // 이메일/비번 틀림 (보안상 합침)
  emailAlreadyInUse, // 이미 가입된 이메일
  weakPassword, // 비번 6자 미만
  network, // 네트워크 오류
  googleSignInCancelled, // 구글 계정 선택 취소 (에러 아님)
  googleAccountUnavailable, // 구글 토큰을 받지 못함
  unknown,
}

class AuthException implements Exception {
  const AuthException(this.error);

  final AuthError error;
}