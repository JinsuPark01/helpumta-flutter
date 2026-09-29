import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../data/auth/google_auth_client.dart';
import '../../domain/usecase/email_login_use_case.dart';
import '../../domain/usecase/google_login_use_case.dart';
import '../../domain/usecase/save_user_use_case.dart';
import '../auth/auth_error_message.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({
    required EmailLoginUseCase emailLoginUseCase,
    required GoogleLoginUseCase googleLoginUseCase,
    required GoogleAuthClient googleAuthClient,
    required SaveUserUseCase saveUserUseCase,
  })  : _emailLoginUseCase = emailLoginUseCase,
        _googleLoginUseCase = googleLoginUseCase,
        _googleAuthClient = googleAuthClient,
        _saveUserUseCase = saveUserUseCase,
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
  final GoogleAuthClient _googleAuthClient;
  final SaveUserUseCase _saveUserUseCase;

  Future<void> _onSubmitted(
      LoginSubmitted event,
      Emitter<LoginState> emit,
      ) async {
    if (state.isLoading) return;

    emit(state.copyWith(isLoading: true, errorMessage: () => null));

    final result = await _emailLoginUseCase(
      email: state.email.trim(),
      password: state.password,
    );

    switch (result) {
      case Ok():
        emit(state.copyWith(isLoading: false, isLoggedIn: true));
      case Error(:final error):
        emit(state.copyWith(
          isLoading: false,
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

    emit(state.copyWith(isLoading: true, errorMessage: () => null));

    final tokenResult = await _googleAuthClient.getIdToken();

    switch (tokenResult) {
      case Ok(value: final idToken):
        final loginResult = await _googleLoginUseCase(idToken);

        switch (loginResult) {
          case Ok():
            await _saveUserUseCase();
            emit(state.copyWith(isLoading: false, isLoggedIn: true));
          case Error(:final error):
            emit(state.copyWith(
              isLoading: false,
              errorMessage: () =>
                  authErrorMessageOf(error, fallback: '구글 로그인에 실패했습니다'),
            ));
        }
      case Error():
      // 구글 클라이언트(토큰 받기) 실패 — Firebase 에러 아님
        emit(state.copyWith(
          isLoading: false,
          errorMessage: () => '구글 계정을 가져올 수 없습니다',
        ));
    }
  }
}