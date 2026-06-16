import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_settings.dart';
import '../models/dose_event.dart';
import '../models/dose_schedule.dart';
import '../models/enums.dart';
import '../models/medication.dart';
import '../utils/date_utils.dart';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static Future<AppDatabase> open() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'arabic_med_reminder.db');
    final database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE medications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            strength TEXT,
            form TEXT NOT NULL,
            dose_amount TEXT NOT NULL,
            dose_unit TEXT NOT NULL,
            doses_per_day INTEGER NOT NULL,
            start_date TEXT NOT NULL,
            end_date TEXT NOT NULL,
            food_relation TEXT NOT NULL,
            notes TEXT,
            color_value INTEGER NOT NULL,
            icon_code_point INTEGER,
            ringtone TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE dose_schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            time_of_day TEXT NOT NULL,
            FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE dose_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medication_id INTEGER NOT NULL,
            scheduled_at TEXT NOT NULL,
            status TEXT NOT NULL,
            taken_at TEXT,
            snoozed_until TEXT,
            notes TEXT,
            FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE ringtone_settings (
            medication_id INTEGER PRIMARY KEY,
            ringtone TEXT NOT NULL,
            FOREIGN KEY (medication_id) REFERENCES medications(id) ON DELETE CASCADE
          )
        ''');
        await _insertDefaultSettings(db);
      },
    );
    return AppDatabase._(database);
  }

  static Future<void> _insertDefaultSettings(Database db) async {
    final settings = AppSettings.defaults;
    await db.insert('app_settings', {
      'key': 'default_ringtone',
      'value': settings.defaultRingtone.name,
    });
    await db.insert('app_settings', {
      'key': 'vibration_enabled',
      'value': settings.vibrationEnabled ? '1' : '0',
    });
    await db.insert('app_settings', {
      'key': 'repeat_interval',
      'value': settings.repeatInterval.name,
    });
    await db.insert('app_settings', {
      'key': 'missed_dose_window_minutes',
      'value': settings.missedDoseWindowMinutes.toString(),
    });
    await db.insert('app_settings', {
      'key': 'language_code',
      'value': settings.languageCode,
    });
  }

  Future<int> insertMedication(Medication medication) {
    return db.insert('medications', medication.toMap());
  }

  Future<void> insertDoseSchedules(List<DoseSchedule> schedules) async {
    final batch = db.batch();
    for (final schedule in schedules) {
      batch.insert('dose_schedules', schedule.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertDoseEvents(List<DoseEvent> events) async {
    final batch = db.batch();
    for (final event in events) {
      batch.insert('dose_events', event.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Medication>> getMedications() async {
    final rows = await db.query('medications', orderBy: 'name COLLATE NOCASE');
    return rows.map(Medication.fromMap).toList();
  }

  Future<Medication?> getMedication(int id) async {
    final rows = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : Medication.fromMap(rows.first);
  }

  Future<List<DoseEvent>> getDoseEventsForMedication(int medicationId) async {
    final rows = await db.query(
      'dose_events',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'scheduled_at ASC',
    );
    return rows.map(DoseEvent.fromMap).toList();
  }

  Future<List<DoseWithMedication>> getDoseEventsBetween(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await db.rawQuery('''
      SELECT
        e.id AS event_id,
        e.medication_id,
        e.scheduled_at,
        e.status,
        e.taken_at,
        e.snoozed_until,
        e.notes AS event_notes,
        m.*
      FROM dose_events e
      JOIN medications m ON m.id = e.medication_id
      WHERE e.scheduled_at BETWEEN ? AND ?
      ORDER BY e.scheduled_at ASC
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return rows.map(_doseWithMedicationFromJoinedRow).toList();
  }

  Future<List<DoseWithMedication>> getAllDoseEvents() async {
    final rows = await db.rawQuery('''
      SELECT
        e.id AS event_id,
        e.medication_id,
        e.scheduled_at,
        e.status,
        e.taken_at,
        e.snoozed_until,
        e.notes AS event_notes,
        m.*
      FROM dose_events e
      JOIN medications m ON m.id = e.medication_id
      ORDER BY e.scheduled_at DESC
    ''');
    return rows.map(_doseWithMedicationFromJoinedRow).toList();
  }

  Future<DoseWithMedication?> getDoseWithMedication(int eventId) async {
    final rows = await db.rawQuery('''
      SELECT
        e.id AS event_id,
        e.medication_id,
        e.scheduled_at,
        e.status,
        e.taken_at,
        e.snoozed_until,
        e.notes AS event_notes,
        m.*
      FROM dose_events e
      JOIN medications m ON m.id = e.medication_id
      WHERE e.id = ?
      LIMIT 1
    ''', [eventId]);
    return rows.isEmpty ? null : _doseWithMedicationFromJoinedRow(rows.first);
  }

  Future<void> updateDoseEvent(DoseEvent event) async {
    await db.update(
      'dose_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<void> updatePendingEventsToMissed(DateTime now, int windowMinutes) async {
    final cutoff = now.subtract(Duration(minutes: windowMinutes));
    await db.update(
      'dose_events',
      {'status': DoseStatus.missed.name},
      where: 'status IN (?, ?) AND scheduled_at < ?',
      whereArgs: [
        DoseStatus.pending.name,
        DoseStatus.snoozed.name,
        cutoff.toIso8601String(),
      ],
    );
  }

  Future<AppSettings> getSettings() async {
    final rows = await db.query('app_settings');
    final map = {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
    return AppSettings(
      defaultRingtone: enumByNameOrDefault(
        ReminderRingtone.values,
        map['default_ringtone'],
        AppSettings.defaults.defaultRingtone,
      ),
      vibrationEnabled: map['vibration_enabled'] != '0',
      repeatInterval: enumByNameOrDefault(
        RepeatInterval.values,
        map['repeat_interval'],
        AppSettings.defaults.repeatInterval,
      ),
      missedDoseWindowMinutes:
          int.tryParse(map['missed_dose_window_minutes'] ?? '') ??
              AppSettings.defaults.missedDoseWindowMinutes,
      languageCode: map['language_code'] ?? AppSettings.defaults.languageCode,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _upsertSetting('default_ringtone', settings.defaultRingtone.name);
    await _upsertSetting(
      'vibration_enabled',
      settings.vibrationEnabled ? '1' : '0',
    );
    await _upsertSetting('repeat_interval', settings.repeatInterval.name);
    await _upsertSetting(
      'missed_dose_window_minutes',
      settings.missedDoseWindowMinutes.toString(),
    );
    await _upsertSetting('language_code', settings.languageCode);
  }

  Future<void> _upsertSetting(String key, String value) {
    return db.insert(
      'app_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<DateTime, Map<DoseStatus, int>>> getCourseHistory() async {
    final events = await getAllDoseEvents();
    final result = <DateTime, Map<DoseStatus, int>>{};
    for (final item in events) {
      final day = dateOnly(item.event.scheduledAt);
      final counts = result.putIfAbsent(day, () => {});
      counts[item.event.status] = (counts[item.event.status] ?? 0) + 1;
    }
    return result;
  }

  DoseWithMedication _doseWithMedicationFromJoinedRow(
    Map<String, Object?> row,
  ) {
    final event = DoseEvent.fromMap({
      'id': row['event_id'],
      'medication_id': row['medication_id'],
      'scheduled_at': row['scheduled_at'],
      'status': row['status'],
      'taken_at': row['taken_at'],
      'snoozed_until': row['snoozed_until'],
      'notes': row['event_notes'],
    });
    return DoseWithMedication(
      event: event,
      medication: Medication.fromMap(row),
    );
  }
}
