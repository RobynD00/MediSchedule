import 'package:medischedule/models/dose_record.dart';
import 'package:medischedule/models/reminder_schedule.dart';
import 'package:medischedule/services/api_client.dart';

// Reminders, dose actions and dose history (backend: ReminderController and DoseController).
class DoseService {
  // ----- reminder schedules -----
  static Future<List<ReminderSchedule>> reminders(int medicationId) async {
    final json = await ApiClient.get('/api/medications/$medicationId/reminders');
    return [
      for (final item in json as List<dynamic>)
        ReminderSchedule.fromJson(item as Map<String, dynamic>),
    ];
  }

  // time is "HH:mm". days is only used when frequency is SPECIFIC_DAYS, e.g. ["MON", "WED"].
  static Future<ReminderSchedule> addReminder({
    required int medicationId,
    required String time,
    required bool daily,
    List<String> days = const [],
  }) async {
    final json = await ApiClient.post(
      '/api/medications/$medicationId/reminders',
      body: {
        'reminderTime': time,
        'frequency': daily ? 'DAILY' : 'SPECIFIC_DAYS',
        if (!daily) 'daysOfWeek': days.join(','),
      },
    );
    return ReminderSchedule.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> deleteReminder(int reminderId) async {
    await ApiClient.delete('/api/reminders/$reminderId');
  }

  // ----- doses -----
  // Doses the user should be reminded about right now.
  static Future<List<DoseRecord>> due() async {
    final json = await ApiClient.get('/api/doses/due');
    return _doses(json);
  }

  static Future<void> markTaken(int doseId) async {
    await ApiClient.post('/api/doses/$doseId/taken');
  }

  static Future<void> snooze(int doseId) async {
    await ApiClient.post('/api/doses/$doseId/snooze');
  }

  static Future<void> skip(int doseId) async {
    await ApiClient.post('/api/doses/$doseId/skip');
  }

  // History, newest first. medicationId is an optional filter.
  static Future<List<DoseRecord>> history({int? medicationId}) async {
    final json = await ApiClient.get(
      '/api/doses/history',
      query: {if (medicationId != null) 'medicationId': '$medicationId'},
    );
    return _doses(json);
  }

  static List<DoseRecord> _doses(dynamic json) => [
    for (final item in json as List<dynamic>)
      DoseRecord.fromJson(item as Map<String, dynamic>),
  ];
}
