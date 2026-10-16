import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/entity/home_layout.dart';
import '../../domain/usecase/get_groups_use_case.dart';
import '../../domain/usecase/watch_home_layout_use_case.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetGroupsUseCase getGroupsUseCase,
    required WatchHomeLayoutUseCase watchHomeLayoutUseCase,
  })  : _getGroupsUseCase = getGroupsUseCase,
        _watchHomeLayoutUseCase = watchHomeLayoutUseCase,
        super(const HomeState()) {
    on<HomeLayoutSubscriptionRequested>(_onLayoutSubscriptionRequested);
    on<HomeGroupsRequested>(_onGroupsRequested);
  }

  final GetGroupsUseCase _getGroupsUseCase;
  final WatchHomeLayoutUseCase _watchHomeLayoutUseCase;

  /// 네이티브 viewModelScope.launch { flow.collect { } } 대응.
  /// Bloc이 닫히면 구독도 자동 해제
  Future<void> _onLayoutSubscriptionRequested(
      HomeLayoutSubscriptionRequested event,
      Emitter<HomeState> emit,
      ) {
    return emit.forEach<HomeLayout>(
      _watchHomeLayoutUseCase(),
      onData: (layout) => state.copyWith(homeLayout: layout),
    );
  }

  Future<void> _onGroupsRequested(
      HomeGroupsRequested event,
      Emitter<HomeState> emit,
      ) async {
    if (state.isLoading) return;

    // 기존 목록은 유지한 채 로딩 → 새로고침 중에도 목록이 사라지지 않음
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