import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({required this.nickname, required this.email});

  final String nickname;
  final String email;

  @override
  List<Object?> get props => [nickname, email];
}