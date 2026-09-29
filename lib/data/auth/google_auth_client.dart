import 'package:google_sign_in/google_sign_in.dart';

import '../../core/result.dart';

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
        return Result.error(Exception('구글 로그인 응답이 올바르지 않습니다'));
      }
      return Result.ok(idToken);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return Result.error(Exception('로그인이 취소되었습니다'));
      }
      return Result.error(e);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}