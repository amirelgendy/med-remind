import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../state/providers.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDoses = ref.watch(allDosesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات')),
      body: allDoses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          message: 'تعذر تحميل الإحصائيات.',
          icon: Icons.error_outline,
        ),
        data: (items) {
          final now = DateTime.now();
          final today = items
              .where((i) => dateOnly(i.event.scheduledAt) == dateOnly(now))
              .toList();
          final weekStart = dateOnly(now).subtract(const Duration(days: 6));
          final week = items
              .where((i) => i.event.scheduledAt.isAfter(weekStart))
              .toList();
          final pending =
              items.where((i) => i.event.status == DoseStatus.pending).length;
          final missed =
              items.where((i) => i.event.status == DoseStatus.missed).length;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatCard(
                label: 'الالتزام اليوم',
                value: _adherence(today),
                icon: Icons.today,
              ),
              _StatCard(
                label: 'الالتزام الأسبوعي',
                value: _adherence(week),
                icon: Icons.date_range,
              ),
              _StatCard(
                label: 'الالتزام الكامل للكورس',
                value: _adherence(items),
                icon: Icons.show_chart,
              ),
              _NumberCard(
                label: 'إجمالي الجرعات المعلقة',
                value: pending.toString(),
                icon: Icons.pending_actions,
              ),
              _NumberCard(
                label: 'إجمالي الجرعات الفائتة',
                value: missed.toString(),
                icon: Icons.warning_amber,
              ),
            ],
          );
        },
      ),
    );
  }

  String _adherence(List items) {
    final taken = items.where((i) => i.event.status == DoseStatus.taken).length;
    final counted = items
        .where((i) =>
            i.event.status == DoseStatus.taken ||
            i.event.status == DoseStatus.missed ||
            i.event.status == DoseStatus.skipped)
        .length;
    if (counted == 0) return '0%';
    return '${((taken / counted) * 100).round()}%';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _NumberCard(label: label, value: value, icon: icon);
  }
}

class _NumberCard extends StatelessWidget {
  const _NumberCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 34),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
