import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../core/result.dart';
import '../../domain/entity/auth_error.dart';
import '../../domain/entity/auth_provider.dart';
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
  AuthProvider getAuthProvider() {
    final user = _firebaseAuth.currentUser;
    if (user == null) return AuthProvider.unknown;

    final providerIds = user.providerData.map((info) => info.providerId);
    if (providerIds.contains('google.com')) return AuthProvider.google;
    if (providerIds.contains('password')) return AuthProvider.email;
    return AuthProvider.unknown;
  }

  @override
  Future<Result<void>> reauthenticateWithPassword(String password) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return Result.error(Exception('로그인 상태가 아닙니다'));
    final email = user.email;
    if (email == null) return Result.error(Exception('이메일 정보를 가져올 수 없습니다'));

    try {
      final credential = fb.EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(AuthException(e.toAuthError()));
    }
  }

  @override
  Future<Result<void>> reauthenticateWithGoogle() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return Result.error(Exception('로그인 상태가 아닙니다'));

    // 로그인과 동일하게 토큰 획득도 Data 레이어 안에서 처리 (Activity 불필요)
    final tokenResult = await _googleAuthClient.getIdToken();

    switch (tokenResult) {
      case Error(:final error):
        return Result.error(error);
      case Ok(value: final idToken):
        try {
          final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
          await user.reauthenticateWithCredential(credential);
          return const Result.ok(null);
        } on Exception catch (e) {
          return Result.error(AuthException(e.toAuthError()));
        }
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return Result.error(Exception('로그인 상태가 아닙니다'));

    try {
      await user.delete();
      // 다음 로그인 때 이전 구글 계정이 자동 선택되지 않도록 세션 정리
      await _googleAuthClient.signOut();
      return const Result.ok(null);
    } on Exception catch (e) {
      return Result.error(AuthException(e.toAuthError()));
    }
  }

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