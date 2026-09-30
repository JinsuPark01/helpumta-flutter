import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

/// 긴 변을 [maxSize] 이하로 줄이고 JPEG로 재인코딩한다. EXIF 회전 보정 포함.
class ImageCompressor {
  static const defaultMaxSize = 1920;
  static const defaultQuality = 85;

  Future<Uint8List> compress(
      String path, {
        int maxSize = defaultMaxSize,
        int quality = defaultQuality,
      }) async {
    final targetShortSide = await _targetShortSide(path, maxSize);

    // flutter_image_compress는 minWidth/minHeight 비율 중 "작은 쪽" 기준으로 축소한다.
    // 둘 다 목표 짧은 변 길이로 주면, 회전 여부와 무관하게 긴 변이 maxSize가 된다.
    final result = await FlutterImageCompress.compressWithFile(
      path,
      minWidth: targetShortSide,
      minHeight: targetShortSide,
      quality: quality,
      format: CompressFormat.jpeg,
      autoCorrectionAngle: true,
    );

    if (result == null) {
      throw Exception('이미지를 압축할 수 없습니다');
    }
    return result;
  }

  /// 원본 크기를 헤더만 읽어서(전체 디코드 없이) 목표 짧은 변 길이 계산
  Future<int> _targetShortSide(String path, int maxSize) async {
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      try {
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        try {
          final longSide = math.max(descriptor.width, descriptor.height);
          final shortSide = math.min(descriptor.width, descriptor.height);
          if (longSide <= maxSize) return shortSide;
          return (shortSide * maxSize / longSide).round();
        } finally {
          descriptor.dispose();
        }
      } finally {
        buffer.dispose();
      }
    } on Exception {
      // 크기를 못 읽는 포맷이면 짧은 변 기준으로라도 줄이기
      return maxSize;
    }
  }
}