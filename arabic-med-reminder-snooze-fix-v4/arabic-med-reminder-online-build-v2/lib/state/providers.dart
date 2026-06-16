import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/app_settings.dart';
import '../models/dose_event.dart';
import '../models/medication.dart';
import '../repositories/medication_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/export_service.dart';
import '../services/notification_service.dart';
import '../utils/date_utils.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('notificationServiceProvider must be overridden');
});

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository(ref.watch(databaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

final refreshProvider = StateProvider<int>((ref) => 0);

void refreshApp(WidgetRef ref) {
  ref.read(refreshProvider.notifier).state++;
}

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(settingsRepositoryProvider).getSettings();
});

final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(medicationRepositoryProvider).getMedications();
});

final todayDosesProvider = FutureProvider<List<DoseWithMedication>>((ref) async {
  ref.watch(refreshProvider);
  final settings = await ref.watch(settingsProvider.future);
  return ref.watch(medicationRepositoryProvider).getTodayDoses(settings);
});

final allDosesProvider = FutureProvider<List<DoseWithMedication>>((ref) async {
  ref.watch(refreshProvider);
  return ref.watch(medicationRepositoryProvider).getAllDoseEvents();
});

final medicationDetailsProvider =
    FutureProvider.family<MedicationDetails, int>((ref, medicationId) async {
  ref.watch(refreshProvider);
  final repository = ref.watch(medicationRepositoryProvider);
  final medication = await repository.getMedication(medicationId);
  final events = await repository.getMedicationEvents(medicationId);
  if (medication == null) {
    throw StateError('Medication not found');
  }
  return MedicationDetails(medication: medication, events: events);
});

final courseHistoryProvider =
    FutureProvider<Map<DateTime, DayDoseCounts>>((ref) async {
  final List<DoseWithMedication> items;
  try {
    items = await ref.watch(allDosesProvider.future);
  } catch (_) {
    return <DateTime, DayDoseCounts>{};
  }
  final result = <DateTime, DayDoseCounts>{};
  for (final item in items) {
    try {
      final day = dateOnly(item.event.scheduledAt);
      final counts = result.putIfAbsent(day, DayDoseCounts.new);
      counts.add(item.event.status);
    } catch (_) {
      continue;
    }
  }
  return result;
});

class MedicationDetails {
  MedicationDetails({
    required this.medication,
    required this.events,
  });

  final Medication medication;
  final List<DoseEvent> events;

  int get total => events.length;
  int get taken => events.where((e) => e.status.name == 'taken').length;
  int get missed => events.where((e) => e.status.name == 'missed').length;
  int get skipped => events.where((e) => e.status.name == 'skipped').length;
  int get actionableTotal => total == 0 ? 1 : total;
  double get adherence => taken / actionableTotal;
}

class DayDoseCounts {
  int taken = 0;
  int missed = 0;
  int skipped = 0;
  int pending = 0;

  void add(status) {
    switch (status.name) {
      case 'taken':
        taken++;
        break;
      case 'missed':
        missed++;
        break;
      case 'skipped':
        skipped++;
        break;
      default:
        pending++;
        break;
    }
  }
}
