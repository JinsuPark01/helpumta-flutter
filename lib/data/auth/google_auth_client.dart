import 'package:google_sign_in/google_sign_in.dart';

import '../../core/result.dart';
import '../../domain/entity/auth_error.dart';

/// 구글 계정 선택 → idToken 획득.
/// AuthRepositoryImpl 내부에서만 사용한다.
class GoogleAuthClient {
  GoogleAuthClient({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  /// 7.x부터 authenticate() 전에 initialize()가 반드시 한 번 필요.
  /// Android는 google-services.json의 웹 클라이언트(client_type: 3)를 자동으로 사용.
  Future<void> _ensureInitialized() async {
    final initialization = _initialization ??= _googleSignIn.initialize();
    try {
      await initialization;
    } catch (_) {
      // 실패하면 다음 시도에서 다시 초기화
      _initialization = null;
      rethrow;
    }
  }

  Future<Result<String>> getIdToken() async {
    try {
      await _ensureInitialized();

      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null) {
        return const Result.error(
          AuthException(AuthError.googleAccountUnavailable),
        );
      }
      return Result.ok(idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Result.error(
          AuthException(AuthError.googleSignInCancelled),
        );
      }
      return const Result.error(
        AuthException(AuthError.googleAccountUnavailable),
      );
    } on Exception {
      return const Result.error(
        AuthException(AuthError.googleAccountUnavailable),
      );
    }
  }

  /// 다음 로그인 때 이전 계정이 자동 선택되지 않도록 구글 세션 정리
  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } on Exception {
      // 구글 세션 정리 실패는 로그아웃 자체를 막지 않음
    }
  }
}