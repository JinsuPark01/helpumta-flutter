import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/auth/google_auth_client.dart';
import 'data/repository/auth_repository_impl.dart';
import 'data/repository/group_repository_impl.dart';
import 'data/repository/user_repository_impl.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 앱 전체에서 인스턴스 하나만 사용 (Hilt @Singleton 역할)
  final firestore = FirebaseFirestore.instance;
  final authRepository = AuthRepositoryImpl(
    FirebaseAuth.instance,
    GoogleAuthClient(),
  );
  final userRepository = UserRepositoryImpl(firestore);
  final groupRepository = GroupRepositoryImpl(firestore);

  runApp(
    HelpumtaApp(
      authRepository: authRepository,
      userRepository: userRepository,
      groupRepository: groupRepository,
    ),
  );
}