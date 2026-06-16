import 'package:flutter/material.dart';

import '../models/dose_event.dart';
import '../models/enums.dart';
import '../utils/date_utils.dart';

class DoseCard extends StatelessWidget {
  const DoseCard({
    super.key,
    required this.item,
    required this.onTaken,
    required this.onSnooze,
    required this.onSkip,
    this.showSafetyMessage = false,
  });

  final DoseWithMedication item;
  final VoidCallback onTaken;
  final VoidCallback onSnooze;
  final VoidCallback onSkip;
  final bool showSafetyMessage;

  @override
  Widget build(BuildContext context) {
    final med = item.medication;
    final event = item.event;
    final color = Color(med.colorValue);
    final canAct =
        event.status == DoseStatus.pending || event.status == DoseStatus.snoozed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.14),
                  foregroundColor: color,
                  radius: 24,
                  child: Icon(
                    med.iconCodePoint == null
                        ? Icons.medication_liquid
                        : IconData(
                            med.iconCodePoint!,
                            fontFamily: 'MaterialIcons',
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${med.doseAmount} ${med.doseUnit} • ${med.foodRelation.arLabel}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatArabicTime(event.scheduledAt),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            if (event.status == DoseStatus.snoozed &&
                event.snoozedUntil != null) ...[
              const SizedBox(height: 10),
              Text(
                'مؤجلة حتى ${formatArabicTime(event.snoozedUntil!)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (showSafetyMessage) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'فات موعد هذه الجرعة. لا تضاعف الجرعة لتعويض الجرعة الفائتة إلا إذا أخبرك الطبيب أو الصيدلي بذلك.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            if (canAct) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: onTaken,
                    icon: const Icon(Icons.check),
                    label: const Text('أخذت الجرعة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onSnooze,
                    icon: const Icon(Icons.snooze),
                    label: const Text('تأجيل'),
                  ),
                  TextButton.icon(
                    onPressed: onSkip,
                    icon: const Icon(Icons.close),
                    label: const Text('تخطي'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
