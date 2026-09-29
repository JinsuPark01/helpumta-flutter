import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import 'sign_up_bloc.dart';
import 'sign_up_event.dart';
import 'sign_up_state.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpBloc, SignUpState>(
      listenWhen: (previous, current) =>
      previous.status != current.status &&
          current.status == SignUpStatus.success,
      listener: (context, state) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('회원가입이 완료됐어요!')),
        );
        context.go(AppRoutes.home);
      },
      child: BlocBuilder<SignUpBloc, SignUpState>(
        builder: (context, state) => _SignUpContent(
          state: state,
          onEvent: context.read<SignUpBloc>().add,
          onNavigateBack: () => context.pop(),
        ),
      ),
    );
  }
}

class _SignUpContent extends StatelessWidget {
  const _SignUpContent({
    required this.state,
    required this.onEvent,
    required this.onNavigateBack,
  });

  final SignUpState state;
  final void Function(SignUpEvent) onEvent;
  final VoidCallback onNavigateBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final showEmailError = state.email.trim().isNotEmpty && !state.isValidEmail;
    final showPasswordMismatch = state.password.trim().isNotEmpty &&
        state.passwordConfirm.trim().isNotEmpty &&
        state.password != state.passwordConfirm;

    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로가기',
          onPressed: onNavigateBack,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              const SizedBox(height: 16),

              // 이메일
              TextField(
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '이메일',
                  border: const OutlineInputBorder(),
                  errorText: showEmailError ? '올바른 이메일 형식이 아닙니다' : null,
                ),
                onChanged: (value) => onEvent(SignUpEmailChanged(value)),
              ),

              // 닉네임
              TextField(
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onEvent(SignUpNicknameChanged(value)),
              ),

              // 비밀번호
              TextField(
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '비밀번호 (6자 이상)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => onEvent(SignUpPasswordChanged(value)),
              ),

              // 비밀번호 확인
              TextField(
                obscureText: true,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  labelText: '비밀번호 확인',
                  border: const OutlineInputBorder(),
                  errorText: showPasswordMismatch ? '비밀번호가 일치하지 않습니다' : null,
                ),
                onChanged: (value) =>
                    onEvent(SignUpPasswordConfirmChanged(value)),
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

              // 가입 버튼 (로딩 중이면 버튼 대신 스피너)
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: state.isSignUpEnabled
                        ? () => onEvent(const SignUpSubmitted())
                        : null,
                    child: const Text('가입하기'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}