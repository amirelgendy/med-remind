import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/dose_event.dart';

class ExportService {
  Future<File> exportHistoryCsv(List<DoseWithMedication> items) async {
    final rows = <List<String>>[
      [
        'Medication name',
        'Scheduled time',
        'Status',
        'Taken time',
        'Notes',
      ],
      ...items.map(
        (item) => [
          item.medication.name,
          item.event.scheduledAt.toIso8601String(),
          item.event.status.name,
          item.event.takenAt?.toIso8601String() ?? '',
          item.event.notes,
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/medication_history_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    return file.writeAsString(csv);
  }

  Future<void> shareCsv(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'سجل جرعات الدواء',
    );
  }
}
