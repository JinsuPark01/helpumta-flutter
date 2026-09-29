import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.status = LoginStatus.initial,
    this.errorMessage,
  });

  final String email;
  final String password;
  final LoginStatus status;
  final String? errorMessage;

  bool get isLoading => status == LoginStatus.loading;

  bool get isLoginEnabled =>
      email.trim().isNotEmpty && password.trim().isNotEmpty;

  LoginState copyWith({
    String? email,
    String? password,
    LoginStatus? status,
    ValueGetter<String?>? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [email, password, status, errorMessage];
}