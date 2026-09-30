import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/repository/auth_repository.dart';
import '../domain/repository/group_repository.dart';
import '../domain/repository/user_repository.dart';
import '../domain/usecase/email_login_use_case.dart';
import '../domain/usecase/get_groups_use_case.dart';
import '../domain/usecase/google_login_use_case.dart';
import '../domain/usecase/save_user_use_case.dart';
import '../domain/usecase/sign_up_use_case.dart';
import '../presentation/common/placeholder_screen.dart';
import '../presentation/home/home_bloc.dart';
import '../presentation/home/home_event.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/login/login_bloc.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/sign_up/sign_up_bloc.dart';
import '../presentation/sign_up/sign_up_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const signUp = '/signup';
  static const home = '/home';
  static const myPage = '/mypage';

  // 그룹 관련 화면은 /home 하위 → go()로 이동해도 "홈 → 대상" 스택이 만들어짐
  static const groupCreate = '/home/group/create';

  static String groupDetailPath(String groupId) => '/home/group/$groupId';
  static String recordCreatePath(String groupId) =>
      '/home/group/$groupId/record';
}

GoRouter createRouter(AuthRepository authRepository) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      final isLoggedIn = authRepository.getCurrentUserId() != null;
      final location = state.matchedLocation;
      final isAuthPage =
          location == AppRoutes.login || location == AppRoutes.signUp;

      if (!isLoggedIn && !isAuthPage) return AppRoutes.login;
      if (isLoggedIn && isAuthPage) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          final authRepository = context.read<AuthRepository>();
          final saveUserUseCase = SaveUserUseCase(
            authRepository,
            context.read<UserRepository>(),
          );
          return BlocProvider(
            create: (context) => LoginBloc(
              emailLoginUseCase: EmailLoginUseCase(authRepository),
              googleLoginUseCase:
              GoogleLoginUseCase(authRepository, saveUserUseCase),
            ),
            child: const LoginScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) {
          final authRepository = context.read<AuthRepository>();
          final saveUserUseCase = SaveUserUseCase(
            authRepository,
            context.read<UserRepository>(),
          );
          return BlocProvider(
            create: (context) => SignUpBloc(
              signUpUseCase: SignUpUseCase(authRepository, saveUserUseCase),
            ),
            child: const SignUpScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => BlocProvider(
          // 생성 직후 첫 로딩 (네이티브 ViewModel init 블록 역할)
          create: (context) => HomeBloc(
            getGroupsUseCase: GetGroupsUseCase(
              context.read<GroupRepository>(),
              context.read<AuthRepository>(),
            ),
          )..add(const HomeGroupsRequested()),
          child: const HomeScreen(),
        ),
        routes: [
          // group/create는 반드시 group/:groupId보다 위에 있어야 함
          GoRoute(
            path: 'group/create',
            builder: (context, state) =>
            const PlaceholderScreen(title: '그룹 생성'),
          ),
          GoRoute(
            path: 'group/:groupId',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              return PlaceholderScreen(
                title: '그룹 상세: $groupId',
                links: [
                  PlaceholderLink(
                    '기록 작성',
                    AppRoutes.recordCreatePath(groupId),
                  ),
                ],
              );
            },
            routes: [
              GoRoute(
                path: 'record',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  return PlaceholderScreen(title: '기록 작성: $groupId');
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.myPage,
        // 마이페이지 구현 전까지 로그아웃만 되는 임시 화면
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('마이페이지')),
          body: Center(
            child: FilledButton(
              onPressed: () async {
                await context.read<AuthRepository>().logout();
                if (context.mounted) context.go(AppRoutes.login);
              },
              child: const Text('로그아웃'),
            ),
          ),
        ),
      ),
    ],
  );
}