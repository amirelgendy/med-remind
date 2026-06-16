import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import '../models/app_settings.dart';
import '../models/dose_event.dart';
import '../models/enums.dart';
import '../repositories/medication_repository.dart';

const _actionTaken = 'dose_taken';
const _actionSnooze10 = 'dose_snooze_10';
const _actionSkip = 'dose_skip';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  unawaited(NotificationService.handleNotificationAction(response));
}

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final StreamController<int> _alarmTapController =
      StreamController<int>.broadcast();
  int? _initialAlarmEventId;

  static AppDatabase? _database;

  Stream<int> get alarmTaps => _alarmTapController.stream;

  int? takeInitialAlarmEventId() {
    final eventId = _initialAlarmEventId;
    _initialAlarmEventId = null;
    return eventId;
  }

  Future<void> initialize(AppDatabase database) async {
    _database = database;
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _initialAlarmEventId = _eventIdFromPayload(response?.payload);
    }
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    final eventId = _eventIdFromPayload(response.payload);
    if (eventId != null &&
        (response.actionId == null || response.actionId!.isEmpty)) {
      _alarmTapController.add(eventId);
      return;
    }
    await handleNotificationAction(response);
  }

  Future<bool> requestPermissions() async {
    final notificationStatus = await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();
    final granted = notificationStatus.isGranted || notificationStatus.isLimited;
    if (!granted) {
      await openAppSettings();
    }
    return granted;
  }

  Future<void> scheduleDoseReminder(
    DoseWithMedication item,
    AppSettings settings,
  ) async {
    final event = item.event;
    if (event.id == null ||
        event.status == DoseStatus.taken ||
        event.status == DoseStatus.skipped ||
        event.status == DoseStatus.missed) {
      return;
    }

    final triggerAt = event.snoozedUntil ?? event.scheduledAt;
    if (triggerAt.isBefore(DateTime.now())) return;

    await cancelDose(event.id!);
    await _scheduleSingleNotification(
      notificationId: _notificationId(event.id!, 0),
      item: item,
      settings: settings,
      triggerAt: triggerAt,
    );

    final repeatMinutes = settings.repeatInterval.minutes;
    if (repeatMinutes == 0) return;

    final maxRepeats =
        (settings.missedDoseWindowMinutes ~/ repeatMinutes).clamp(0, 3);
    for (var index = 1; index <= maxRepeats; index++) {
      await _scheduleSingleNotification(
        notificationId: _notificationId(event.id!, index),
        item: item,
        settings: settings,
        triggerAt: triggerAt.add(Duration(minutes: repeatMinutes * index)),
      );
    }
  }

  Future<void> _scheduleSingleNotification({
    required int notificationId,
    required DoseWithMedication item,
    required AppSettings settings,
    required DateTime triggerAt,
  }) async {
    final event = item.event;
    final ringtone = item.medication.ringtone ?? settings.defaultRingtone;
    final channelId =
        'med_alarm_${ringtone.rawResourceName}_${settings.vibrationEnabled}';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'تذكير الدواء',
      channelDescription: 'تنبيهات قوية لمواعيد الأدوية',
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(ringtone.rawResourceName),
      enableVibration: settings.vibrationEnabled,
      ongoing: true,
      autoCancel: false,
      actions: const [
        AndroidNotificationAction(
          _actionTaken,
          'أخذت الجرعة',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          _actionSnooze10,
          'تأجيل 10 دقائق',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          _actionSkip,
          'تخطي',
          showsUserInterface: true,
        ),
      ],
    );

    await _plugin.zonedSchedule(
      notificationId,
      'حان موعد الدواء',
      '${item.medication.name} - ${item.medication.doseAmount} ${item.medication.doseUnit}',
      tz.TZDateTime.from(triggerAt, tz.local),
      NotificationDetails(android: androidDetails),
      payload: 'event:${event.id}',
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleUpcoming(
    List<DoseWithMedication> items,
    AppSettings settings,
  ) async {
    for (final item in items.take(30)) {
      await scheduleDoseReminder(item, settings);
    }
  }

  Future<void> cancelDose(int eventId) async {
    for (var index = 0; index <= 48; index++) {
      await _plugin.cancel(_notificationId(eventId, index));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> handleNotificationAction(
    NotificationResponse response,
  ) async {
    final eventId = _eventIdFromPayload(response.payload);
    final database = _database ?? await AppDatabase.open();
    if (eventId == null) return;

    final repository = MedicationRepository(database);
    switch (response.actionId) {
      case _actionTaken:
        await repository.markTaken(eventId);
        await _cancelDoseNotifications(eventId);
        break;
      case _actionSnooze10:
        await _cancelDoseNotifications(eventId);
        await repository.snooze(eventId, const Duration(minutes: 10));
        final item = await database.getDoseWithMedication(eventId);
        final settings = await database.getSettings();
        if (item != null) {
          final service = NotificationService();
          await service.initialize(database);
          await service.scheduleDoseReminder(item, settings);
        }
        break;
      case _actionSkip:
        await repository.skip(eventId);
        await _cancelDoseNotifications(eventId);
        break;
      default:
        break;
    }
  }

  static Future<void> _cancelDoseNotifications(int eventId) async {
    final plugin = FlutterLocalNotificationsPlugin();
    for (var index = 0; index <= 48; index++) {
      await plugin.cancel(_notificationId(eventId, index));
    }
  }

  static int _notificationId(int eventId, int repeatIndex) {
    if (repeatIndex == 0) return eventId;
    return 100000000 + (eventId * 100) + repeatIndex;
  }

  static int? _eventIdFromPayload(String? payload) {
    if (payload == null || !payload.startsWith('event:')) return null;
    return int.tryParse(payload.substring('event:'.length));
  }
}
