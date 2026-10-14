import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/entity/gallery_exception.dart';
import '../../domain/usecase/get_daily_extract_use_case.dart';
import '../../domain/usecase/save_image_to_gallery_use_case.dart';
import 'extract_event.dart';
import 'extract_state.dart';

class ExtractBloc extends Bloc<ExtractEvent, ExtractState> {
  ExtractBloc({
    required String groupId,
    required DateTime date,
    required GetDailyExtractUseCase getDailyExtractUseCase,
    required SaveImageToGalleryUseCase saveImageToGalleryUseCase,
  })  : _getDailyExtractUseCase = getDailyExtractUseCase,
        _saveImageToGalleryUseCase = saveImageToGalleryUseCase,
        super(ExtractState(groupId: groupId, date: date)) {
    on<ExtractStarted>(_onStarted);
    // 저장 중 중복 요청 무시
    on<ExtractSaveRequested>(_onSaveRequested, transformer: droppable());
  }

  final GetDailyExtractUseCase _getDailyExtractUseCase;
  final SaveImageToGalleryUseCase _saveImageToGalleryUseCase;

  Future<void> _onStarted(
      ExtractStarted event,
      Emitter<ExtractState> emit,
      ) async {
    emit(state.copyWith(status: ExtractStatus.loading));

    final result = await _getDailyExtractUseCase(
      groupId: state.groupId,
      date: state.date,
    );

    switch (result) {
      case Ok(value: final slots):
        emit(state.copyWith(status: ExtractStatus.success, slots: slots));
      case Error():
        emit(state.copyWith(status: ExtractStatus.failure));
    }
  }

  Future<void> _onSaveRequested(
      ExtractSaveRequested event,
      Emitter<ExtractState> emit,
      ) async {
    emit(state.copyWith(
      saveStatus: ExtractSaveStatus.inProgress,
      saveErrorMessage: () => null,
    ));

    final result = await _saveImageToGalleryUseCase(event.bytes);

    switch (result) {
      case Ok():
        emit(state.copyWith(saveStatus: ExtractSaveStatus.success));
      case Error(error: GalleryAccessDeniedException()):
        emit(state.copyWith(
          saveStatus: ExtractSaveStatus.failure,
          saveErrorMessage: () => '저장하려면 권한이 필요해요',
        ));
      case Error():
        emit(state.copyWith(
          saveStatus: ExtractSaveStatus.failure,
          saveErrorMessage: () => '저장에 실패했어요. 다시 시도해주세요.',
        ));
    }
  }
}