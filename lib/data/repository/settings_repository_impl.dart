import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entity/home_layout.dart';
import '../../domain/repository/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _homeLayoutKey = 'home_layout';

  /// shared_preferences는 변경 알림이 없어서(DataStore Flow와 다름)
  /// 이 Repository를 거친 변경을 직접 알린다
  final _homeLayoutChanges = StreamController<HomeLayout>.broadcast();

  @override
  Stream<HomeLayout> watchHomeLayout() async* {
    yield await _readHomeLayout();
    yield* _homeLayoutChanges.stream;
  }

  @override
  Future<void> setHomeLayout(HomeLayout layout) async {
    try {
      await _prefs.setString(_homeLayoutKey, layout.name);
      _homeLayoutChanges.add(layout);
    } on Exception {
      // 저장 실패 시 알리지 않음 (설정값은 기존 값 유지)
    }
  }

  /// 저장값이 없거나 깨졌으면 기본값(그리드)
  Future<HomeLayout> _readHomeLayout() async {
    try {
      final saved = await _prefs.getString(_homeLayoutKey);
      return HomeLayout.values.asNameMap()[saved] ?? HomeLayout.grid;
    } on Exception {
      return HomeLayout.grid;
    }
  }
}