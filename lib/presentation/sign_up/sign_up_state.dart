import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Android Patterns.EMAIL_ADDRESS 대체 (완전히 동일한 규칙은 아님)
final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

enum SignUpStatus { initial, loading, success, failure }

class SignUpState extends Equatable {
  const SignUpState({
    this.email = '',
    this.password = '',
    this.passwordConfirm = '',
    this.nickname = '',
    this.status = SignUpStatus.initial,
    this.errorMessage,
  });

  final String email;
  final String password;
  final String passwordConfirm;
  final String nickname;
  final SignUpStatus status;
  final String? errorMessage;

  bool get isLoading => status == SignUpStatus.loading;

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
    SignUpStatus? status,
    ValueGetter<String?>? errorMessage,
  }) {
    return SignUpState(
      email: email ?? this.email,
      password: password ?? this.password,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      nickname: nickname ?? this.nickname,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    passwordConfirm,
    nickname,
    status,
    errorMessage,
  ];
}