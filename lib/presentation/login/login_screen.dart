import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import 'login_bloc.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
      previous.status != current.status &&
          current.status == LoginStatus.success,
      listener: (context, state) => context.go(AppRoutes.home),
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) => _LoginContent(
          state: state,
          onEvent: context.read<LoginBloc>().add,
          onNavigateToSignUp: () => context.push(AppRoutes.signUp),
        ),
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  const _LoginContent({
    required this.state,
    required this.onEvent,
    required this.onNavigateToSignUp,
  });

  final LoginState state;
  final void Function(LoginEvent) onEvent;
  final VoidCallback onNavigateToSignUp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                // 앱 타이틀
                Text(
                  '헬품타',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '오늘도 같이 운동하자',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // 이메일 입력
                TextField(
                  enabled: !state.isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onEvent(LoginEmailChanged(value)),
                ),

                // 비밀번호 입력
                TextField(
                  enabled: !state.isLoading,
                  obscureText: true,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onEvent(LoginPasswordChanged(value)),
                ),

                // 에러 메시지
                if (state.errorMessage != null)
                  Text(
                    state.errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),

                const SizedBox(height: 8),

                // 로그인 버튼 (로딩 중이면 비활성화, 안에 스피너)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: state.isLoginEnabled && !state.isLoading
                        ? () => onEvent(const LoginSubmitted())
                        : null,
                    child: state.isLoading
                        ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                        : const Text('로그인'),
                  ),
                ),

                // 구글 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: state.isLoading
                        ? null
                        : () => onEvent(const LoginGoogleRequested()),
                    child: const Text('Google로 로그인'),
                  ),
                ),

                TextButton(
                  onPressed: state.isLoading ? null : onNavigateToSignUp,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '계정이 없으신가요? ',
                          style: TextStyle(color: colorScheme.onSurface),
                        ),
                        TextSpan(
                          text: '회원가입',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}