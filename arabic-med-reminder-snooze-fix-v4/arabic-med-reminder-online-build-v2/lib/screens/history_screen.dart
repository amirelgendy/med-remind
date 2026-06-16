import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(courseHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('سجل الكورس')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const EmptyState(
          message: 'تعذر تحميل سجل الكورس.',
          icon: Icons.error_outline,
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(message: 'لا يوجد سجل جرعات بعد.');
          }
          final days = items.keys.toList()..sort((a, b) => b.compareTo(a));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final counts = items[day]!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatArabicDate(day),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Chip(label: 'تم أخذها', value: counts.taken),
                          _Chip(label: 'فائتة', value: counts.missed),
                          _Chip(label: 'تم تخطيها', value: counts.skipped),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      avatar: const Icon(Icons.circle, size: 12),
    );
  }
}
