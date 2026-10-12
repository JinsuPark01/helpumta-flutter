import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entity/record_image.dart';
import '../../domain/entity/workout_policy.dart';
import 'record_bloc.dart';
import 'record_event.dart';
import 'record_state.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<void> _pickImage(BuildContext context) async {
    final bloc = context.read<RecordBloc>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || bloc.isClosed) return; // 선택 취소
    bloc.add(RecordImagePicked(file.path));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<RecordBloc, RecordState>(
          listenWhen: (previous, current) =>
          previous.loadStatus != current.loadStatus &&
              current.loadStatus == RecordLoadStatus.failure,
          listener: (context, state) {
            _showSnackBar(context, '기록을 불러오지 못했어요');
            context.pop(); // 결과 없이 닫힘 → 상세는 새로고침하지 않음
          },
        ),
        BlocListener<RecordBloc, RecordState>(
          listenWhen: (previous, current) =>
          previous.submitStatus != current.submitStatus,
          listener: (context, state) {
            switch (state.submitStatus) {
              case RecordSubmitStatus.success:
                _showSnackBar(
                  context,
                  state.isEditMode ? '기록을 수정했어요!' : '기록을 저장했어요!',
                );
                // 저장 완료 결과 전달 → 상세가 오늘로 리셋 + 새로고침
                context.pop(true);
              case RecordSubmitStatus.failure:
                _showSnackBar(
                  context,
                  state.errorMessage ??
                      (state.isEditMode ? '기록 수정에 실패했어요' : '기록 저장에 실패했어요'),
                );
              case RecordSubmitStatus.idle || RecordSubmitStatus.inProgress:
                break;
            }
          },
        ),
      ],
      child: BlocBuilder<RecordBloc, RecordState>(
        builder: (context, state) => _RecordContent(
          state: state,
          onEvent: context.read<RecordBloc>().add,
          onNavigateBack: () => context.pop(), // 결과 없음 → 날짜 유지
          onPickImage: () => _pickImage(context),
        ),
      ),
    );
  }
}

class _RecordContent extends StatelessWidget {
  const _RecordContent({
    required this.state,
    required this.onEvent,
    required this.onNavigateBack,
    required this.onPickImage,
  });

  final RecordState state;
  final void Function(RecordEvent) onEvent;
  final VoidCallback onNavigateBack;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditMode ? '기록 수정' : '운동 기록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '뒤로가기',
          onPressed: onNavigateBack,
        ),
      ),
      body: switch (state.loadStatus) {
      // 수정 모드: 기존 기록 불러오는 중 (실패 시엔 리스너가 화면을 닫음)
        RecordLoadStatus.loading ||
        RecordLoadStatus.failure =>
        const Center(child: CircularProgressIndicator()),
        RecordLoadStatus.ready => _buildForm(context),
      },
    );
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final image = state.image;

    // 입력창은 로딩이 끝난 뒤에 처음 만들어지므로 initialValue로 기존 값을 채울 수 있음
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            // 운동 종류
            TextFormField(
              initialValue: state.workoutType,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '운동 종류',
                hintText: '예: 헬스, 러닝, 사이클',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => onEvent(RecordWorkoutTypeChanged(value)),
            ),

            // 운동 시간
            TextFormField(
              initialValue: state.workoutDuration,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              // 숫자만, 최대값 초과 입력은 입력창 단계에서 무시
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                const _MaxValueInputFormatter(WorkoutPolicy.maxDurationMinutes),
              ],
              decoration: const InputDecoration(
                labelText: '운동 시간 (분, 최대 ${WorkoutPolicy.maxDurationMinutes})',
                hintText: '예: 60',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => onEvent(RecordDurationChanged(value)),
            ),

            // 인증샷 라벨 + 사진 제거 (한 줄)
            SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('인증샷 (선택)', style: theme.textTheme.bodyMedium),
                  if (image is! NoRecordImage)
                    TextButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () => onEvent(const RecordImageRemoved()),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('사진 제거'),
                    ),
                ],
              ),
            ),

            // 인증샷
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Material(
                  color: colorScheme.surfaceContainerHighest,
                  child: InkWell(
                    onTap: state.isSubmitting ? null : onPickImage,
                    child: switch (image) {
                      NewRecordImage(:final path) =>
                          Image.file(File(path), fit: BoxFit.cover),
                      ExistingRecordImage(:final url) => CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                      ),
                      NoRecordImage() => Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 8,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            semanticLabel: '이미지 추가',
                            color: colorScheme.onSurfaceVariant,
                          ),
                          Text(
                            '사진 추가',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    },
                  ),
                ),
              ),
            ),

            // 한줄 소감
            TextFormField(
              initialValue: state.comment,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '한줄 소감 (선택)',
                hintText: '오늘 운동 어땠나요?',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => onEvent(RecordCommentChanged(value)),
            ),

            const SizedBox(height: 8),

            // 작성/수정 완료 버튼 (저장 중이면 스피너)
            if (state.isSubmitting)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: state.isSubmitEnabled
                      ? () => onEvent(const RecordSubmitted())
                      : null,
                  child: Text(state.isEditMode ? '수정 완료' : '기록 남기기'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// [max]를 넘는 숫자 입력은 받아들이지 않고 이전 값을 유지
class _MaxValueInputFormatter extends TextInputFormatter {
  const _MaxValueInputFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    if (newValue.text.isEmpty) return newValue; // 지우는 중 허용
    final value = int.tryParse(newValue.text);
    if (value == null || value > max) return oldValue;
    return newValue;
  }
}