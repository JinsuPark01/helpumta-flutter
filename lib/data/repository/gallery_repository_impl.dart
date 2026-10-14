import 'dart:typed_data';

import 'package:gal/gal.dart';

import '../../core/result.dart';
import '../../domain/entity/gallery_exception.dart';
import '../../domain/repository/gallery_repository.dart';

/// 네이티브 ImageSaver(MediaStore + 버전별 권한 분기) 대응.
/// 권한 요청과 Android 버전별 저장 방식은 gal이 처리한다.
class GalleryRepositoryImpl implements GalleryRepository {
  static const _album = '헬품타';

  @override
  Future<Result<void>> saveImage(
      Uint8List bytes, {
        required String fileName,
      }) async {
    try {
      await Gal.putImageBytes(bytes, album: _album, name: fileName);
      return const Result.ok(null);
    } on GalException catch (e) {
      if (e.type == GalExceptionType.accessDenied) {
        return const Result.error(GalleryAccessDeniedException());
      }
      return Result.error(e);
    } on Exception catch (e) {
      return Result.error(e);
    }
  }
}