import 'dart:typed_data';

import '../../core/result.dart';

abstract interface class GalleryRepository {
  /// 이미지 바이트를 기기 갤러리(헬품타 앨범)에 저장
  Future<Result<void>> saveImage(Uint8List bytes, {required String fileName});
}