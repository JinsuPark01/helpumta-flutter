import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/usecase/email_login_use_case.dart';
import '../auth/auth_error_message.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required EmailLoginUseCase emailLoginUseCase})
      : _emailLoginUseCase = emailLoginUseCase,
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
  }

  final EmailLoginUseCase _emailLoginUseCase;

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
}