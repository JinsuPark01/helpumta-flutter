import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/entity/network_exception.dart';
import '../../domain/entity/record_exception.dart';
import '../../domain/entity/record_image.dart';
import '../../domain/usecase/create_record_use_case.dart';
import '../../domain/usecase/get_record_by_id_use_case.dart';
import '../../domain/usecase/update_record_use_case.dart';
import 'record_event.dart';
import 'record_state.dart';

class RecordBloc extends Bloc<RecordEvent, RecordState> {
  RecordBloc({
    required String groupId,
    String? recordId,
    required CreateRecordUseCase createRecordUseCase,
    required UpdateRecordUseCase updateRecordUseCase,
    required GetRecordByIdUseCase getRecordByIdUseCase,
  })  : _createRecordUseCase = createRecordUseCase,
        _updateRecordUseCase = updateRecordUseCase,
        _getRecordByIdUseCase = getRecordByIdUseCase,
        super(RecordState(
        groupId: groupId,
        recordId: recordId,
        loadStatus:
        recordId == null ? RecordLoadStatus.ready : RecordLoadStatus.loading,
      )) {
    on<RecordStarted>(_onStarted);
    on<RecordWorkoutTypeChanged>(
          (event, emit) => emit(state.copyWith(workoutType: event.workoutType)),
    );
    on<RecordDurationChanged>(
          (event, emit) => emit(state.copyWith(workoutDuration: event.duration)),
    );
    on<RecordImagePicked>(
          (event, emit) => emit(state.copyWith(image: NewRecordImage(event.path))),
    );
    on<RecordImageRemoved>(
          (event, emit) => emit(state.copyWith(image: const NoRecordImage())),
    );
    on<RecordCommentChanged>(
          (event, emit) => emit(state.copyWith(comment: event.comment)),
    );
    // 저장 중 중복 요청 무시
    on<RecordSubmitted>(_onSubmitted, transformer: droppable());
  }

  final CreateRecordUseCase _createRecordUseCase;
  final UpdateRecordUseCase _updateRecordUseCase;
  final GetRecordByIdUseCase _getRecordByIdUseCase;

  Future<void> _onStarted(
      RecordStarted event,
      Emitter<RecordState> emit,
      ) async {
    final recordId = state.recordId;
    if (recordId == null) return; // 작성 모드는 불러올 것 없음

    final result = await _getRecordByIdUseCase(recordId);

    switch (result) {
      case Ok(value: final record):
        emit(state.copyWith(
          loadStatus: RecordLoadStatus.ready,
          workoutType: record.workoutType,
          workoutDuration: record.workoutDuration.toString(),
          image: record.imageUrl.isEmpty
              ? const NoRecordImage()
              : ExistingRecordImage(record.imageUrl),
          comment: record.comment,
        ));
      case Error():
        emit(state.copyWith(loadStatus: RecordLoadStatus.failure));
    }
  }

  Future<void> _onSubmitted(
      RecordSubmitted event,
      Emitter<RecordState> emit,
      ) async {
    if (!state.isSubmitEnabled) return;

    emit(state.copyWith(
      submitStatus: RecordSubmitStatus.inProgress,
      errorMessage: () => null,
    ));

    final workoutType = state.workoutType.trim();
    final workoutDuration = int.parse(state.workoutDuration);
    final comment = state.comment.trim();
    final recordId = state.recordId;

    final Result<Object?> result = recordId != null
        ? await _updateRecordUseCase(
      recordId: recordId,
      workoutType: workoutType,
      workoutDuration: workoutDuration,
      image: state.image,
      comment: comment,
    )
        : await _createRecordUseCase(
      groupId: state.groupId,
      workoutType: workoutType,
      workoutDuration: workoutDuration,
      imagePath: switch (state.image) {
        NewRecordImage(:final path) => path,
        _ => null,
      },
      comment: comment,
    );

    switch (result) {
      case Ok():
        emit(state.copyWith(submitStatus: RecordSubmitStatus.success));
      case Error(:final error):
        emit(state.copyWith(
          submitStatus: RecordSubmitStatus.failure,
          errorMessage: () => _failureMessage(error),
        ));
    }
  }

  String _failureMessage(Exception error) => switch (error) {
    AlreadyWroteTodayException() => '오늘 기록은 이미 작성했어요',
    RecordEditExpiredException() => '오늘 작성한 기록만 수정할 수 있어요',
    NetworkUnavailableException() => '네트워크 연결을 확인해주세요',
    _ => state.isEditMode ? '기록 수정에 실패했어요' : '기록 저장에 실패했어요',
  };
}