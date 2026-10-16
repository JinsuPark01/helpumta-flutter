import '../entity/home_layout.dart';

abstract interface class SettingsRepository {
  /// 현재 값을 먼저 내보내고, 이후 바뀔 때마다 새 값을 내보냄
  Stream<HomeLayout> watchHomeLayout();

  Future<void> setHomeLayout(HomeLayout layout);
}