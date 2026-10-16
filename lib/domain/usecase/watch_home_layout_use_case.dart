import '../entity/home_layout.dart';
import '../repository/settings_repository.dart';

class WatchHomeLayoutUseCase {
  const WatchHomeLayoutUseCase(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  Stream<HomeLayout> call() => _settingsRepository.watchHomeLayout();
}