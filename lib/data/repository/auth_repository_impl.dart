import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/result.dart';
import '../../domain/entity/auth_error.dart';
import '../../domain/entity/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../auth/google_auth_client.dart';
import '../mapper/user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseAuth, this._googleAuthClient);

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleAuthClient _googleAuthClient;

  @override
  Future<Result<User>> emailLogin({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return Result.error(Exception('유저 정보를 가져올 수 없습니다'));
      }
      return Result.ok(firebaseUser.toDomain());
    } on Exception catch (e) {
      return Result.error(AuthException(e.toAuthError()));
    }
  }

  @override
  Future<Result<User>> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return Result.error(Exception('회원가입에 실패했습니다'));
      }

      // 계정은 이미 생성됐으므로 닉네임 설정 실패는 가입 실패로 보지 않는다.
      // (users 문서에는 닉네임이 별도로 저장되고, displayName이 없으면
      //  getCurrentUserName()이 이메일 앞부분으로 대체한다)
      try {
        await firebaseUser.updateDisplayName(nickname);
        await firebaseUser.reload();
      } on Exception {
        // 무시
      }

      return Result.ok(firebaseUser.toDomain());
    } on Exception catch (e) {
      return Result.error(AuthException(e.toAuthError()));
    }
  }

  @override
  Future<Result<User>> googleLogin() async {
    final tokenResult = await _googleAuthClient.getIdToken();

    switch (tokenResult) {
      case Error(:final error):
        return Result.error(error);
      case Ok(value: final idToken):
        try {
          final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
          final result = await _firebaseAuth.signInWithCredential(credential);

          final firebaseUser = result.user;
          if (firebaseUser == null) {
            return Result.error(Exception('구글 로그인에 실패했습니다'));
          }
          return Result.ok(firebaseUser.toDomain());
        } on Exception catch (e) {
          return Result.error(AuthException(e.toAuthError()));
        }
    }
  }

  @override
  String? getCurrentUserId() => _firebaseAuth.currentUser?.uid;

  @override
  String? getCurrentUserName() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;
    // displayName이 없으면 email의 @ 앞부분 사용
    return user.displayName ?? user.email?.split('@').first;
  }

  @override
  String? getCurrentUserEmail() => _firebaseAuth.currentUser?.email;

  @override
  Future<void> logout() async {
    await _googleAuthClient.signOut();
    await _firebaseAuth.signOut();
  }
}

extension on Exception {
  AuthError toAuthError() {
    final e = this;
    if (e is! fb.FirebaseAuthException) return AuthError.unknown;

    return switch (e.code) {
      'weak-password' => AuthError.weakPassword,
    // 보안상 합침 (계정 존재 여부를 노출하지 않음)
      'invalid-credential' ||
      'wrong-password' ||
      'invalid-email' ||
      'user-not-found' ||
      'user-disabled' =>
      AuthError.invalidCredential,
      'email-already-in-use' => AuthError.emailAlreadyInUse,
      'network-request-failed' => AuthError.network,
      _ => AuthError.unknown,
    };
  }
}