import 'enums.dart';

class AppSettings {
  const AppSettings({
    required this.defaultRingtone,
    required this.vibrationEnabled,
    required this.repeatInterval,
    required this.missedDoseWindowMinutes,
    required this.languageCode,
  });

  final ReminderRingtone defaultRingtone;
  final bool vibrationEnabled;
  final RepeatInterval repeatInterval;
  final int missedDoseWindowMinutes;
  final String languageCode;

  static const defaults = AppSettings(
    defaultRingtone: ReminderRingtone.classicAlarm,
    vibrationEnabled: true,
    repeatInterval: RepeatInterval.tenMinutes,
    missedDoseWindowMinutes: 120,
    languageCode: 'ar',
  );

  AppSettings copyWith({
    ReminderRingtone? defaultRingtone,
    bool? vibrationEnabled,
    RepeatInterval? repeatInterval,
    int? missedDoseWindowMinutes,
    String? languageCode,
  }) {
    return AppSettings(
      defaultRingtone: defaultRingtone ?? this.defaultRingtone,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      missedDoseWindowMinutes:
          missedDoseWindowMinutes ?? this.missedDoseWindowMinutes,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
