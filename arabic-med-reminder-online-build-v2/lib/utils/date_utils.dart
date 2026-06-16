import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

String timeOfDayToStorage(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay storageToTimeOfDay(String value) {
  final parts = value.split(':');
  return TimeOfDay(
    hour: int.parse(parts.first),
    minute: int.parse(parts.last),
  );
}

String formatArabicTime(DateTime value) {
  return DateFormat('hh:mm a', 'ar').format(value);
}

String formatArabicDate(DateTime value) {
  return DateFormat('d MMMM yyyy', 'ar').format(value);
}

Iterable<DateTime> eachDayInclusive(DateTime start, DateTime end) sync* {
  var current = dateOnly(start);
  final last = dateOnly(end);
  while (!current.isAfter(last)) {
    yield current;
    current = current.add(const Duration(days: 1));
  }
}
