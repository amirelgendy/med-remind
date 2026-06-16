import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../services/alarm_player_service.dart';
import '../state/providers.dart';
import '../utils/date_utils.dart';

class AlarmScreen extends ConsumerStatefulWidget {
  const AlarmScreen({super.key, required this.eventId});

  final int eventId;

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  final _player = AlarmPlayerService();
  bool _started = false;

  @override
  void dispose() {
    _player.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F3D36),
      body: SafeArea(
        child: FutureBuilder(
          future: ref.read(databaseProvider).getDoseWithMedication(widget.eventId),
          builder: (context, snapshot) {
            final item = snapshot.data;
            if (!snapshot.hasData || item == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            settingsAsync.whenData((settings) {
              if (!_started) {
                _started = true;
                _player.start(
                  ringtone: item.medication.ringtone ?? settings.defaultRingtone,
                  vibrate: settings.vibrationEnabled,
                );
              }
            });

            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  const Icon(
                    Icons.alarm,
                    color: Colors.white,
                    size: 76,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'حان موعد الدواء',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    item.medication.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.medication.doseAmount} ${item.medication.doseUnit}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${item.medication.foodRelation.arLabel} • ${formatArabicTime(item.event.scheduledAt)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 19),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F3D36),
                      minimumSize: const Size.fromHeight(58),
                    ),
                    onPressed: () => _markTaken(context),
                    icon: const Icon(Icons.check),
                    label: const Text('أخذت الجرعة'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      minimumSize: const Size.fromHeight(56),
                    ),
                    onPressed: () => _snooze(context),
                    icon: const Icon(Icons.snooze),
                    label: const Text('تأجيل 10 دقائق'),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                    ),
                    onPressed: () => _skip(context),
                    icon: const Icon(Icons.close),
                    label: const Text('تخطي الجرعة'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _markTaken(BuildContext context) async {
    await _player.stop();
    await ref.read(medicationRepositoryProvider).markTaken(widget.eventId);
    await ref.read(notificationServiceProvider).cancelDose(widget.eventId);
    refreshApp(ref);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _skip(BuildContext context) async {
    await _player.stop();
    await ref.read(medicationRepositoryProvider).skip(widget.eventId);
    await ref.read(notificationServiceProvider).cancelDose(widget.eventId);
    refreshApp(ref);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _snooze(BuildContext context) async {
    await _player.stop();
    await ref.read(notificationServiceProvider).cancelDose(widget.eventId);
    await ref
        .read(medicationRepositoryProvider)
        .snooze(widget.eventId, const Duration(minutes: 10));
    final item = await ref.read(databaseProvider).getDoseWithMedication(widget.eventId);
    final settings = await ref.read(settingsProvider.future);
    if (item != null) {
      await ref.read(notificationServiceProvider).scheduleDoseReminder(item, settings);
    }
    refreshApp(ref);
    if (context.mounted) Navigator.pop(context);
  }
}
