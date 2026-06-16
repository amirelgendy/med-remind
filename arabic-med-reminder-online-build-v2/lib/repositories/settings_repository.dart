import '../database/app_database.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this.database);

  final AppDatabase database;

  Future<AppSettings> getSettings() => database.getSettings();

  Future<void> saveSettings(AppSettings settings) => database.saveSettings(settings);
}
