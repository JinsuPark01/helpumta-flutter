import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entity/workout_record.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.record,
    required this.canEdit,
    required this.canDelete,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final WorkoutRecord record;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  static final _timeFormat = DateFormat('MM/dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final initial = record.userName.isEmpty ? '' : record.userName.characters.first;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            // 헤더: 아바타 + 이름/시간 + 수정/삭제
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _timeFormat.format(record.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  _SmallIconButton(
                    icon: Icons.edit,
                    tooltip: '수정',
                    onPressed: onEditTap,
                  ),
                if (canDelete)
                  _SmallIconButton(
                    icon: Icons.delete,
                    tooltip: '삭제',
                    onPressed: onDeleteTap,
                  ),
              ],
            ),

            // 운동 정보
            Row(
              spacing: 8,
              children: [
                Flexible(
                  child: Chip(
                    label: Text(
                      record.workoutType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    '${record.workoutDuration}분',
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ],
            ),

            // 소감 (있으면)
            if (record.comment.trim().isNotEmpty)
              Text(
                record.comment,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),

            // 인증샷 (있으면)
            if (record.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: record.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        ColoredBox(color: colorScheme.surfaceContainerHighest),
                    errorWidget: (context, url, error) => ColoredBox(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.broken_image,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 18),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      padding: EdgeInsets.zero,
    );
  }
}