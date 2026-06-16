import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../models/app_settings.dart';
import '../models/dose_event.dart';
import '../models/dose_schedule.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../utils/date_utils.dart';

class MedicationRepository {
  MedicationRepository(this.database);

  final AppDatabase database;

  Future<void> addMedication({
    required Medication medication,
    required List<TimeOfDay> doseTimes,
  }) async {
    final medicationId = await database.insertMedication(medication);
    final sortedTimes = [...doseTimes]
      ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));

    await database.insertDoseSchedules(
      sortedTimes
          .map(
            (time) => DoseSchedule(
              medicationId: medicationId,
              timeOfDay: timeOfDayToStorage(time),
            ),
          )
          .toList(),
    );

    final events = <DoseEvent>[];
    for (final day in eachDayInclusive(medication.startDate, medication.endDate)) {
      for (final time in sortedTimes) {
        events.add(
          DoseEvent(
            medicationId: medicationId,
            scheduledAt: combineDateAndTime(day, time),
            status: DoseStatus.pending,
          ),
        );
      }
    }
    await database.insertDoseEvents(events);
  }

  Future<List<Medication>> getMedications() => database.getMedications();

  Future<List<DoseWithMedication>> getTodayDoses(AppSettings settings) async {
    await database.updatePendingEventsToMissed(
      DateTime.now(),
      settings.missedDoseWindowMinutes,
    );
    final today = DateTime.now();
    return database.getDoseEventsBetween(dateOnly(today), endOfDay(today));
  }

  Future<List<DoseWithMedication>> getAllDoseEvents() =>
      database.getAllDoseEvents();

  Future<List<DoseEvent>> getMedicationEvents(int medicationId) =>
      database.getDoseEventsForMedication(medicationId);

  Future<Medication?> getMedication(int id) => database.getMedication(id);

  Future<void> markTaken(int eventId) async {
    final item = await database.getDoseWithMedication(eventId);
    if (item == null) return;
    await database.updateDoseEvent(
      item.event.copyWith(
        status: DoseStatus.taken,
        takenAt: DateTime.now(),
        clearSnooze: true,
      ),
    );
  }

  Future<void> skip(int eventId) async {
    final item = await database.getDoseWithMedication(eventId);
    if (item == null) return;
    await database.updateDoseEvent(
      item.event.copyWith(status: DoseStatus.skipped, clearSnooze: true),
    );
  }

  Future<void> snooze(int eventId, Duration duration) async {
    final item = await database.getDoseWithMedication(eventId);
    if (item == null) return;
    await database.updateDoseEvent(
      item.event.copyWith(
        status: DoseStatus.snoozed,
        snoozedUntil: DateTime.now().add(duration),
      ),
    );
  }
}
