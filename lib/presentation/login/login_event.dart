sealed class LoginEvent {
  const LoginEvent();
}

final class LoginEmailChanged extends LoginEvent {
  const LoginEmailChanged(this.email);

  final String email;
}

final class LoginPasswordChanged extends LoginEvent {
  const LoginPasswordChanged(this.password);

  final String password;
}

final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}