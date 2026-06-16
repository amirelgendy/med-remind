import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/enums.dart';
import '../state/providers.dart';
import '../widgets/empty_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          message: 'تعذر تحميل الإعدادات.',
          icon: Icons.error_outline,
        ),
        data: (value) => _SettingsForm(settings: value),
      ),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final AppSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late AppSettings _settings = widget.settings;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SafetyMessage(),
        DropdownButtonFormField<ReminderRingtone>(
          value: _settings.defaultRingtone,
          decoration: const InputDecoration(
            labelText: 'النغمة الافتراضية',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final ringtone in ReminderRingtone.values)
              DropdownMenuItem(
                value: ringtone,
                child: Text(ringtone.arLabel),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              _save(_settings.copyWith(defaultRingtone: value));
            }
          },
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _settings.vibrationEnabled,
          onChanged: (value) {
            _save(_settings.copyWith(vibrationEnabled: value));
          },
          title: const Text('الاهتزاز'),
          subtitle: const Text('تشغيل أو إيقاف الاهتزاز مع التنبيه'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<RepeatInterval>(
          value: _settings.repeatInterval,
          decoration: const InputDecoration(
            labelText: 'تكرار التذكير',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final interval in RepeatInterval.values)
              DropdownMenuItem(
                value: interval,
                child: Text(interval.arLabel),
              ),
          ],
          onChanged: (value) {
            if (value != null) {
              _save(_settings.copyWith(repeatInterval: value));
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          value: _settings.missedDoseWindowMinutes,
          decoration: const InputDecoration(
            labelText: 'وقت اعتبار الجرعة فائتة',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 60, child: Text('بعد ساعة')),
            DropdownMenuItem(value: 120, child: Text('بعد ساعتين')),
            DropdownMenuItem(value: 180, child: Text('بعد 3 ساعات')),
            DropdownMenuItem(value: 240, child: Text('بعد 4 ساعات')),
          ],
          onChanged: (value) {
            if (value != null) {
              _save(_settings.copyWith(missedDoseWindowMinutes: value));
            }
          },
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.language),
          title: const Text('اللغة'),
          subtitle: const Text('العربية افتراضياً'),
          trailing: const Text('AR'),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _exporting ? null : _export,
          icon: _exporting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download),
          label: const Text('تصدير سجل العلاج CSV'),
        ),
      ],
    );
  }

  Future<void> _save(AppSettings settings) async {
    setState(() => _settings = settings);
    await ref.read(settingsRepositoryProvider).saveSettings(settings);
    final futureDoses = (await ref.read(allDosesProvider.future))
        .where((item) => item.event.scheduledAt.isAfter(DateTime.now()))
        .toList();
    await ref.read(notificationServiceProvider).cancelAll();
    await ref.read(notificationServiceProvider).scheduleUpcoming(
          futureDoses,
          settings,
        );
    refreshApp(ref);
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final items = await ref.read(allDosesProvider.future);
    final service = ref.read(exportServiceProvider);
    final file = await service.exportHistoryCsv(items);
    await service.shareCsv(file);
    if (mounted) setState(() => _exporting = false);
  }
}

class _SafetyMessage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'التطبيق لا يشخص ولا يصف ولا يوصي بتغيير الجرعات. استخدمه لتذكير وتتبع الخطة التي أدخلتها فقط.',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
