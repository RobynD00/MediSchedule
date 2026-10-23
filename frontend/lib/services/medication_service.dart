import 'package:flutter/material.dart';
import 'package:medischedule/screens/medications/medication.dart';
import 'package:medischedule/services/api_client.dart';

class MedicationService {
  static const dayCodes = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  static Future<List<Medication>> load() async {
    final json = await ApiClient.get('/api/medications');
    final items = (json as List<dynamic>).cast<Map<String, dynamic>>();
    return Future.wait(items.map(_withReminders));
  }

  static Future<void> create(Medication medication) async {
    final json = await ApiClient.post(
      '/api/medications',
      body: _body(medication),
    );
    final id = (json['id'] as num).toInt();
    await _createReminders(id, medication);
  }

  static Future<void> update(Medication previous, Medication updated) async {
    final id = previous.id!;
    await ApiClient.put('/api/medications/$id', body: _body(updated));
    final existing = await ApiClient.get('/api/medications/$id/reminders');
    for (final item in existing as List<dynamic>) {
      await ApiClient.delete('/api/reminders/${(item['id'] as num).toInt()}');
    }
    await _createReminders(id, updated);
  }

  static Future<void> remove(Medication medication) async {
    await ApiClient.delete('/api/medications/${medication.id}');
  }

  static Map<String, dynamic> _body(Medication m) => {
        'name': m.name,
        'dosage': m.dose,
        'notes': m.notes,
      };

  static String _date(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  static String _time(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Future<void> _createReminders(int id, Medication m) async {
    final hour = m.timeHour ?? 9;
    final minute = m.timeMinute ?? 0;
    final start = _date(m.startDate);
    final path = '/api/medications/$id/reminders';

    if (m.frequency == 'As needed') return;

    if (m.frequency == 'Weekly') {
      await ApiClient.post(path, body: {
        'reminderTime': _time(hour, minute),
        'frequency': 'SPECIFIC_DAYS',
        'daysOfWeek': dayCodes[m.startDate.weekday - 1],
        'startDate': start,
      });
      return;
    }

    final interval = _intervalHours(m.frequency);
    if (interval == null) {
      await ApiClient.post(path, body: {
        'reminderTime': _time(hour, minute),
        'frequency': 'DAILY',
        'startDate': start,
      });
      return;
    }

    var total = hour * 60 + minute;
    while (total < 24 * 60) {
      await ApiClient.post(path, body: {
        'reminderTime': _time(total ~/ 60, total % 60),
        'frequency': 'DAILY',
        'startDate': start,
      });
      total += interval * 60;
    }
  }

  static int? _intervalHours(String frequency) {
    final match = RegExp(r'^Every (?:(\d+) hours?|hour)$', caseSensitive: false)
        .firstMatch(frequency);
    if (match == null) return null;
    final value = int.tryParse(match.group(1) ?? '') ?? 1;
    return value < 1 ? 1 : value;
  }

  static Future<Medication> _withReminders(Map<String, dynamic> json) async {
    final id = (json['id'] as num).toInt();
    final reminders = await ApiClient.get('/api/medications/$id/reminders');
    final active = (reminders as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((r) => r['active'] != false)
        .toList();

    final minutes = <int>[];
    var weekly = false;
    DateTime? startDate;
    for (final r in active) {
      final parts = (r['reminderTime'] as String).split(':');
      minutes.add(int.parse(parts[0]) * 60 + int.parse(parts[1]));
      if (r['frequency'] == 'SPECIFIC_DAYS') weekly = true;
      final date = DateTime.tryParse((r['startDate'] ?? '') as String);
      if (date != null && (startDate == null || date.isBefore(startDate))) {
        startDate = date;
      }
    }
    minutes.sort();

    String frequency;
    if (minutes.isEmpty) {
      frequency = 'As needed';
    } else if (weekly) {
      frequency = 'Weekly';
    } else if (minutes.length == 1) {
      frequency = 'Daily';
    } else {
      final gap = minutes[1] - minutes[0];
      final even = gap % 60 == 0 &&
          [for (var i = 1; i < minutes.length; i++) minutes[i] - minutes[i - 1]]
              .every((g) => g == gap);
      if (even) {
        final hours = gap ~/ 60;
        frequency = hours == 1 ? 'Every hour' : 'Every $hours hours';
      } else {
        frequency = 'Daily';
      }
    }

    final first = minutes.isEmpty ? 9 * 60 : minutes.first;
    final hour = first ~/ 60;
    final minute = first % 60;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return Medication(
      id: id,
      name: json['name'] as String,
      dose: json['dosage'] as String,
      startDate: startDate ?? DateTime.now(),
      frequency: frequency,
      time: '$displayHour:${minute.toString().padLeft(2, '0')} $period',
      notes: (json['notes'] ?? '') as String,
      icon: Icons.medication_outlined,
      timeHour: hour,
      timeMinute: minute,
    );
  }
}