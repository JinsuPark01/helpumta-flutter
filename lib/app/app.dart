import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../domain/repository/auth_repository.dart';
import '../domain/repository/group_repository.dart';
import '../domain/repository/record_repository.dart';
import '../domain/repository/user_repository.dart';
import 'router.dart';

class HelpumtaApp extends StatefulWidget {
  const HelpumtaApp({
    super.key,
    required this.authRepository,
    required this.userRepository,
    required this.groupRepository,
    required this.recordRepository,
  });

  final AuthRepository authRepository;
  final UserRepository userRepository;
  final GroupRepository groupRepository;
  final RecordRepository recordRepository;

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
        RepositoryProvider<GroupRepository>.value(
          value: widget.groupRepository,
        ),
        RepositoryProvider<RecordRepository>.value(
          value: widget.recordRepository,
        ),
      ],
      child: MaterialApp.router(
        title: '헬품타',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        // 달력 등 기본 위젯을 한국어로 표시
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}