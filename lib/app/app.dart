import 'package:flutter/material.dart';

import 'router.dart';

class HelpumtaApp extends StatelessWidget {
  const HelpumtaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '헬품타',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: appRouter,
    );
  }
}