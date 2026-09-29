import 'package:go_router/go_router.dart';

import '../presentation/common/placeholder_screen.dart';

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

final appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const PlaceholderScreen(
        title: '로그인',
        links: [
          PlaceholderLink('회원가입', AppRoutes.signUp),
          PlaceholderLink('로그인 성공 → 홈', AppRoutes.home, replace: true),
        ],
      ),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (context, state) => const PlaceholderScreen(title: '회원가입'),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => PlaceholderScreen(
        title: '홈',
        links: [
          const PlaceholderLink('그룹 생성', AppRoutes.groupCreate),
          PlaceholderLink('그룹 상세 (sample)', AppRoutes.groupDetailPath('sample')),
          const PlaceholderLink('마이페이지', AppRoutes.myPage),
        ],
      ),
    ),
    // groupCreate는 반드시 groupDetail보다 위에 있어야 함
    // (아래에 두면 'create'가 groupId로 매칭됨)
    GoRoute(
      path: AppRoutes.groupCreate,
      builder: (context, state) => const PlaceholderScreen(title: '그룹 생성'),
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
      builder: (context, state) => const PlaceholderScreen(
        title: '마이페이지',
        links: [
          PlaceholderLink('로그아웃 → 로그인', AppRoutes.login, replace: true),
        ],
      ),
    ),
  ],
);