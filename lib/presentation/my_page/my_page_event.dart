import '../../domain/entity/home_layout.dart';
import '../../domain/entity/reauth_method.dart';

sealed class MyPageEvent {
  const MyPageEvent();
}

/// 프로필, 로그인 방식 불러오기
final class MyPageStarted extends MyPageEvent {
  const MyPageStarted();
}

final class MyPageLayoutSubscriptionRequested extends MyPageEvent {
  const MyPageLayoutSubscriptionRequested();
}

final class MyPageHomeLayoutChanged extends MyPageEvent {
  const MyPageHomeLayoutChanged(this.layout);

  final HomeLayout layout;
}

final class MyPageLogoutRequested extends MyPageEvent {
  const MyPageLogoutRequested();
}

/// 본인 확인 방법을 담아 계정 삭제 요청 (네이티브는 Activity를 담았음)
final class MyPageDeleteRequested extends MyPageEvent {
  const MyPageDeleteRequested(this.method);

  final ReauthMethod method;
}