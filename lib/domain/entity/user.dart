import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.uid,
    required this.email,
  });

  final String uid;
  final String email;

  @override
  List<Object?> get props => [uid, email];
}