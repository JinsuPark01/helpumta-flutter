import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/repository/auth_repository.dart';
import '../domain/repository/user_repository.dart';
import 'router.dart';

class HelpumtaApp extends StatefulWidget {
  const HelpumtaApp({
    super.key,
    required this.authRepository,
    required this.userRepository,
  });

  final AuthRepository authRepository;
  final UserRepository userRepository;

  @override
  State<HelpumtaApp> createState() => _HelpumtaAppState();
}

class _HelpumtaAppState extends State<HelpumtaApp> {
  // 리빌드마다 라우터가 새로 만들어지지 않도록 State에서 한 번만 생성
  late final GoRouter _router = createRouter(widget.authRepository);

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(
          value: widget.authRepository,
        ),
        RepositoryProvider<UserRepository>.value(
          value: widget.userRepository,
        ),
      ],
      child: MaterialApp.router(
        title: '헬품타',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        routerConfig: _router,
      ),
    );
  }
}