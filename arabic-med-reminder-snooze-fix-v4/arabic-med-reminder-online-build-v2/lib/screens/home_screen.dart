import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/dose_event.dart';
import '../models/enums.dart';
import '../state/providers.dart';
import '../widgets/dose_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import 'medication_details_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doses = ref.watch(todayDosesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواعيد الدواء اليوم'),
        actions: [
          IconButton(
            tooltip: 'الأدوية',
            onPressed: () => _showMedicationList(context, ref),
            icon: const Icon(Icons.medication_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshApp(ref),
        child: doses.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              EmptyState(
                message: 'تعذر تحميل الجرعات. حاول مرة أخرى.',
                icon: Icons.error_outline,
              ),
            ],
          ),
          data: (items) {
            final now = DateTime.now();
            final dueNow = items
                .where((item) =>
                    (item.event.status == DoseStatus.pending ||
                        item.event.status == DoseStatus.snoozed) &&
                    !(item.event.snoozedUntil ?? item.event.scheduledAt)
                        .isAfter(now))
                .toList();
            final upcoming = items
                .where((item) =>
                    (item.event.status == DoseStatus.pending ||
                        item.event.status == DoseStatus.snoozed) &&
                    (item.event.snoozedUntil ?? item.event.scheduledAt)
                        .isAfter(now))
                .toList();
            final missed = items
                .where((item) => item.event.status == DoseStatus.missed)
                .toList();
            final taken = items
                .where((item) => item.event.status == DoseStatus.taken)
                .toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                _PermissionNotice(),
                _DoseSection(title: 'مستحق الآن', items: dueNow),
                _DoseSection(title: 'قادم اليوم', items: upcoming),
                _DoseSection(
                  title: 'جرعات فائتة',
                  items: missed,
                  showSafetyMessage: true,
                ),
                _DoseSection(title: 'تم أخذها اليوم', items: taken),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMedicationList(BuildContext context, WidgetRef ref) {
    final medications = ref.read(medicationsProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => medications.when(
        loading: () => const SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const Padding(
          padding: EdgeInsets.all(24),
          child: Text('تعذر تحميل قائمة الأدوية.'),
        ),
        data: (items) => ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'الأدوية',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            for (final med in items)
              ListTile(
                leading: CircleAvatar(backgroundColor: Color(med.colorValue)),
                title: Text(med.name),
                subtitle: Text('${med.strength} • ${med.dosesPerDay} مرة يومياً'),
                trailing: IconButton(
                  tooltip: 'حذف الدواء',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDeleteMedication(context, ref, med.id!),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MedicationDetailsScreen(
                        medicationId: med.id!,
                      ),
                    ),
                  );
                },
              ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('لم تضف أي دواء بعد.'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteMedication(
    BuildContext context,
    WidgetRef ref,
    int medicationId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الدواء'),
        content: const Text(
          'سيتم حذف الدواء وكل جرعاته من التطبيق. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(notificationServiceProvider).cancelAll();
    await ref.read(medicationRepositoryProvider).deleteMedication(medicationId);
    final settings = await ref.read(settingsProvider.future);
    final futureDoses = (await ref.read(medicationRepositoryProvider)
            .getAllDoseEvents())
        .where((item) => item.event.scheduledAt.isAfter(DateTime.now()))
        .toList();
    await ref.read(notificationServiceProvider).scheduleUpcoming(
          futureDoses,
          settings,
        );
    refreshApp(ref);
    if (context.mounted) Navigator.pop(context);
  }
}

class _DoseSection extends ConsumerWidget {
  const _DoseSection({
    required this.title,
    required this.items,
    this.showSafetyMessage = false,
  });

  final String title;
  final List<DoseWithMedication> items;
  final bool showSafetyMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, count: items.length),
        if (items.isEmpty)
          EmptyState(message: _emptyMessage(title))
        else
          for (final item in items)
            DoseCard(
              item: item,
              showSafetyMessage: showSafetyMessage,
              onTaken: () => _markTaken(ref, item),
              onSnooze: () => _snooze(context, ref, item),
              onSkip: () => _skip(ref, item),
            ),
      ],
    );
  }

  String _emptyMessage(String title) {
    return switch (title) {
      'مستحق الآن' => 'لا توجد جرعات مستحقة الآن.',
      'قادم اليوم' => 'لا توجد جرعات أخرى اليوم.',
      'جرعات فائتة' => 'لا توجد جرعات فائتة اليوم.',
      _ => 'لم يتم تسجيل جرعات مأخوذة اليوم.',
    };
  }

  Future<void> _markTaken(WidgetRef ref, DoseWithMedication item) async {
    await ref.read(medicationRepositoryProvider).markTaken(item.event.id!);
    await ref.read(notificationServiceProvider).cancelDose(item.event.id!);
    refreshApp(ref);
  }

  Future<void> _skip(WidgetRef ref, DoseWithMedication item) async {
    await ref.read(medicationRepositoryProvider).skip(item.event.id!);
    await ref.read(notificationServiceProvider).cancelDose(item.event.id!);
    refreshApp(ref);
  }

  Future<void> _snooze(
    BuildContext context,
    WidgetRef ref,
    DoseWithMedication item,
  ) async {
    final minutes = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('اختر مدة التأجيل')),
            for (final value in [5, 10, 15, 30])
              ListTile(
                leading: const Icon(Icons.snooze),
                title: Text('$value دقائق'),
                onTap: () => Navigator.pop(context, value),
              ),
          ],
        ),
      ),
    );
    if (minutes == null) return;
    await ref.read(notificationServiceProvider).cancelDose(item.event.id!);
    await ref
        .read(medicationRepositoryProvider)
        .snooze(item.event.id!, Duration(minutes: minutes));
    final settings = await ref.read(settingsProvider.future);
    final updated =
        await ref.read(databaseProvider).getDoseWithMedication(item.event.id!);
    if (updated != null) {
      await ref
          .read(notificationServiceProvider)
          .scheduleDoseReminder(updated, settings);
    }
    refreshApp(ref);
  }
}

class _PermissionNotice extends ConsumerStatefulWidget {
  @override
  ConsumerState<_PermissionNotice> createState() => _PermissionNoticeState();
}

class _PermissionNoticeState extends ConsumerState<_PermissionNotice> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اسمح بالإشعارات حتى تعمل تذكيرات الدواء بشكل صحيح.',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'قد تحتاج أيضاً للسماح بالمنبهات الدقيقة وإلغاء قيود البطارية من إعدادات أندرويد إذا تأخرت التنبيهات.',
            style: TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(notificationServiceProvider).requestPermissions();
                  setState(() => _dismissed = true);
                },
                icon: const Icon(Icons.notifications_active),
                label: const Text('السماح الآن'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await openAppSettings();
                  setState(() => _dismissed = true);
                },
                icon: const Icon(Icons.settings),
                label: const Text('فتح الإعدادات'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => setState(() => _dismissed = true),
                child: const Text('لاحقاً'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
