import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/result.dart';
import '../../domain/entity/account_exception.dart';
import '../../domain/entity/auth_error.dart';
import '../../domain/entity/home_layout.dart';
import '../../domain/entity/network_exception.dart';
import '../../domain/entity/reauth_method.dart';
import '../../domain/usecase/delete_account_use_case.dart';
import '../../domain/usecase/get_auth_provider_use_case.dart';
import '../../domain/usecase/get_user_profile_use_case.dart';
import '../../domain/usecase/logout_use_case.dart';
import '../../domain/usecase/set_home_layout_use_case.dart';
import '../../domain/usecase/watch_home_layout_use_case.dart';
import 'my_page_event.dart';
import 'my_page_state.dart';

class MyPageBloc extends Bloc<MyPageEvent, MyPageState> {
  MyPageBloc({
    required GetUserProfileUseCase getUserProfileUseCase,
    required GetAuthProviderUseCase getAuthProviderUseCase,
    required LogoutUseCase logoutUseCase,
    required DeleteAccountUseCase deleteAccountUseCase,
    required WatchHomeLayoutUseCase watchHomeLayoutUseCase,
    required SetHomeLayoutUseCase setHomeLayoutUseCase,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        _getAuthProviderUseCase = getAuthProviderUseCase,
        _logoutUseCase = logoutUseCase,
        _deleteAccountUseCase = deleteAccountUseCase,
        _watchHomeLayoutUseCase = watchHomeLayoutUseCase,
        _setHomeLayoutUseCase = setHomeLayoutUseCase,
        super(const MyPageState()) {
    on<MyPageStarted>(_onStarted);
    on<MyPageLayoutSubscriptionRequested>(_onLayoutSubscriptionRequested);
    on<MyPageHomeLayoutChanged>(
          (event, emit) => _setHomeLayoutUseCase(event.layout),
    );
    on<MyPageLogoutRequested>(_onLogoutRequested, transformer: droppable());
    // 삭제 중 중복 요청 무시 (네이티브 isDeleting 가드)
    on<MyPageDeleteRequested>(_onDeleteRequested, transformer: droppable());
  }

  final GetUserProfileUseCase _getUserProfileUseCase;
  final GetAuthProviderUseCase _getAuthProviderUseCase;
  final LogoutUseCase _logoutUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;
  final WatchHomeLayoutUseCase _watchHomeLayoutUseCase;
  final SetHomeLayoutUseCase _setHomeLayoutUseCase;

  void _onStarted(MyPageStarted event, Emitter<MyPageState> emit) {
    final profile = _getUserProfileUseCase();
    if (profile == null) return;
    emit(state.copyWith(
      profile: profile,
      authProvider: _getAuthProviderUseCase(),
    ));
  }

  Future<void> _onLayoutSubscriptionRequested(
      MyPageLayoutSubscriptionRequested event,
      Emitter<MyPageState> emit,
      ) {
    return emit.forEach<HomeLayout>(
      _watchHomeLayoutUseCase(),
      onData: (layout) => state.copyWith(homeLayout: layout),
    );
  }

  Future<void> _onLogoutRequested(
      MyPageLogoutRequested event,
      Emitter<MyPageState> emit,
      ) async {
    await _logoutUseCase();
    emit(state.copyWith(isSignedOut: true));
  }

  Future<void> _onDeleteRequested(
      MyPageDeleteRequested event,
      Emitter<MyPageState> emit,
      ) async {
    emit(state.copyWith(
      deleteStatus: MyPageDeleteStatus.inProgress,
      errorMessage: () => null,
    ));

    final result = await _deleteAccountUseCase(event.method);

    switch (result) {
      case Ok():
        emit(state.copyWith(
          deleteStatus: MyPageDeleteStatus.idle,
          isSignedOut: true,
        ));

    // 구글 계정 선택 취소: 문구 없이 원래 상태로
      case Error(error: AuthException(error: AuthError.googleSignInCancelled)):
        emit(state.copyWith(deleteStatus: MyPageDeleteStatus.idle));

    // 본인 확인이 네트워크 때문에 실패 → 비밀번호 탓으로 안내하지 않음
      case Error(
      error: ReauthenticationFailedException(
      cause: AuthException(error: AuthError.network)
      )
      ):
        _emitFailure(emit, '네트워크 연결을 확인해주세요');

      case Error(error: ReauthenticationFailedException()):
        _emitFailure(
          emit,
          event.method is PasswordReauth
              ? '본인 확인에 실패했어요. 비밀번호를 확인해주세요.'
              : '구글 인증에 실패했어요. 다시 시도해주세요.',
        );

      case Error(error: NetworkUnavailableException()):
        _emitFailure(emit, '네트워크 연결을 확인해주세요');

      case Error():
        _emitFailure(emit, '계정 삭제에 실패했어요. 다시 시도해주세요.');
    }
  }

  void _emitFailure(Emitter<MyPageState> emit, String message) {
    emit(state.copyWith(
      deleteStatus: MyPageDeleteStatus.failure,
      errorMessage: () => message,
    ));
  }
}