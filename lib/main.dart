import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'data/repository/auth_repository_impl.dart';
import 'data/repository/user_repository_impl.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = AuthRepositoryImpl(FirebaseAuth.instance);
  final userRepository = UserRepositoryImpl(FirebaseFirestore.instance);

  runApp(
    HelpumtaApp(
      authRepository: authRepository,
      userRepository: userRepository,
    ),
  );
}