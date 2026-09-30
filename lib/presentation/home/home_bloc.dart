import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/usecase/get_groups_use_case.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({required GetGroupsUseCase getGroupsUseCase})
      : _getGroupsUseCase = getGroupsUseCase,
        super(const HomeState()) {
    on<HomeGroupsRequested>(_onGroupsRequested);
  }

  final GetGroupsUseCase _getGroupsUseCase;

  Future<void> _onGroupsRequested(
      HomeGroupsRequested event,
      Emitter<HomeState> emit,
      ) async {
    if (state.isLoading) return;

    // 기존 목록은 유지한 채 로딩 → 새로고침 중에도 그리드가 사라지지 않음
    emit(state.copyWith(status: HomeStatus.loading));

    final result = await _getGroupsUseCase();

    switch (result) {
      case Ok(value: final groups):
        emit(state.copyWith(
          status: HomeStatus.success,
          groups: groups,
          errorMessage: () => null, // 이전 실패 문구 제거
        ));
      case Error():
        emit(state.copyWith(
          status: HomeStatus.failure,
          errorMessage: () => '그룹을 불러올 수 없습니다',
        ));
    }
  }
}