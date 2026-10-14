import 'dart:typed_data';

sealed class ExtractEvent {
  const ExtractEvent();
}

final class ExtractStarted extends ExtractEvent {
  const ExtractStarted();
}

/// 화면에서 캡처한 카드 이미지 바이트
final class ExtractSaveRequested extends ExtractEvent {
  const ExtractSaveRequested(this.bytes);

  final Uint8List bytes;
}