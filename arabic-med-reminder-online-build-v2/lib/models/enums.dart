enum MedicationForm {
  tablet,
  capsule,
  syrup,
  drops,
  injection,
  other,
}

enum FoodRelation {
  beforeFood,
  afterFood,
  withFood,
  none,
}

enum DoseStatus {
  pending,
  taken,
  missed,
  skipped,
  snoozed,
}

enum RepeatInterval {
  once,
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
}

enum ReminderRingtone {
  classicAlarm,
  softBell,
  digitalBeep,
  calmReminder,
  strongAlert,
}

extension MedicationFormLabel on MedicationForm {
  String get arLabel => switch (this) {
        MedicationForm.tablet => 'قرص',
        MedicationForm.capsule => 'كبسولة',
        MedicationForm.syrup => 'شراب',
        MedicationForm.drops => 'نقط',
        MedicationForm.injection => 'حقنة',
        MedicationForm.other => 'أخرى',
      };
}

extension FoodRelationLabel on FoodRelation {
  String get arLabel => switch (this) {
        FoodRelation.beforeFood => 'قبل الأكل',
        FoodRelation.afterFood => 'بعد الأكل',
        FoodRelation.withFood => 'مع الأكل',
        FoodRelation.none => 'لا علاقة بالطعام',
      };
}

extension DoseStatusLabel on DoseStatus {
  String get arLabel => switch (this) {
        DoseStatus.pending => 'معلقة',
        DoseStatus.taken => 'تم أخذها',
        DoseStatus.missed => 'فائتة',
        DoseStatus.skipped => 'تم تخطيها',
        DoseStatus.snoozed => 'مؤجلة',
      };
}

extension RepeatIntervalMinutes on RepeatInterval {
  int get minutes => switch (this) {
        RepeatInterval.once => 0,
        RepeatInterval.fiveMinutes => 5,
        RepeatInterval.tenMinutes => 10,
        RepeatInterval.fifteenMinutes => 15,
      };

  String get arLabel => switch (this) {
        RepeatInterval.once => 'مرة واحدة',
        RepeatInterval.fiveMinutes => 'كل 5 دقائق',
        RepeatInterval.tenMinutes => 'كل 10 دقائق',
        RepeatInterval.fifteenMinutes => 'كل 15 دقيقة',
      };
}

extension ReminderRingtoneInfo on ReminderRingtone {
  String get arLabel => switch (this) {
        ReminderRingtone.classicAlarm => 'منبه كلاسيكي',
        ReminderRingtone.softBell => 'جرس هادئ',
        ReminderRingtone.digitalBeep => 'صفارة رقمية',
        ReminderRingtone.calmReminder => 'تذكير لطيف',
        ReminderRingtone.strongAlert => 'تنبيه قوي',
      };

  String get assetName => switch (this) {
        ReminderRingtone.classicAlarm => 'classic_alarm.wav',
        ReminderRingtone.softBell => 'soft_bell.wav',
        ReminderRingtone.digitalBeep => 'digital_beep.wav',
        ReminderRingtone.calmReminder => 'calm_reminder.wav',
        ReminderRingtone.strongAlert => 'strong_alert.wav',
      };

  String get rawResourceName => assetName.replaceAll('.wav', '');
}

T enumByNameOrDefault<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
