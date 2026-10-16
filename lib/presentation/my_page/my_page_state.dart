import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entity/auth_provider.dart';
import '../../domain/entity/home_layout.dart';
import '../../domain/entity/user_profile.dart';

enum MyPageDeleteStatus { idle, inProgress, failure }

class MyPageState extends Equatable {
  const MyPageState({
    this.profile,
    this.authProvider = AuthProvider.unknown,
    this.homeLayout = HomeLayout.grid,
    this.deleteStatus = MyPageDeleteStatus.idle,
    this.errorMessage,
    this.isSignedOut = false,
  });

  final UserProfile? profile;
  final AuthProvider authProvider;
  final HomeLayout homeLayout;
  final MyPageDeleteStatus deleteStatus;

  /// 계정 삭제 실패 시 스낵바 문구
  final String? errorMessage;

  /// 로그아웃·계정 삭제 완료 → 로그인 화면으로 (화면을 떠나므로 플래그로 충분)
  final bool isSignedOut;

  bool get isDeleting => deleteStatus == MyPageDeleteStatus.inProgress;

  MyPageState copyWith({
    UserProfile? profile,
    AuthProvider? authProvider,
    HomeLayout? homeLayout,
    MyPageDeleteStatus? deleteStatus,
    ValueGetter<String?>? errorMessage,
    bool? isSignedOut,
  }) {
    return MyPageState(
      profile: profile ?? this.profile,
      authProvider: authProvider ?? this.authProvider,
      homeLayout: homeLayout ?? this.homeLayout,
      deleteStatus: deleteStatus ?? this.deleteStatus,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isSignedOut: isSignedOut ?? this.isSignedOut,
    );
  }

  @override
  List<Object?> get props => [
    profile,
    authProvider,
    homeLayout,
    deleteStatus,
    errorMessage,
    isSignedOut,
  ];
}