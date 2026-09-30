import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'group_create_bloc.dart';
import 'group_create_event.dart';
import 'group_create_state.dart';

class GroupCreateScreen extends StatelessWidget {
  const GroupCreateScreen({super.key});

  static Future<void> _pickImage(BuildContext context) async {
    final bloc = context.read<GroupCreateBloc>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || bloc.isClosed) return; // 선택 취소
    bloc.add(GroupCreateImagePicked(file.path));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GroupCreateBloc, GroupCreateState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case GroupCreateStatus.success:
          // 만든 그룹 ID를 결과로 돌려주고 닫힘 → 홈이 새로고침 후 상세로 이동
            context.pop(state.createdGroupId);
          case GroupCreateStatus.failure:
          // 이전 스낵바를 닫고 바로 새로 표시 (연속 실패 시 줄 서지 않게)
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? '그룹 생성에 실패했어요'),
                ),
              );
          case GroupCreateStatus.initial || GroupCreateStatus.loading:
            break;
        }
      },
      child: BlocBuilder<GroupCreateBloc, GroupCreateState>(
        builder: (context, state) => _GroupCreateContent(
          state: state,
          onEvent: context.read<GroupCreateBloc>().add,
          onNavigateBack: () => context.pop(),
          onPickImage: () => _pickImage(context),
        ),
      ),
    );
  }
}

class _GroupCreateContent extends StatelessWidget {
  const _GroupCreateContent({
    required this.state,
    required this.onEvent,
    required this.onNavigateBack,
    required this.onPickImage,
  });

  final GroupCreateState state;
  final void Function(GroupCreateEvent) onEvent;
  final VoidCallback onNavigateBack;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final imagePath = state.imagePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로가기',
          onPressed: onNavigateBack,
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              // 평소엔 남는 공간을 채워 버튼을 바닥에 두고,
              // 키보드가 올라와 공간이 부족하면 스크롤로 전환
              sliver: SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    // 그룹 대표 이미지
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Material(
                          color: colorScheme.surfaceContainerHighest,
                          child: InkWell(
                            onTap: state.isLoading ? null : onPickImage,
                            child: imagePath != null
                                ? Image.file(File(imagePath), fit: BoxFit.cover)
                                : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 8,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  semanticLabel: '이미지 추가',
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                Text(
                                  '그룹 대표 이미지 추가',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 그룹 이름
                    TextField(
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '그룹 이름',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          onEvent(GroupCreateNameChanged(value)),
                    ),

                    // 그룹 설명
                    TextField(
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '그룹 설명 (선택)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) =>
                          onEvent(GroupCreateDescriptionChanged(value)),
                    ),

                    const Spacer(),

                    // 생성 버튼 (로딩 중이면 버튼 대신 스피너)
                    if (state.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: state.isCreateEnabled
                              ? () => onEvent(const GroupCreateSubmitted())
                              : null,
                          child: const Text('그룹 만들기'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}