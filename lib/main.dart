import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const HelpumtaApp());
}

class HelpumtaApp extends StatelessWidget {
  const HelpumtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '헬품타',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Firebase 연결 완료'),
        ),
      ),
    );
  }
}