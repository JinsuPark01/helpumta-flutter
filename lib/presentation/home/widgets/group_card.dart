import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../domain/entity/group.dart';

class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.onTap});

  final Group group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasImage = group.imageUrl.trim().isNotEmpty;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage) ...[
            // 이미지 배경
            CachedNetworkImage(
              imageUrl: group.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  ColoredBox(color: colorScheme.surfaceContainerHighest),
              errorWidget: (context, url, error) => const _FallbackBackground(),
            ),
            // 하단 그라데이션 (흰 글자 가독성)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.55, 1.0],
                ),
              ),
            ),
          ] else
          // fallback: 흐린 아이콘 (텍스트랑 안 겹치게)
            const _FallbackBackground(),

          // 텍스트 (하단)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: hasImage ? Colors.white : colorScheme.onSurface,
                  ),
                ),
                Text(
                  '멤버 ${group.memberCount}명',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hasImage
                        ? Colors.white.withValues(alpha: 0.85)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 터치 효과를 이미지 위에 그리기 위해 맨 위에 투명 레이어로 배치
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackBackground extends StatelessWidget {
  const _FallbackBackground();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.groups,
          size: 64,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}