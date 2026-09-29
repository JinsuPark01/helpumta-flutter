sealed class SignUpEvent {
  const SignUpEvent();
}

final class SignUpEmailChanged extends SignUpEvent {
  const SignUpEmailChanged(this.email);

  final String email;
}

final class SignUpPasswordChanged extends SignUpEvent {
  const SignUpPasswordChanged(this.password);

  final String password;
}

final class SignUpPasswordConfirmChanged extends SignUpEvent {
  const SignUpPasswordConfirmChanged(this.passwordConfirm);

  final String passwordConfirm;
}

final class SignUpNicknameChanged extends SignUpEvent {
  const SignUpNicknameChanged(this.nickname);

  final String nickname;
}

final class SignUpSubmitted extends SignUpEvent {
  const SignUpSubmitted();
}