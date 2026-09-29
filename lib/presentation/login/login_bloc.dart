import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/entity/auth_error.dart';
import '../../domain/usecase/email_login_use_case.dart';
import '../../domain/usecase/google_login_use_case.dart';
import '../auth/auth_error_message.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required EmailLoginUseCase emailLoginUseCase,
    required GoogleLoginUseCase googleLoginUseCase,
  })  : _emailLoginUseCase = emailLoginUseCase,
        _googleLoginUseCase = googleLoginUseCase,
        super(const LoginState()) {
    on<LoginEmailChanged>(
          (event, emit) => emit(
        state.copyWith(email: event.email, errorMessage: () => null),
      ),
    );
    on<LoginPasswordChanged>(
          (event, emit) => emit(
        state.copyWith(password: event.password, errorMessage: () => null),
      ),
    );
    on<LoginSubmitted>(_onSubmitted);
    on<LoginGoogleRequested>(_onGoogleRequested);
  }

  final EmailLoginUseCase _emailLoginUseCase;
  final GoogleLoginUseCase _googleLoginUseCase;

  Future<void> _onSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    if (state.isLoading) return;

    emit(state.copyWith(
      status: LoginStatus.loading,
      errorMessage: () => null,
    ));

    final result = await _emailLoginUseCase(
      email: state.email.trim(),
      password: state.password,
    );

    switch (result) {
      case Ok():
        emit(state.copyWith(status: LoginStatus.success));
      case Error(:final error):
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: () =>
              authErrorMessageOf(error, fallback: '잠시 후 다시 시도해주세요'),
        ));
    }
  }

  Future<void> _onGoogleRequested(
      LoginGoogleRequested event,
      Emitter<LoginState> emit,
      ) async {
    if (state.isLoading) return;

    emit(state.copyWith(
      status: LoginStatus.loading,
      errorMessage: () => null,
    ));

    final result = await _googleLoginUseCase();

    switch (result) {
      case Ok():
        emit(state.copyWith(status: LoginStatus.success));
    // 계정 선택 취소는 에러가 아니므로 문구 없이 원래 상태로
      case Error(error: AuthException(error: AuthError.googleSignInCancelled)):
        emit(state.copyWith(status: LoginStatus.initial));
      case Error(:final error):
        emit(state.copyWith(
          status: LoginStatus.failure,
          errorMessage: () =>
              authErrorMessageOf(error, fallback: '구글 로그인에 실패했습니다'),
        ));
    }
  }
}