import 'enums.dart';

class Medication {
  Medication({
    this.id,
    required this.name,
    required this.strength,
    required this.form,
    required this.doseAmount,
    required this.doseUnit,
    required this.dosesPerDay,
    required this.startDate,
    required this.endDate,
    required this.foodRelation,
    this.notes = '',
    required this.colorValue,
    this.iconCodePoint,
    this.ringtone,
    this.createdAt,
  });

  final int? id;
  final String name;
  final String strength;
  final MedicationForm form;
  final String doseAmount;
  final String doseUnit;
  final int dosesPerDay;
  final DateTime startDate;
  final DateTime endDate;
  final FoodRelation foodRelation;
  final String notes;
  final int colorValue;
  final int? iconCodePoint;
  final ReminderRingtone? ringtone;
  final DateTime? createdAt;

  Medication copyWith({
    int? id,
    String? name,
    String? strength,
    MedicationForm? form,
    String? doseAmount,
    String? doseUnit,
    int? dosesPerDay,
    DateTime? startDate,
    DateTime? endDate,
    FoodRelation? foodRelation,
    String? notes,
    int? colorValue,
    int? iconCodePoint,
    ReminderRingtone? ringtone,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      strength: strength ?? this.strength,
      form: form ?? this.form,
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      dosesPerDay: dosesPerDay ?? this.dosesPerDay,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      foodRelation: foodRelation ?? this.foodRelation,
      notes: notes ?? this.notes,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      ringtone: ringtone ?? this.ringtone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'strength': strength,
      'form': form.name,
      'dose_amount': doseAmount,
      'dose_unit': doseUnit,
      'doses_per_day': dosesPerDay,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'food_relation': foodRelation.name,
      'notes': notes,
      'color_value': colorValue,
      'icon_code_point': iconCodePoint,
      'ringtone': ringtone?.name,
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<String, Object?> map) {
    return Medication(
      id: map['id'] as int?,
      name: map['name'] as String,
      strength: map['strength'] as String? ?? '',
      form: enumByNameOrDefault(
        MedicationForm.values,
        map['form'] as String?,
        MedicationForm.tablet,
      ),
      doseAmount: map['dose_amount'] as String? ?? '',
      doseUnit: map['dose_unit'] as String? ?? '',
      dosesPerDay: map['doses_per_day'] as int? ?? 1,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      foodRelation: enumByNameOrDefault(
        FoodRelation.values,
        map['food_relation'] as String?,
        FoodRelation.none,
      ),
      notes: map['notes'] as String? ?? '',
      colorValue: map['color_value'] as int? ?? 0xFF1565C0,
      iconCodePoint: map['icon_code_point'] as int?,
      ringtone: (map['ringtone'] as String?) == null
          ? null
          : enumByNameOrDefault(
              ReminderRingtone.values,
              map['ringtone'] as String?,
              ReminderRingtone.classicAlarm,
            ),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
    );
  }
}
