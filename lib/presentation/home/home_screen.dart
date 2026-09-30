import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../domain/entity/group_policy.dart';
import 'home_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';
import 'widgets/group_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// 다른 화면으로 이동했다가 돌아오면 목록 새로고침 (네이티브 ON_RESUME 대체)
  static Future<void> _pushAndRefresh(
      BuildContext context,
      String location,
      ) async {
    final bloc = context.read<HomeBloc>();
    await context.push(location);
    if (!bloc.isClosed) bloc.add(const HomeGroupsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) => _HomeContent(
        state: state,
        onGroupClick: (groupId) =>
            _pushAndRefresh(context, AppRoutes.groupDetailPath(groupId)),
        onCreateClick: () => _pushAndRefresh(context, AppRoutes.groupCreate),
        onMyPageClick: () => context.push(AppRoutes.myPage),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.state,
    required this.onGroupClick,
    required this.onCreateClick,
    required this.onMyPageClick,
  });

  final HomeState state;
  final ValueChanged<String> onGroupClick;
  final VoidCallback onCreateClick;
  final VoidCallback onMyPageClick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 목록이 있으면 새로고침 중이어도 그리드 유지
    final body = switch (state) {
      HomeState(groups: [_, ...]) => _GroupGrid(
        state: state,
        onGroupClick: onGroupClick,
      ),
      HomeState(status: HomeStatus.failure) => Center(
        child: Text(
          state.errorMessage ?? '그룹을 불러올 수 없습니다',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.error,
          ),
        ),
      ),
      HomeState(status: HomeStatus.success) => const _EmptyGuide(),
      _ => const Center(child: CircularProgressIndicator()),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('헬품타'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: '마이페이지',
            onPressed: onMyPageClick,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onCreateClick,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        tooltip: '그룹 만들기',
        child: const Icon(Icons.add),
      ),
      body: body,
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.state, required this.onGroupClick});

  final HomeState state;
  final ValueChanged<String> onGroupClick;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1, // 네이티브 GroupCard aspectRatio(1f)
      ),
      itemCount: state.groups.length,
      itemBuilder: (context, index) {
        final group = state.groups[index];
        return GroupCard(
          key: ValueKey(group.id),
          group: group,
          onTap: () => onGroupClick(group.id),
        );
      },
    );
  }
}

class _EmptyGuide extends StatelessWidget {
  const _EmptyGuide();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final guideStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 세로 라인 + 인트로 문단
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '헬품타에 오신 걸 환영해요',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '친구들과 그룹을 만들어\n운동 기록을 함께 공유해보세요',
                          style: guideStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 안내 카드
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    _GuideItem(
                      '그룹은 최대 ${GroupPolicy.maxMembers}명까지 참여할 수 있어요',
                      style: guideStyle,
                    ),
                    _GuideItem('하루에 한 번 운동 기록을 남길 수 있어요', style: guideStyle),
                    _GuideItem(
                      '그룹원들의 하루 기록을 한 장의 사진으로 저장할 수 있어요',
                      style: guideStyle,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // FAB 모양 배지 + 안내
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      size: 12,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('버튼으로 그룹을 만들어보세요', style: hintStyle),
                ],
              ),
            ),

            const SizedBox(height: 4),

            Center(
              child: Text('친구에게 받은 초대 링크로도 참여할 수 있어요', style: hintStyle),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  const _GuideItem(this.text, {this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('·', style: style),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}