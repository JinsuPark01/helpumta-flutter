sealed class HomeEvent {
  const HomeEvent();
}

/// 그룹 목록 불러오기 (최초 진입 + 다른 화면에서 복귀 시)
final class HomeGroupsRequested extends HomeEvent {
  const HomeGroupsRequested();
}