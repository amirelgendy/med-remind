import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/medication.dart';
import '../state/providers.dart';
import '../utils/date_utils.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _strength = TextEditingController();
  final _doseAmount = TextEditingController(text: '1');
  final _doseUnit = TextEditingController(text: 'قرص');
  final _notes = TextEditingController();

  MedicationForm _form = MedicationForm.tablet;
  FoodRelation _foodRelation = FoodRelation.none;
  ReminderRingtone? _ringtone;
  int _dosesPerDay = 1;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  int _color = 0xFF1F7A6D;
  int _icon = Icons.medication.codePoint;
  late List<TimeOfDay> _times;
  bool _saving = false;

  final _colors = const [
    0xFF1F7A6D,
    0xFF2563EB,
    0xFFD97706,
    0xFFBE123C,
    0xFF7C3AED,
    0xFF047857,
  ];

  final _icons = const [
    Icons.medication,
    Icons.medical_services,
    Icons.water_drop,
    Icons.vaccines,
    Icons.spa,
  ];

  @override
  void initState() {
    super.initState();
    _times = [_defaultFirstDoseTime()];
  }

  @override
  void dispose() {
    _name.dispose();
    _strength.dispose();
    _doseAmount.dispose();
    _doseUnit.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة دواء')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _SafetyBox(),
            _field(
              controller: _name,
              label: 'اسم الدواء',
              icon: Icons.medication,
              validator: _required,
            ),
            _field(
              controller: _strength,
              label: 'التركيز، مثال: 24 mg',
              icon: Icons.science_outlined,
            ),
            _dropdown<MedicationForm>(
              label: 'الشكل',
              value: _form,
              items: MedicationForm.values,
              labelOf: (value) => value.arLabel,
              onChanged: (value) => setState(() => _form = value),
            ),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _doseAmount,
                    label: 'كمية الجرعة',
                    icon: Icons.format_list_numbered,
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    controller: _doseUnit,
                    label: 'وحدة الجرعة',
                    icon: Icons.straighten,
                    validator: _required,
                  ),
                ),
              ],
            ),
            _DoseCountSelector(
              value: _dosesPerDay,
              onChanged: _setDoseCount,
            ),
            const SizedBox(height: 8),
            Text(
              'أوقات الجرعات',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            const Text(
              'اضغط على وقت الجرعة الأولى لتحديد أول موعد تنبيه.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < _times.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(i == 0 ? 'موعد الجرعة الأولى' : 'الجرعة ${i + 1}'),
                trailing: FilledButton.tonal(
                  onPressed: () => _pickTime(i),
                  child: Text(_times[i].format(context)),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _dateTile(
                    label: 'تاريخ البداية',
                    value: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateTile(
                    label: 'تاريخ النهاية',
                    value: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            _dropdown<FoodRelation>(
              label: 'العلاقة بالطعام',
              value: _foodRelation,
              items: FoodRelation.values,
              labelOf: (value) => value.arLabel,
              onChanged: (value) => setState(() => _foodRelation = value),
            ),
            _dropdown<ReminderRingtone?>(
              label: 'نغمة هذا الدواء',
              value: _ringtone,
              items: [null, ...ReminderRingtone.values],
              labelOf: (value) => value?.arLabel ?? 'استخدام النغمة الافتراضية',
              onChanged: (value) => setState(() => _ringtone = value),
            ),
            const SizedBox(height: 10),
            Text('لون أو أيقونة', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final color in _colors)
                  ChoiceChip(
                    selected: _color == color,
                    label: const SizedBox(width: 18, height: 18),
                    avatar: CircleAvatar(backgroundColor: Color(color)),
                    onSelected: (_) => setState(() => _color = color),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                for (final icon in _icons)
                  ChoiceChip(
                    selected: _icon == icon.codePoint,
                    label: Icon(icon),
                    onSelected: (_) => setState(() => _icon = icon.codePoint),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('حفظ الدواء وإنشاء جدول الجرعات'),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(labelOf(item))),
        ],
        onChanged: (value) {
          if (value != null || null is T) onChanged(value as T);
        },
      ),
    );
  }

  Widget _dateTile({
    required String label,
    required DateTime value,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(formatArabicDate(value)),
        leading: const Icon(Icons.event),
        onTap: onTap,
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  void _setDoseCount(int value) {
    setState(() {
      _dosesPerDay = value;
      final next = [..._times];
      while (next.length < value) {
        final hour = (8 + next.length * 6) % 24;
        next.add(TimeOfDay(hour: hour, minute: 0));
      }
      _times = next.take(value).toList();
    });
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );
    if (picked == null) return;
    setState(() => _times[index] = picked);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = dateOnly(picked);
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = dateOnly(picked);
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final medication = Medication(
      name: _name.text.trim(),
      strength: _strength.text.trim(),
      form: _form,
      doseAmount: _doseAmount.text.trim(),
      doseUnit: _doseUnit.text.trim(),
      dosesPerDay: _dosesPerDay,
      startDate: _startDate,
      endDate: _endDate,
      foodRelation: _foodRelation,
      notes: _notes.text.trim(),
      colorValue: _color,
      iconCodePoint: _icon,
      ringtone: _ringtone,
    );

    await ref
        .read(medicationRepositoryProvider)
        .addMedication(medication: medication, doseTimes: _times);
    final settings = await ref.read(settingsProvider.future);
    final repository = ref.read(medicationRepositoryProvider);
    final notificationService = ref.read(notificationServiceProvider);
    final allDoses = await repository.getAllDoseEvents();
    final futureDoses = allDoses
        .where((item) => item.event.scheduledAt.isAfter(DateTime.now()))
        .toList();
    unawaited(
      notificationService.scheduleUpcoming(futureDoses, settings).catchError(
            (_) {},
          ),
    );
    refreshApp(ref);
    if (mounted) Navigator.pop(context);
  }
}

TimeOfDay _defaultFirstDoseTime() {
  final now = DateTime.now().add(const Duration(minutes: 10));
  final minute = ((now.minute + 4) ~/ 5) * 5;
  final adjusted = DateTime(now.year, now.month, now.day, now.hour, minute);
  return TimeOfDay(hour: adjusted.hour, minute: adjusted.minute);
}

class _DoseCountSelector extends StatelessWidget {
  const _DoseCountSelector({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('عدد الجرعات يومياً', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1')),
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {value},
              onSelectionChanged: (selected) => onChanged(selected.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'هذا التطبيق يذكّرك فقط بما أدخلته أنت. لا يصف أدوية ولا يقترح جرعات أو يغير خطة العلاج.',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );
  }
}
