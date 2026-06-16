import 'enums.dart';
import 'medication.dart';

class DoseEvent {
  DoseEvent({
    this.id,
    required this.medicationId,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
    this.snoozedUntil,
    this.notes = '',
  });

  final int? id;
  final int medicationId;
  final DateTime scheduledAt;
  final DoseStatus status;
  final DateTime? takenAt;
  final DateTime? snoozedUntil;
  final String notes;

  DoseEvent copyWith({
    int? id,
    int? medicationId,
    DateTime? scheduledAt,
    DoseStatus? status,
    DateTime? takenAt,
    DateTime? snoozedUntil,
    String? notes,
    bool clearSnooze = false,
  }) {
    return DoseEvent(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      snoozedUntil: clearSnooze ? null : snoozedUntil ?? this.snoozedUntil,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'scheduled_at': scheduledAt.toIso8601String(),
      'status': status.name,
      'taken_at': takenAt?.toIso8601String(),
      'snoozed_until': snoozedUntil?.toIso8601String(),
      'notes': notes,
    };
  }

  factory DoseEvent.fromMap(Map<String, Object?> map) {
    return DoseEvent(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      scheduledAt: DateTime.parse(map['scheduled_at'] as String),
      status: enumByNameOrDefault(
        DoseStatus.values,
        map['status'] as String?,
        DoseStatus.pending,
      ),
      takenAt: DateTime.tryParse(map['taken_at'] as String? ?? ''),
      snoozedUntil: DateTime.tryParse(map['snoozed_until'] as String? ?? ''),
      notes: map['notes'] as String? ?? '',
    );
  }
}

class DoseWithMedication {
  DoseWithMedication({
    required this.event,
    required this.medication,
  });

  final DoseEvent event;
  final Medication medication;
}
