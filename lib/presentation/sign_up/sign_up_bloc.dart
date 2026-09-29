import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/usecase/sign_up_use_case.dart';
import '../auth/auth_error_message.dart';
import 'sign_up_event.dart';
import 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc({required SignUpUseCase signUpUseCase})
      : _signUpUseCase = signUpUseCase,
        super(const SignUpState()) {
    on<SignUpEmailChanged>(
          (event, emit) => emit(
        state.copyWith(email: event.email, errorMessage: () => null),
      ),
    );
    on<SignUpPasswordChanged>(
          (event, emit) => emit(
        state.copyWith(password: event.password, errorMessage: () => null),
      ),
    );
    on<SignUpPasswordConfirmChanged>(
          (event, emit) => emit(
        state.copyWith(
          passwordConfirm: event.passwordConfirm,
          errorMessage: () => null,
        ),
      ),
    );
    on<SignUpNicknameChanged>(
          (event, emit) => emit(
        state.copyWith(nickname: event.nickname, errorMessage: () => null),
      ),
    );
    on<SignUpSubmitted>(_onSubmitted);
  }

  final SignUpUseCase _signUpUseCase;

  Future<void> _onSubmitted(
      SignUpSubmitted event,
      Emitter<SignUpState> emit,
      ) async {
    if (state.isLoading) return;

    emit(state.copyWith(
      status: SignUpStatus.loading,
      errorMessage: () => null,
    ));

    final result = await _signUpUseCase(
      email: state.email.trim(),
      password: state.password,
      nickname: state.nickname.trim(),
    );

    switch (result) {
      case Ok():
        emit(state.copyWith(status: SignUpStatus.success));
      case Error(:final error):
        emit(state.copyWith(
          status: SignUpStatus.failure,
          errorMessage: () =>
              authErrorMessageOf(error, fallback: '잠시 후 다시 시도해주세요'),
        ));
    }
  }
}