import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../core/date_utils.dart';
import '../../domain/entity/group_policy.dart';
import '../../domain/entity/workout_record.dart';
import 'group_detail_bloc.dart';
import 'group_detail_event.dart';
import 'group_detail_state.dart';
import 'widgets/record_card.dart';

enum _MenuAction { extract, copyName, leave }

class GroupDetailScreen extends StatelessWidget {
  const GroupDetailScreen({super.key});

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 기록 작성·수정 화면이 저장 완료(true)를 돌려주면 오늘로 리셋 + 새로고침
  static Future<void> _openRecordScreen(
      BuildContext context,
      String location,
      ) async {
    final bloc = context.read<GroupDetailBloc>();
    final saved = await context.push<bool>(location);
    if (saved == true && !bloc.isClosed) {
      bloc.add(const GroupDetailRefreshedToToday());
    }
  }

  static Future<void> _onWriteTap(
      BuildContext context,
      GroupDetailState state,
      ) async {
    if (state.hasWroteToday) {
      _showSnackBar(context, '오늘 기록은 이미 작성했어요');
      return;
    }
    await _openRecordScreen(context, AppRoutes.recordCreatePath(state.groupId));
  }

  static Future<void> _pickDate(
      BuildContext context,
      DateTime selectedDate,
      ) async {
    final bloc = context.read<GroupDetailBloc>();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(), // 미래 선택 불가
    );
    if (picked != null && !bloc.isClosed) {
      bloc.add(GroupDetailDateChanged(picked));
    }
  }

  static Future<void> _confirmDelete(
      BuildContext context,
      WorkoutRecord record,
      ) async {
    final bloc = context.read<GroupDetailBloc>();
    final isToday = record.createdAt.isSameDay(DateTime.now());

    final confirmed = await _showConfirmDialog(
      context,
      title: '기록 삭제',
      message: isToday
          ? '삭제하면 사진도 함께 삭제되며 복구할 수 없어요. 오늘 기록은 다시 작성할 수 있어요.'
          : '삭제하면 사진도 함께 삭제되며 복구할 수 없어요. 지난 날짜는 다시 작성할 수 없어요.',
      confirmLabel: '삭제',
    );
    if (confirmed && !bloc.isClosed) {
      bloc.add(GroupDetailRecordDeleteRequested(record.id));
    }
  }

  static Future<void> _confirmLeave(BuildContext context) async {
    final bloc = context.read<GroupDetailBloc>();
    final confirmed = await _showConfirmDialog(
      context,
      title: '그룹 나가기',
      message:
      '그룹을 나가면 이 그룹에 작성한 내 기록과 사진이 모두 삭제되며 복구할 수 없어요. 정말 나가시겠어요?',
      confirmLabel: '나가기',
    );
    if (confirmed && !bloc.isClosed) {
      bloc.add(const GroupDetailLeaveRequested());
    }
  }

  /// 사용자의 선택을 Future로 돌려받는 확인 다이얼로그
  static Future<bool> _showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmLabel,
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
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> _onMenuSelected(
      BuildContext context,
      GroupDetailState state,
      _MenuAction action,
      ) async {
    switch (action) {
      case _MenuAction.extract:
        context.push(AppRoutes.extractPath(state.groupId, state.selectedDate));
      case _MenuAction.copyName:
      // 초대 참여 기능 구현 전까지는 그룹 이름만 복사
        final name = state.group?.name ?? '';
        await Clipboard.setData(ClipboardData(text: name));
        if (context.mounted) _showSnackBar(context, '그룹 이름을 복사했어요');
      case _MenuAction.leave:
        await _confirmLeave(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GroupDetailBloc, GroupDetailState>(
          listenWhen: (previous, current) =>
          previous.deleteStatus != current.deleteStatus,
          listener: (context, state) {
            switch (state.deleteStatus) {
              case GroupDetailActionStatus.success:
                _showSnackBar(context, '기록을 삭제했어요');
              case GroupDetailActionStatus.failure:
                _showSnackBar(
                  context,
                  state.actionErrorMessage ?? '기록 삭제에 실패했어요. 다시 시도해주세요.',
                );
              case GroupDetailActionStatus.idle ||
              GroupDetailActionStatus.inProgress:
                break;
            }
          },
        ),
        BlocListener<GroupDetailBloc, GroupDetailState>(
          listenWhen: (previous, current) =>
          previous.leaveStatus != current.leaveStatus,
          listener: (context, state) {
            switch (state.leaveStatus) {
              case GroupDetailActionStatus.success:
              // 홈의 await push()가 완료되며 목록 새로고침
                context.pop();
              case GroupDetailActionStatus.failure:
                _showSnackBar(
                  context,
                  state.actionErrorMessage ?? '그룹 나가기에 실패했어요. 다시 시도해주세요.',
                );
              case GroupDetailActionStatus.idle ||
              GroupDetailActionStatus.inProgress:
                break;
            }
          },
        ),
      ],
      child: BlocBuilder<GroupDetailBloc, GroupDetailState>(
        builder: (context, state) => _GroupDetailContent(
          state: state,
          onNavigateBack: () => context.pop(),
          onMenuSelected: (action) => _onMenuSelected(context, state, action),
          onWriteTap: () => _onWriteTap(context, state),
          onPrevDay: () => context
              .read<GroupDetailBloc>()
              .add(GroupDetailDateChanged(state.selectedDate.addDays(-1))),
          onNextDay: () => context
              .read<GroupDetailBloc>()
              .add(GroupDetailDateChanged(state.selectedDate.addDays(1))),
          onDateTap: () => _pickDate(context, state.selectedDate),
          onEditRecord: (record) => _openRecordScreen(
            context,
            AppRoutes.recordEditPath(state.groupId, record.id),
          ),
          onDeleteRecord: (record) => _confirmDelete(context, record),
        ),
      ),
    );
  }
}

class _GroupDetailContent extends StatelessWidget {
  const _GroupDetailContent({
    required this.state,
    required this.onNavigateBack,
    required this.onMenuSelected,
    required this.onWriteTap,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onDateTap,
    required this.onEditRecord,
    required this.onDeleteRecord,
  });

  final GroupDetailState state;
  final VoidCallback onNavigateBack;
  final ValueChanged<_MenuAction> onMenuSelected;
  final VoidCallback onWriteTap;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onDateTap;
  final ValueChanged<WorkoutRecord> onEditRecord;
  final ValueChanged<WorkoutRecord> onDeleteRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final group = state.group;

    final body = switch (state.status) {
      GroupDetailStatus.loading =>
      const Center(child: CircularProgressIndicator()),
      GroupDetailStatus.failure => Center(
        child: Text(
          '그룹을 불러올 수 없습니다',
          style: TextStyle(color: colorScheme.error),
        ),
      ),
      GroupDetailStatus.success => Column(
        children: [
          _DateNavigationBar(
            selectedDate: state.selectedDate,
            isToday: state.isSelectedToday,
            onPrevDay: onPrevDay,
            onNextDay: onNextDay,
            onDateTap: onDateTap,
          ),
          const Divider(height: 1),
          Expanded(child: _buildRecords(context)),
        ],
      ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로가기',
          onPressed: onNavigateBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group?.name ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (group != null)
              Text(
                '멤버 ${group.memberCount} / ${GroupPolicy.maxMembers}명',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (group != null)
            PopupMenuButton<_MenuAction>(
              tooltip: '메뉴',
              icon: const Icon(Icons.more_vert),
              onSelected: onMenuSelected,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: _MenuAction.extract,
                  child: ListTile(
                    leading: Icon(Icons.image),
                    title: Text('사진 추출'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: _MenuAction.copyName,
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('초대 코드 복사'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _MenuAction.leave,
                  child: ListTile(
                    leading: Icon(Icons.logout, color: colorScheme.error),
                    title: Text(
                      '그룹 나가기',
                      style: TextStyle(color: colorScheme.error),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: group == null
          ? null
          : FloatingActionButton(
        onPressed: onWriteTap,
        tooltip:
        state.hasWroteToday ? '오늘은 이미 작성했어요' : '오늘 기록 작성',
        // 네이티브 DisabledGray/OnDisabledGray 대신 M3 비활성 색 규칙 사용
        backgroundColor: state.hasWroteToday
            ? colorScheme.onSurface.withValues(alpha: 0.12)
            : colorScheme.primary,
        foregroundColor: state.hasWroteToday
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : colorScheme.onPrimary,
        child: const Icon(Icons.edit),
      ),
      body: body,
    );
  }

  Widget _buildRecords(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (state.isRecordsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final recordsError = state.recordsErrorMessage;
    if (recordsError != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            margin: EdgeInsets.zero,
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                recordsError,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ),
        ),
      );
    }

    if (state.records.isEmpty) {
      return Center(
        child: Text(
          state.isSelectedToday
              ? '아직 오늘 기록이 없어요\n첫 기록을 남겨보세요!'
              : '이 날에는 운동 기록이 없어요',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final now = DateTime.now();
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = state.records[index];
        final isMine = record.userId == state.currentUserId;
        return RecordCard(
          key: ValueKey(record.id),
          record: record,
          // 수정은 본인 + 오늘 작성한 기록만, 삭제는 본인 기록 전체
          canEdit: isMine && record.createdAt.isSameDay(now),
          canDelete: isMine,
          onEditTap: () => onEditRecord(record),
          onDeleteTap: () => onDeleteRecord(record),
        );
      },
    );
  }
}

class _DateNavigationBar extends StatelessWidget {
  const _DateNavigationBar({
    required this.selectedDate,
    required this.isToday,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onDateTap,
  });

  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onDateTap;

  static final _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: '이전 날',
            onPressed: onPrevDay,
          ),
          InkWell(
            onTap: onDateTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                _dateFormat.format(selectedDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: '다음 날',
            // 오늘이면 다음 날 비활성화
            onPressed: isToday ? null : onNextDay,
          ),
        ],
      ),
    );
  }
}