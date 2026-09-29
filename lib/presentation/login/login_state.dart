import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage,
    this.isLoggedIn = false,
  });

  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;

  /// SideEffect.NavigateToHome 대체 — false → true 전환 시 한 번만 반응
  final bool isLoggedIn;

  bool get isLoginEnabled =>
      email.trim().isNotEmpty && password.trim().isNotEmpty;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    ValueGetter<String?>? errorMessage,
    bool? isLoggedIn,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }

  @override
  List<Object?> get props =>
      [email, password, isLoading, errorMessage, isLoggedIn];
}