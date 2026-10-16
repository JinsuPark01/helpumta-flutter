import '../entity/home_layout.dart';
import '../repository/settings_repository.dart';

class SetHomeLayoutUseCase {
  const SetHomeLayoutUseCase(this._settingsRepository);

  final SettingsRepository _settingsRepository;

  Future<void> call(HomeLayout layout) =>
      _settingsRepository.setHomeLayout(layout);
}