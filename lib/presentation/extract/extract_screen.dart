import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entity/extract_slot.dart';
import 'extract_bloc.dart';
import 'extract_event.dart';
import 'extract_state.dart';

/// 저장되는 이미지 폭 (9:16 → 1080 × 1920). 기기 화면 크기와 무관하게 고정
const _outputWidth = 1080.0;

/// 칸 세로 최대 비율 (칸 높이 = 카드 폭 × 이 값)
const _slotMaxHeightRatio = 0.55;

class ExtractScreen extends StatefulWidget {
  const ExtractScreen({super.key});

  @override
  State<ExtractScreen> createState() => _ExtractScreenState();
}

class _ExtractScreenState extends State<ExtractScreen> {
  /// 캡처 대상(RepaintBoundary)을 찾기 위한 키
  final _canvasKey = GlobalKey();

  /// 카드 안 이미지가 모두 받아졌는지 (순수 UI 관심사라 Bloc 미경유)
  bool _imagesReady = false;

  @override
  void initState() {
    super.initState();
    // 화면이 붙기 전에 이미 로딩이 끝났을 경우 대비
    final state = context.read<ExtractBloc>().state;
    if (state.status == ExtractStatus.success) _prepareImages(state.slots);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 캡처 전에 카드 이미지를 전부 미리 받아둔다.
  /// 실패한 이미지도 "더 기다릴 필요 없음"으로 처리 (네이티브 onSuccess/onError 카운트 대체)
  Future<void> _prepareImages(List<ExtractSlot> slots) async {
    setState(() => _imagesReady = false);

    final urls = slots
        .whereType<RecordedSlot>()
        .map((slot) => slot.imageUrl)
        .where((url) => url.isNotEmpty);

    await Future.wait(
      urls.map(
            (url) => precacheImage(
          CachedNetworkImageProvider(url),
          context,
          onError: (error, stackTrace) {},
        ),
      ),
    );

    if (mounted) setState(() => _imagesReady = true);
  }

  /// 카드를 1080 × 1920 PNG로 캡처해서 Bloc에 저장 요청
  Future<void> _captureAndSave() async {
    final bloc = context.read<ExtractBloc>();
    final boundary =
    _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final pixelRatio = _outputWidth / boundary.size.width;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();

    if (byteData == null) {
      if (mounted) _showSnackBar('저장에 실패했어요. 다시 시도해주세요.');
      return;
    }
    if (!bloc.isClosed) {
      bloc.add(ExtractSaveRequested(byteData.buffer.asUint8List()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExtractBloc, ExtractState>(
          listenWhen: (previous, current) =>
          previous.status != current.status &&
              current.status == ExtractStatus.success,
          listener: (context, state) => _prepareImages(state.slots),
        ),
        BlocListener<ExtractBloc, ExtractState>(
          listenWhen: (previous, current) =>
          previous.saveStatus != current.saveStatus,
          listener: (context, state) {
            switch (state.saveStatus) {
              case ExtractSaveStatus.success:
                _showSnackBar('갤러리에 저장했어요!');
                context.pop();
              case ExtractSaveStatus.failure:
                _showSnackBar(
                  state.saveErrorMessage ?? '저장에 실패했어요. 다시 시도해주세요.',
                );
              case ExtractSaveStatus.idle || ExtractSaveStatus.inProgress:
                break;
            }
          },
        ),
      ],
      child: BlocBuilder<ExtractBloc, ExtractState>(
        builder: (context, state) {
          final colorScheme = Theme.of(context).colorScheme;
          final hasSlots = state.slots.isNotEmpty;
          final isBusy = state.isSaving || !_imagesReady;

          return Scaffold(
            appBar: AppBar(
              title: const Text('사진 추출'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: '뒤로가기',
                onPressed: () => context.pop(),
              ),
            ),
            floatingActionButton: !hasSlots
                ? null
                : FloatingActionButton(
              // 저장 중 / 이미지 로딩 중이면 스피너, 누를 수 없음
              onPressed: isBusy ? null : _captureAndSave,
              tooltip: '이미지 저장',
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              child: isBusy
                  ? SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
                  : const Icon(Icons.download),
            ),
            body: Center(
              child: switch (state.status) {
                ExtractStatus.loading => const CircularProgressIndicator(),
                ExtractStatus.failure => Text(
                  '추출 데이터를 불러오지 못했어요',
                  style: TextStyle(color: colorScheme.error),
                ),
                ExtractStatus.success when !hasSlots => Text(
                  '이 날에는 추출할 기록이 없어요',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                ExtractStatus.success => _ExtractCanvas(
                  canvasKey: _canvasKey,
                  slots: state.slots,
                ),
              },
            ),
          );
        },
      ),
    );
  }
}

/// 추출 결과물 본체 (이 영역을 캡처함)
class _ExtractCanvas extends StatelessWidget {
  const _ExtractCanvas({required this.canvasKey, required this.slots});

  final GlobalKey canvasKey;
  final List<ExtractSlot> slots;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.85,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        // 화면에선 둥근 모서리, 저장 이미지는 RepaintBoundary 안쪽이라 사각형
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: RepaintBoundary(
            key: canvasKey,
            // 결과물 이미지라 시스템 글자 크기 설정과 무관하게 항상 같은 레이아웃
            child: MediaQuery.withNoTextScaling(
              child: ColoredBox(
                color: Colors.black,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final count = slots.isEmpty ? 1 : slots.length;

                    // 칸 높이 = min(꽉 채운 높이, 상한). 상한 = 폭 × 비율
                    final evenHeight = constraints.maxHeight / count;
                    final maxSlotHeight =
                        constraints.maxWidth * _slotMaxHeightRatio;
                    final slotHeight =
                    evenHeight < maxSlotHeight ? evenHeight : maxSlotHeight;

                    return Column(
                      // 위아래 남는 공간은 절반씩
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final slot in slots)
                          SizedBox(
                            height: slotHeight,
                            width: double.infinity,
                            child: switch (slot) {
                              RecordedSlot() => _RecordedSlot(slot),
                              EmptySlot() => _EmptySlot(slot),
                            },
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordedSlot extends StatelessWidget {
  const _RecordedSlot(this.slot);

  final RecordedSlot slot;

  static const _fallbackColor = Color(0xFF3B4A5A);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 배경: 인증샷 (미리 받아둔 이미지라 바로 표시, 페이드인 없이 캡처에 안전)
        if (slot.imageUrl.isNotEmpty)
          Image(
            image: CachedNetworkImageProvider(slot.imageUrl),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: _fallbackColor),
          )
        else
          const ColoredBox(color: _fallbackColor),

        // 가독성용 어둡게
        ColoredBox(color: Colors.black.withValues(alpha: 0.28)),

        // 텍스트 (좌: 이름/소감, 우: 시간/종목)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              // 좌측: 남은 공간만 차지 → 우측에 양보, 넘치면 말줄임
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (slot.comment.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        slot.comment,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 우측: 콘텐츠 크기대로 먼저 자리 차지 (시간/종목 값 보존)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ValueText('${slot.workoutDuration}분'),
                  const _LabelText('운동 시간'),
                  const SizedBox(height: 7),
                  ConstrainedBox(
                    // 종목 상한 (극단적으로 긴 경우만 제한)
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: _ValueText(slot.workoutType),
                  ),
                  const _LabelText('운동 종목'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot(this.slot);

  final EmptySlot slot;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1A1A1A), // 미기록 어두운 배경
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        // 기록자와 동일한 좌우 레이아웃, 전체를 흐리게
        child: Row(
          children: [
            // 좌측: 이름 / 💤
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slot.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '💤 ',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // 우측: -- / 라벨
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ValueText('--', dimmed: true),
                _LabelText('운동 시간', dimmed: true),
                SizedBox(height: 7),
                _ValueText('--', dimmed: true),
                _LabelText('운동 종목', dimmed: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueText extends StatelessWidget {
  const _ValueText(this.text, {this.dimmed = false});

  final String text;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: dimmed ? Colors.white.withValues(alpha: 0.5) : Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  const _LabelText(this.text, {this.dimmed = false});

  final String text;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: dimmed ? 0.35 : 0.7),
        fontSize: 9,
      ),
    );
  }
}