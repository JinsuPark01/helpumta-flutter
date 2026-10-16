import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../domain/entity/auth_provider.dart';
import '../../domain/entity/home_layout.dart';
import '../../domain/entity/reauth_method.dart';
import 'my_page_bloc.dart';
import 'my_page_event.dart';
import 'my_page_state.dart';

const _privacyPolicyUrl =
    'https://jinsupark01.github.io/helpumta-policy/privacy.html';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<bool> _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmLabel,
        bool isDestructive = false,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              confirmLabel,
              style: isDestructive
                  ? TextStyle(color: Theme.of(dialogContext).colorScheme.error)
                  : null,
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _onLogoutTap(BuildContext context) async {
    final bloc = context.read<MyPageBloc>();
    final confirmed = await _showConfirmDialog(
      context,
      title: '로그아웃',
      message: '정말 로그아웃 하시겠어요?',
      confirmLabel: '로그아웃',
    );
    if (confirmed && !bloc.isClosed) bloc.add(const MyPageLogoutRequested());
  }

  /// 삭제 확인 → 로그인 방식에 따라 본인 확인 방법 결정 → 삭제 요청
  static Future<void> _onDeleteTap(
      BuildContext context,
      MyPageState state,
      ) async {
    final bloc = context.read<MyPageBloc>();
    final confirmed = await _showConfirmDialog(
      context,
      title: '계정 삭제',
      message: '계정을 삭제하면 작성한 모든 운동 기록과 사진이 삭제되며 복구할 수 없어요. 정말 삭제하시겠어요?',
      confirmLabel: '삭제',
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;

    final ReauthMethod method;
    if (state.authProvider == AuthProvider.google) {
      method = const GoogleReauth();
    } else {
      // 이메일 사용자: 비밀번호 재입력
      final password = await showDialog<String>(
        context: context,
        builder: (dialogContext) => const _PasswordDialog(),
      );
      if (password == null) return; // 취소
      method = PasswordReauth(password);
    }

    if (!bloc.isClosed) bloc.add(MyPageDeleteRequested(method));
  }

  static Future<void> _openPrivacyPolicy(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(_privacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      );
    } on Exception {
      opened = false;
    }
    if (!opened && context.mounted) {
      _showSnackBar(context, '페이지를 열 수 없어요');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MyPageBloc, MyPageState>(
          listenWhen: (previous, current) =>
          !previous.isSignedOut && current.isSignedOut,
          listener: (context, state) => context.go(AppRoutes.login),
        ),
        BlocListener<MyPageBloc, MyPageState>(
          listenWhen: (previous, current) =>
          previous.deleteStatus != current.deleteStatus &&
              current.deleteStatus == MyPageDeleteStatus.failure,
          listener: (context, state) => _showSnackBar(
            context,
            state.errorMessage ?? '계정 삭제에 실패했어요. 다시 시도해주세요.',
          ),
        ),
      ],
      child: BlocBuilder<MyPageBloc, MyPageState>(
        builder: (context, state) => _MyPageContent(
          state: state,
          onNavigateBack: () => context.pop(),
          onChangeHomeLayout: (layout) =>
              context.read<MyPageBloc>().add(MyPageHomeLayoutChanged(layout)),
          onLogoutTap: () => _onLogoutTap(context),
          onDeleteTap: () => _onDeleteTap(context, state),
          onPrivacyTap: () => _openPrivacyPolicy(context),
        ),
      ),
    );
  }
}

class _MyPageContent extends StatelessWidget {
  const _MyPageContent({
    required this.state,
    required this.onNavigateBack,
    required this.onChangeHomeLayout,
    required this.onLogoutTap,
    required this.onDeleteTap,
    required this.onPrivacyTap,
  });

  final MyPageState state;
  final VoidCallback onNavigateBack;
  final ValueChanged<HomeLayout> onChangeHomeLayout;
  final VoidCallback onLogoutTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nickname = state.profile?.nickname ?? '';
    final initial = nickname.isEmpty ? '?' : nickname.characters.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로가기',
          onPressed: onNavigateBack,
        ),
      ),
      body: ListView(
        children: [
          // 프로필 영역
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  nickname,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.profile?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 홈 화면 배치 설정
          ListTile(
            leading: const Icon(Icons.view_agenda),
            title: const Text('홈 화면 배치'),
            subtitle: Text(
              state.homeLayout == HomeLayout.grid ? '2열 그리드' : '1열 목록',
            ),
            trailing: SegmentedButton<HomeLayout>(
              segments: const [
                ButtonSegment(
                  value: HomeLayout.grid,
                  icon: Icon(Icons.grid_view, size: 18),
                  tooltip: '2열 그리드',
                ),
                ButtonSegment(
                  value: HomeLayout.list,
                  icon: Icon(Icons.view_list, size: 18),
                  tooltip: '1열 목록',
                ),
              ],
              selected: {state.homeLayout},
              onSelectionChanged: (selection) =>
                  onChangeHomeLayout(selection.first),
              showSelectedIcon: false,
            ),
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: onLogoutTap,
          ),

          ListTile(
            enabled: !state.isDeleting,
            leading: Icon(Icons.delete_forever, color: colorScheme.error),
            title: Text('계정 삭제', style: TextStyle(color: colorScheme.error)),
            onTap: onDeleteTap,
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('개인정보처리방침'),
            onTap: onPrivacyTap,
          ),

          const _VersionTile(),

          // 삭제 진행 중 표시
          if (state.isDeleting)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}

/// 버전 정보 (네이티브 BuildConfig.VERSION_NAME 대응, pubspec.yaml의 version)
class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  // 리빌드마다 다시 읽지 않도록 한 번만 요청
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('버전'),
      trailing: FutureBuilder<PackageInfo>(
        future: _packageInfo,
        builder: (context, snapshot) => Text(
          snapshot.data?.version ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// 이메일 사용자 본인 확인용 비밀번호 입력. 확인 시 비밀번호를, 취소 시 null을 돌려줌
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().isNotEmpty;

    return AlertDialog(
      title: const Text('본인 확인'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const Text('보안을 위해 비밀번호를 다시 입력해주세요.'),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            keyboardType: TextInputType.visiblePassword,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed:
          canSubmit ? () => Navigator.of(context).pop(_controller.text) : null,
          child: Text(
            '삭제',
            style: canSubmit
                ? TextStyle(color: Theme.of(context).colorScheme.error)
                : null,
          ),
        ),
      ],
    );
  }
}