import '../../domain/entity/auth_error.dart';

extension AuthErrorMessage on AuthError {
  // TODO: 네이티브 toMessage() 문구와 다르면 맞춰서 교체
  String toMessage() => switch (this) {
    AuthError.invalidCredential => '이메일 또는 비밀번호가 올바르지 않습니다',
    AuthError.emailAlreadyInUse => '이미 사용 중인 이메일입니다',
    AuthError.weakPassword => '비밀번호는 6자 이상이어야 합니다',
    AuthError.network => '네트워크 연결을 확인해주세요',
    AuthError.googleSignInCancelled => '로그인이 취소되었습니다',
    AuthError.googleAccountUnavailable => '구글 계정을 가져올 수 없습니다',
    AuthError.unknown => '잠시 후 다시 시도해주세요',
  };
}

String authErrorMessageOf(Exception error, {required String fallback}) {
  return error is AuthException ? error.error.toMessage() : fallback;
}