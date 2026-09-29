import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../domain/repository/auth_repository.dart';
import '../domain/repository/user_repository.dart';
import '../domain/usecase/email_login_use_case.dart';
import '../domain/usecase/google_login_use_case.dart';
import '../domain/usecase/save_user_use_case.dart';
import '../domain/usecase/sign_up_use_case.dart';
import '../presentation/common/placeholder_screen.dart';
import '../presentation/login/login_bloc.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/sign_up/sign_up_bloc.dart';
import '../presentation/sign_up/sign_up_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const signUp = '/signup';
  static const home = '/home';
  static const groupCreate = '/group/create';
  static const groupDetail = '/group/:groupId';
  static const recordCreate = '/group/:groupId/record';
  static const myPage = '/mypage';

  static String groupDetailPath(String groupId) => '/group/$groupId';
  static String recordCreatePath(String groupId) => '/group/$groupId/record';
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
        builder: (context, state) => PlaceholderScreen(
          title: '홈',
          links: [
            const PlaceholderLink('그룹 생성', AppRoutes.groupCreate),
            PlaceholderLink(
              '그룹 상세 (sample)',
              AppRoutes.groupDetailPath('sample'),
            ),
            const PlaceholderLink('마이페이지', AppRoutes.myPage),
          ],
        ),
      ),
      // groupCreate는 반드시 groupDetail보다 위에 있어야 함
      // (아래에 두면 'create'가 groupId로 매칭됨)
      GoRoute(
        path: AppRoutes.groupCreate,
        builder: (context, state) =>
        const PlaceholderScreen(title: '그룹 생성'),
      ),
      GoRoute(
        path: AppRoutes.groupDetail,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return PlaceholderScreen(
            title: '그룹 상세: $groupId',
            links: [
              PlaceholderLink('기록 작성', AppRoutes.recordCreatePath(groupId)),
            ],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recordCreate,
        builder: (context, state) {
          final groupId = state.pathParameters['groupId']!;
          return PlaceholderScreen(title: '기록 작성: $groupId');
        },
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