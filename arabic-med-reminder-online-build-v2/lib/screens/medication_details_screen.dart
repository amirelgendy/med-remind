import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../state/providers.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';

class MedicationDetailsScreen extends ConsumerWidget {
  const MedicationDetailsScreen({super.key, required this.medicationId});

  final int medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(medicationDetailsProvider(medicationId));
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الدواء')),
      body: details.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          message: 'تعذر تحميل تفاصيل الدواء.',
          icon: Icons.error_outline,
        ),
        data: (data) {
          final med = data.medication;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(med.colorValue),
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.medication),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text('${med.strength} • ${med.form.arLabel}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      _InfoRow('بداية الكورس', formatArabicDate(med.startDate)),
                      _InfoRow('نهاية الكورس', formatArabicDate(med.endDate)),
                      _InfoRow('الجرعة', '${med.doseAmount} ${med.doseUnit}'),
                      _InfoRow('الطعام', med.foodRelation.arLabel),
                      if (med.notes.isNotEmpty) _InfoRow('ملاحظات', med.notes),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _StatsGrid(details: data),
              const SizedBox(height: 18),
              Text('سجل الجرعات الكامل', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final event in data.events)
                Card(
                  child: ListTile(
                    leading: Icon(_statusIcon(event.status)),
                    title: Text(formatArabicDate(event.scheduledAt)),
                    subtitle: Text(
                      '${formatArabicTime(event.scheduledAt)} • ${event.status.arLabel}',
                    ),
                    trailing: event.takenAt == null
                        ? null
                        : Text(formatArabicTime(event.takenAt!)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  IconData _statusIcon(DoseStatus status) {
    return switch (status) {
      DoseStatus.taken => Icons.check_circle,
      DoseStatus.missed => Icons.warning_amber,
      DoseStatus.skipped => Icons.cancel,
      DoseStatus.snoozed => Icons.snooze,
      DoseStatus.pending => Icons.schedule,
    };
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.details});

  final MedicationDetails details;

  @override
  Widget build(BuildContext context) {
    final percent = (details.adherence * 100).round();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.7,
      children: [
        _StatTile(label: 'إجمالي الجرعات', value: details.total.toString()),
        _StatTile(label: 'تم أخذها', value: details.taken.toString()),
        _StatTile(label: 'فائتة', value: details.missed.toString()),
        _StatTile(label: 'تم تخطيها', value: details.skipped.toString()),
        _StatTile(label: 'الالتزام', value: '$percent%'),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
