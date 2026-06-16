class DoseSchedule {
  DoseSchedule({
    this.id,
    required this.medicationId,
    required this.timeOfDay,
  });

  final int? id;
  final int medicationId;
  final String timeOfDay;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'time_of_day': timeOfDay,
    };
  }

  factory DoseSchedule.fromMap(Map<String, Object?> map) {
    return DoseSchedule(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      timeOfDay: map['time_of_day'] as String,
    );
  }
}
