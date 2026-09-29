import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Android Patterns.EMAIL_ADDRESS 대체 (완전히 동일한 규칙은 아님)
final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

class SignUpState extends Equatable {
  const SignUpState({
    this.email = '',
    this.password = '',
    this.passwordConfirm = '',
    this.nickname = '',
    this.isLoading = false,
    this.errorMessage,
    this.isSignedUp = false,
  });

  final String email;
  final String password;
  final String passwordConfirm;
  final String nickname;
  final bool isLoading;
  final String? errorMessage;

  /// SideEffect(ShowToast + NavigateToHome) 대체
  final bool isSignedUp;

  bool get isValidEmail => _emailRegex.hasMatch(email);

  bool get isSignUpEnabled =>
      isValidEmail &&
          password.length >= 6 &&
          password == passwordConfirm &&
          nickname.trim().isNotEmpty;

  SignUpState copyWith({
    String? email,
    String? password,
    String? passwordConfirm,
    String? nickname,
    bool? isLoading,
    ValueGetter<String?>? errorMessage,
    bool? isSignedUp,
  }) {
    return SignUpState(
      email: email ?? this.email,
      password: password ?? this.password,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      nickname: nickname ?? this.nickname,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isSignedUp: isSignedUp ?? this.isSignedUp,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    passwordConfirm,
    nickname,
    isLoading,
    errorMessage,
    isSignedUp,
  ];
}