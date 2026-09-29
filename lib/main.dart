import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/auth/google_auth_client.dart';
import 'data/repository/auth_repository_impl.dart';
import 'data/repository/user_repository_impl.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 네이티브 Hilt @Singleton과 같은 역할: 앱 전체에서 인스턴스 하나만 사용
  final authRepository = AuthRepositoryImpl(FirebaseAuth.instance);
  final userRepository = UserRepositoryImpl(FirebaseFirestore.instance);
  final googleAuthClient = GoogleAuthClient();

  runApp(
    HelpumtaApp(
      authRepository: authRepository,
      userRepository: userRepository,
      googleAuthClient: googleAuthClient,
    ),
  );
}