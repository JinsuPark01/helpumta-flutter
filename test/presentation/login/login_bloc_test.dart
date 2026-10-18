import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helpumta_flutter/core/result.dart';
import 'package:helpumta_flutter/domain/entity/auth_error.dart';
import 'package:helpumta_flutter/domain/entity/user.dart';
import 'package:helpumta_flutter/domain/usecase/email_login_use_case.dart';
import 'package:helpumta_flutter/domain/usecase/google_login_use_case.dart';
import 'package:helpumta_flutter/presentation/login/login_bloc.dart';
import 'package:helpumta_flutter/presentation/login/login_event.dart';
import 'package:helpumta_flutter/presentation/login/login_state.dart';

/// 항상 정해진 결과를 돌려주는 가짜 UseCase
class FakeEmailLoginUseCase extends Fake implements EmailLoginUseCase {
  FakeEmailLoginUseCase(this.result);

  final Result<User> result;

  @override
  Future<Result<User>> call({
    required String email,
    required String password,
  }) async =>
      result;
}

class FakeGoogleLoginUseCase extends Fake implements GoogleLoginUseCase {
  FakeGoogleLoginUseCase(this.result);

  final Result<User> result;

  @override
  Future<Result<User>> call() async => result;
}

void main() {
  const loggedInUser = User(uid: 'user1', email: 'jinsu@test.com');
  const filledState = LoginState(
    email: 'jinsu@test.com',
    password: 'wrong-password',
  );

  LoginBloc buildBloc({
    Result<User> emailResult = const Result.ok(loggedInUser),
    Result<User> googleResult = const Result.ok(loggedInUser),
  }) {
    return LoginBloc(
      emailLoginUseCase: FakeEmailLoginUseCase(emailResult),
      googleLoginUseCase: FakeGoogleLoginUseCase(googleResult),
    );
  }

  group('이메일 로그인', () {
    blocTest<LoginBloc, LoginState>(
      '틀린 비밀번호면 loading → failure와 에러 문구를 내보낸다',
      build: () => buildBloc(
        emailResult:
        const Result.error(AuthException(AuthError.invalidCredential)),
      ),
      seed: () => filledState,
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [
        filledState.copyWith(status: LoginStatus.loading),
        filledState.copyWith(
          status: LoginStatus.failure,
          errorMessage: () => '이메일 또는 비밀번호가 올바르지 않습니다',
        ),
      ],
    );

    blocTest<LoginBloc, LoginState>(
      '같은 실패가 연속돼도 매번 loading을 거쳐 failure를 다시 내보낸다',
      build: () => buildBloc(
        emailResult:
        const Result.error(AuthException(AuthError.invalidCredential)),
      ),
      seed: () => filledState,
      act: (bloc) async {
        bloc.add(const LoginSubmitted());
        // 첫 요청이 끝난 뒤 두 번째 요청
        await Future<void>.delayed(Duration.zero);
        bloc.add(const LoginSubmitted());
      },
      expect: () {
        final loading = filledState.copyWith(status: LoginStatus.loading);
        final failure = filledState.copyWith(
          status: LoginStatus.failure,
          errorMessage: () => '이메일 또는 비밀번호가 올바르지 않습니다',
        );
        // failure → failure가 아니라 failure → loading → failure라서
        // BlocListener가 두 번째 실패에도 반응할 수 있다
        return [loading, failure, loading, failure];
      },
    );

    blocTest<LoginBloc, LoginState>(
      '성공하면 loading → success를 내보낸다',
      build: buildBloc,
      seed: () => filledState,
      act: (bloc) => bloc.add(const LoginSubmitted()),
      expect: () => [
        filledState.copyWith(status: LoginStatus.loading),
        filledState.copyWith(status: LoginStatus.success),
      ],
    );
  });

  group('Google 로그인', () {
    blocTest<LoginBloc, LoginState>(
      '계정 선택을 취소하면 에러 문구 없이 initial로 돌아간다',
      build: () => buildBloc(
        googleResult:
        const Result.error(AuthException(AuthError.googleSignInCancelled)),
      ),
      act: (bloc) => bloc.add(const LoginGoogleRequested()),
      expect: () => [
        const LoginState(status: LoginStatus.loading),
        const LoginState(status: LoginStatus.initial),
      ],
    );
  });
}