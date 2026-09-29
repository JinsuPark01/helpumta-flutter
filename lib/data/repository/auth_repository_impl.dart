import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/result.dart';
import '../../domain/entity/auth_error.dart';
import '../../domain/entity/user.dart';
import '../../domain/repository/auth_repository.dart';
import '../mapper/user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseAuth);

  final fb.FirebaseAuth _firebaseAuth;

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

      // 닉네임을 displayName으로 설정
      await firebaseUser.updateDisplayName(nickname);
      // 이후 getCurrentUserName()이 갱신된 값을 읽도록 로컬 캐시 새로고침
      await firebaseUser.reload();

      return Result.ok(firebaseUser.toDomain());
    } on Exception catch (e) {
      return Result.error(AuthException(e.toAuthError()));
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
  Future<void> logout() => _firebaseAuth.signOut();
}

extension on Exception {
  AuthError toAuthError() {
    final e = this;
    if (e is! fb.FirebaseAuthException) return AuthError.unknown;

    return switch (e.code) {
      'weak-password' => AuthError.weakPassword,
    // 보안상 합침 (네이티브의 InvalidCredentials + InvalidUser)
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