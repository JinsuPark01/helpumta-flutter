sealed class HomeEvent {
  const HomeEvent();
}

/// 홈 배치 설정 구독 시작 (마이페이지에서 바꾸면 자동 반영)
final class HomeLayoutSubscriptionRequested extends HomeEvent {
  const HomeLayoutSubscriptionRequested();
}

/// 그룹 목록 불러오기 (최초 진입 + 다른 화면에서 복귀 시)
final class HomeGroupsRequested extends HomeEvent {
  const HomeGroupsRequested();
}