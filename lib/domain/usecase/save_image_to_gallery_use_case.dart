import 'dart:typed_data';

import '../../core/result.dart';
import '../repository/gallery_repository.dart';

class SaveImageToGalleryUseCase {
  const SaveImageToGalleryUseCase(this._galleryRepository);

  final GalleryRepository _galleryRepository;

  Future<Result<void>> call(Uint8List bytes) => _galleryRepository.saveImage(
    bytes,
    fileName: 'helpumta_${DateTime.now().millisecondsSinceEpoch}',
  );
}