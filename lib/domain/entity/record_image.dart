import 'package:equatable/equatable.dart';

/// 기록 이미지의 세 가지 상태.
/// 네이티브는 String 하나로 표현하고 "http로 시작하는지"로 구분했다.
sealed class RecordImage extends Equatable {
  const RecordImage();

  @override
  List<Object?> get props => [];
}

/// 사진 없음 (또는 제거)
final class NoRecordImage extends RecordImage {
  const NoRecordImage();
}

/// 서버에 이미 있는 사진을 유지
final class ExistingRecordImage extends RecordImage {
  const ExistingRecordImage(this.url);

  final String url;

  @override
  List<Object?> get props => [url];
}

/// 새로 고른 기기 내 사진
final class NewRecordImage extends RecordImage {
  const NewRecordImage(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}