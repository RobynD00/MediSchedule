// A repeating reminder for one medication (matches the backend ReminderResponse).
class ReminderSchedule {
  final int id;
  final int medicationId;
  final String reminderTime; // "08:00"
  final String frequency; // DAILY or SPECIFIC_DAYS
  final String? daysOfWeek; // "MON,WED,FRI"

  const ReminderSchedule({
    required this.id,
    required this.medicationId,
    required this.reminderTime,
    required this.frequency,
    required this.daysOfWeek,
  });

  // Plain-language description for the list, e.g. "Every day" or "Mon, Wed, Fri".
  String get repeatsText {
    if (frequency == 'DAILY') return 'Every day';
    final days = (daysOfWeek ?? '').split(',').where((d) => d.isNotEmpty);
    return days.map((d) => d[0] + d.substring(1).toLowerCase()).join(', ');
  }

  factory ReminderSchedule.fromJson(Map<String, dynamic> json) {
    return ReminderSchedule(
      id: json['id'] as int,
      medicationId: json['medicationId'] as int,
      reminderTime: json['reminderTime'] as String? ?? '',
      frequency: json['frequency'] as String? ?? 'DAILY',
      daysOfWeek: json['daysOfWeek'] as String?,
    );
  }
}
