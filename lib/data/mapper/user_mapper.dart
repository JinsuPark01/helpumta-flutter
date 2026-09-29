import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entity/user.dart';

extension FirebaseUserMapper on fb.User {
  User toDomain() => User(uid: uid, email: email ?? '');
}