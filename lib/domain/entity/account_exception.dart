/// 계정 삭제 전 본인 확인(재인증) 실패. [cause]로 원인 구분 (네트워크 등)
class ReauthenticationFailedException implements Exception {
  const ReauthenticationFailedException(this.cause);

  final Exception cause;
}