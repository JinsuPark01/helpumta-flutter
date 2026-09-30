import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/entity/network_exception.dart';
import '../../domain/usecase/create_group_use_case.dart';
import 'group_create_event.dart';
import 'group_create_state.dart';

class GroupCreateBloc extends Bloc<GroupCreateEvent, GroupCreateState> {
  GroupCreateBloc({required CreateGroupUseCase createGroupUseCase})
      : _createGroupUseCase = createGroupUseCase,
        super(const GroupCreateState()) {
    on<GroupCreateNameChanged>(
          (event, emit) => emit(state.copyWith(name: event.name)),
    );
    on<GroupCreateDescriptionChanged>(
          (event, emit) => emit(state.copyWith(description: event.description)),
    );
    on<GroupCreateImagePicked>(
          (event, emit) => emit(state.copyWith(imagePath: () => event.imagePath)),
    );
    on<GroupCreateSubmitted>(_onSubmitted);
  }

  final CreateGroupUseCase _createGroupUseCase;

  Future<void> _onSubmitted(
      GroupCreateSubmitted event,
      Emitter<GroupCreateState> emit,
      ) async {
    if (state.isLoading || !state.isCreateEnabled) return;

    emit(state.copyWith(
      status: GroupCreateStatus.loading,
      errorMessage: () => null,
    ));

    final result = await _createGroupUseCase(
      name: state.name.trim(),
      description: state.description.trim(),
      imagePath: state.imagePath,
    );

    switch (result) {
      case Ok(value: final groupId):
        emit(state.copyWith(
          status: GroupCreateStatus.success,
          createdGroupId: () => groupId,
        ));
      case Error(error: NetworkUnavailableException()):
        emit(state.copyWith(
          status: GroupCreateStatus.failure,
          errorMessage: () => '네트워크 연결을 확인해주세요',
        ));
      case Error():
        emit(state.copyWith(
          status: GroupCreateStatus.failure,
          errorMessage: () => '그룹 생성에 실패했어요',
        ));
    }
  }
}