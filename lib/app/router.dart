import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../domain/repository/auth_repository.dart';
import '../domain/repository/gallery_repository.dart';
import '../domain/repository/group_repository.dart';
import '../domain/repository/record_repository.dart';
import '../domain/repository/settings_repository.dart';
import '../domain/repository/user_repository.dart';
import '../domain/usecase/create_group_use_case.dart';
import '../domain/usecase/create_record_use_case.dart';
import '../domain/usecase/delete_account_use_case.dart';
import '../domain/usecase/delete_record_use_case.dart';
import '../domain/usecase/email_login_use_case.dart';
import '../domain/usecase/get_auth_provider_use_case.dart';
import '../domain/usecase/get_current_user_id_use_case.dart';
import '../domain/usecase/get_daily_extract_use_case.dart';
import '../domain/usecase/get_group_detail_use_case.dart';
import '../domain/usecase/get_groups_use_case.dart';
import '../domain/usecase/get_record_by_id_use_case.dart';
import '../domain/usecase/get_records_by_group_use_case.dart';
import '../domain/usecase/get_user_profile_use_case.dart';
import '../domain/usecase/google_login_use_case.dart';
import '../domain/usecase/has_wrote_today_use_case.dart';
import '../domain/usecase/leave_group_use_case.dart';
import '../domain/usecase/logout_use_case.dart';
import '../domain/usecase/save_image_to_gallery_use_case.dart';
import '../domain/usecase/save_user_use_case.dart';
import '../domain/usecase/set_home_layout_use_case.dart';
import '../domain/usecase/sign_up_use_case.dart';
import '../domain/usecase/update_record_use_case.dart';
import '../domain/usecase/watch_home_layout_use_case.dart';
import '../presentation/extract/extract_bloc.dart';
import '../presentation/extract/extract_event.dart';
import '../presentation/extract/extract_screen.dart';
import '../presentation/group_create/group_create_bloc.dart';
import '../presentation/group_create/group_create_screen.dart';
import '../presentation/group_detail/group_detail_bloc.dart';
import '../presentation/group_detail/group_detail_event.dart';
import '../presentation/group_detail/group_detail_screen.dart';
import '../presentation/home/home_bloc.dart';
import '../presentation/home/home_event.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/login/login_bloc.dart';
import '../presentation/login/login_screen.dart';
import '../presentation/my_page/my_page_bloc.dart';
import '../presentation/my_page/my_page_event.dart';
import '../presentation/my_page/my_page_screen.dart';
import '../presentation/record/record_bloc.dart';
import '../presentation/record/record_event.dart';
import '../presentation/record/record_screen.dart';
import '../presentation/sign_up/sign_up_bloc.dart';
import '../presentation/sign_up/sign_up_screen.dart';

abstract final class AppRoutes {
  static const login = '/login';
  static const signUp = '/signup';
  static const home = '/home';
  static const myPage = '/mypage';

  // 그룹 관련 화면은 /home 하위 → 뒤로가기 시 홈으로 돌아옴
  static const groupCreate = '/home/group/create';

  static final _dateFormat = DateFormat('yyyy-MM-dd');

  static String groupDetailPath(String groupId) => '/home/group/$groupId';

  static String recordCreatePath(String groupId) =>
      '/home/group/$groupId/record';

  static String recordEditPath(String groupId, String recordId) =>
      '/home/group/$groupId/record?recordId=$recordId';

  static String extractPath(String groupId, DateTime date) =>
      '/home/group/$groupId/extract?date=${_dateFormat.format(date)}';
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
          // 배치 설정 구독 + 첫 로딩 (네이티브 ViewModel init 블록 역할)
          create: (context) => HomeBloc(
            getGroupsUseCase: GetGroupsUseCase(
              context.read<GroupRepository>(),
              context.read<AuthRepository>(),
            ),
            watchHomeLayoutUseCase: WatchHomeLayoutUseCase(
              context.read<SettingsRepository>(),
            ),
          )
            ..add(const HomeLayoutSubscriptionRequested())
            ..add(const HomeGroupsRequested()),
          child: const HomeScreen(),
        ),
        routes: [
          // group/create는 반드시 group/:groupId보다 위에 있어야 함
          GoRoute(
            path: 'group/create',
            builder: (context, state) => BlocProvider(
              create: (context) => GroupCreateBloc(
                createGroupUseCase: CreateGroupUseCase(
                  context.read<GroupRepository>(),
                  context.read<AuthRepository>(),
                ),
              ),
              child: const GroupCreateScreen(),
            ),
          ),
          GoRoute(
            path: 'group/:groupId',
            builder: (context, state) {
              final groupId = state.pathParameters['groupId']!;
              final authRepository = context.read<AuthRepository>();
              final groupRepository = context.read<GroupRepository>();
              final recordRepository = context.read<RecordRepository>();

              return BlocProvider(
                create: (context) => GroupDetailBloc(
                  groupId: groupId,
                  getGroupDetailUseCase: GetGroupDetailUseCase(groupRepository),
                  getRecordsByGroupUseCase:
                  GetRecordsByGroupUseCase(recordRepository),
                  hasWroteTodayUseCase:
                  HasWroteTodayUseCase(recordRepository, authRepository),
                  getCurrentUserIdUseCase:
                  GetCurrentUserIdUseCase(authRepository),
                  deleteRecordUseCase:
                  DeleteRecordUseCase(recordRepository, authRepository),
                  leaveGroupUseCase: LeaveGroupUseCase(
                    authRepository,
                    groupRepository,
                    recordRepository,
                  ),
                )..add(const GroupDetailStarted()),
                child: const GroupDetailScreen(),
              );
            },
            routes: [
              GoRoute(
                path: 'record',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  final recordId = state.uri.queryParameters['recordId'];
                  final authRepository = context.read<AuthRepository>();
                  final recordRepository = context.read<RecordRepository>();

                  return BlocProvider(
                    create: (context) => RecordBloc(
                      groupId: groupId,
                      recordId: recordId,
                      createRecordUseCase:
                      CreateRecordUseCase(recordRepository, authRepository),
                      updateRecordUseCase:
                      UpdateRecordUseCase(recordRepository, authRepository),
                      getRecordByIdUseCase:
                      GetRecordByIdUseCase(recordRepository),
                    )..add(const RecordStarted()),
                    child: const RecordScreen(),
                  );
                },
              ),
              GoRoute(
                path: 'extract',
                builder: (context, state) {
                  final groupId = state.pathParameters['groupId']!;
                  // yyyy-MM-dd → 로컬 00:00 (잘못된 값이면 오늘)
                  final date = DateTime.tryParse(
                    state.uri.queryParameters['date'] ?? '',
                  ) ??
                      DateTime.now();

                  return BlocProvider(
                    create: (context) => ExtractBloc(
                      groupId: groupId,
                      date: date,
                      getDailyExtractUseCase: GetDailyExtractUseCase(
                        context.read<GroupRepository>(),
                        context.read<RecordRepository>(),
                        context.read<UserRepository>(),
                      ),
                      saveImageToGalleryUseCase: SaveImageToGalleryUseCase(
                        context.read<GalleryRepository>(),
                      ),
                    )..add(const ExtractStarted()),
                    child: const ExtractScreen(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.myPage,
        builder: (context, state) {
          final authRepository = context.read<AuthRepository>();
          final groupRepository = context.read<GroupRepository>();
          final recordRepository = context.read<RecordRepository>();
          final settingsRepository = context.read<SettingsRepository>();

          return BlocProvider(
            create: (context) => MyPageBloc(
              getUserProfileUseCase: GetUserProfileUseCase(authRepository),
              getAuthProviderUseCase: GetAuthProviderUseCase(authRepository),
              logoutUseCase: LogoutUseCase(authRepository),
              deleteAccountUseCase: DeleteAccountUseCase(
                authRepository,
                groupRepository,
                LeaveGroupUseCase(
                  authRepository,
                  groupRepository,
                  recordRepository,
                ),
                context.read<UserRepository>(),
              ),
              watchHomeLayoutUseCase:
              WatchHomeLayoutUseCase(settingsRepository),
              setHomeLayoutUseCase: SetHomeLayoutUseCase(settingsRepository),
            )
              ..add(const MyPageStarted())
              ..add(const MyPageLayoutSubscriptionRequested()),
            child: const MyPageScreen(),
          );
        },
      ),
    ],
  );
}