import 'package:flutter/material.dart';

class Medication {
  final int? id;
  final String name;
  final String dose;
  final DateTime startDate;
  final String frequency;
  final String time;
  final String notes;
  final IconData icon;
  final DateTime? lastTakenDoseAt;
  final DateTime? lastSkippedDoseAt;
  final int? timeHour;
  final int? timeMinute;
  static final RegExp _intervalFrequencyPattern = RegExp(
    r'^Every (?:(\d+) hours?|hour)$',
  );
  const Medication({
    this.id,
    required this.name,
    required this.dose,
    required this.startDate,
    required this.frequency,
    required this.time,
    required this.notes,
    required this.icon,
    this.lastTakenDoseAt,
    this.lastSkippedDoseAt,
    this.timeHour,
    this.timeMinute,
  });
  String get schedule => frequency.startsWith('Every ')
      ? '$frequency starting $time'
      : '$frequency · $time';
  Medication copyWith({
    DateTime? lastTakenDoseAt,
    DateTime? lastSkippedDoseAt,
  }) {
    return Medication(
      id: id,
      name: name,
      dose: dose,
      startDate: startDate,
      frequency: frequency,
      time: time,
      notes: notes,
      icon: icon,
      lastTakenDoseAt: lastTakenDoseAt ?? this.lastTakenDoseAt,
      lastSkippedDoseAt: lastSkippedDoseAt ?? this.lastSkippedDoseAt,
      timeHour: timeHour,
      timeMinute: timeMinute,
    );
  }

  DateTime? nextDoseAt(DateTime now) {
    if (frequency == 'As needed') return null;

    final lastHandledDoseAt = _lastHandledDoseAt;
    final timeParts = _timeParts;
    if (timeParts == null) return null;

    final (hour, minute) = timeParts;
    final firstDose = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
      hour,
      minute,
    );
    final intervalMatch = _intervalFrequencyPattern.firstMatch(frequency);
    if (intervalMatch != null) {
      final interval = int.tryParse(intervalMatch.group(1) ?? '') ?? 1;
      if (interval < 1) return null;
      return nextDailyIntervalDose(
        firstDose: firstDose,
        now: now,
        intervalHours: interval,
      );
    }
    final daysBetween = switch (frequency) {
      'Daily' => 1,
      'Every other day' => 2,
      'Weekly' => 7,
      _ => null,
    };

    if (daysBetween == null) return null;
    if (lastHandledDoseAt == null && now.isBefore(firstDose)) return firstDose;
    if (lastHandledDoseAt != null && lastHandledDoseAt.isBefore(firstDose)) {
      return firstDose;
    }

    final referenceDate = lastHandledDoseAt ?? now;
    final elapsedDays =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .difference(
              DateTime(firstDose.year, firstDose.month, firstDose.day),
            )
            .inDays;
    var periods = elapsedDays ~/ daysBetween;
    var candidate = DateTime(
      firstDose.year,
      firstDose.month,
      firstDose.day + periods * daysBetween,
      firstDose.hour,
      firstDose.minute,
    );
    if (lastHandledDoseAt != null) {
      if (!candidate.isAfter(lastHandledDoseAt)) {
        periods++;
      }
      return DateTime(
        firstDose.year,
        firstDose.month,
        firstDose.day + periods * daysBetween,
        firstDose.hour,
        firstDose.minute,
      );
    }
    return candidate;
  }

  DateTime nextDailyIntervalDose({
    required DateTime firstDose,
    required DateTime now,
    required int intervalHours,
  }) {
    final interval = Duration(hours: intervalHours);

    final lastHandledDoseAt = _lastHandledDoseAt;
    if (lastHandledDoseAt != null) {
      if (lastHandledDoseAt.isBefore(firstDose)) return firstDose;

      final takenDayStart = DateTime(
        lastHandledDoseAt.year,
        lastHandledDoseAt.month,
        lastHandledDoseAt.day,
        firstDose.hour,
        firstDose.minute,
      );

      final nextDayStart = DateTime(
        takenDayStart.year,
        takenDayStart.month,
        takenDayStart.day + 1,
        firstDose.hour,
        firstDose.minute,
      );
      if (lastHandledDoseAt.isBefore(takenDayStart)) return takenDayStart;

      final elapsed = lastHandledDoseAt.difference(takenDayStart);
      final intervals = elapsed.inMicroseconds ~/ interval.inMicroseconds + 1;
      final nextDose = takenDayStart.add(interval * intervals);
      final isSameScheduleDay =
          nextDose.year == takenDayStart.year &&
          nextDose.month == takenDayStart.month &&
          nextDose.day == takenDayStart.day;
      return isSameScheduleDay ? nextDose : nextDayStart;
    }
    if (now.isBefore(firstDose)) return firstDose;

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
      firstDose.hour,
      firstDose.minute,
    );
    final tomorrowStart = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day + 1,
      firstDose.hour,
      firstDose.minute,
    );
    if (now.isBefore(todayStart)) return todayStart;

    final elapsed = now.difference(todayStart);
    final intervals = elapsed.inMicroseconds ~/ interval.inMicroseconds;
    final candidate = todayStart.add(interval * intervals);

    return candidate.isBefore(tomorrowStart) ? candidate : tomorrowStart;
  }

  DateTime? get _lastHandledDoseAt {
    final taken = lastTakenDoseAt;
    final skipped = lastSkippedDoseAt;
    if (taken == null) return skipped;
    if (skipped == null || taken.isAfter(skipped)) return taken;
    return skipped;
  }

  (int, int)? get _timeParts {
    if (timeHour != null && timeMinute != null) {
      if (timeHour! < 0 ||
          timeHour! > 23 ||
          timeMinute! < 0 ||
          timeMinute! > 59) {
        return null;
      }
      return (timeHour!, timeMinute!);
    }
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
      caseSensitive: false,
    ).firstMatch(time.trim());
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    if (minute > 59) return null;
    if (period == null) {
      if (hour > 23) return null;
      return (hour, minute);
    }
    if (hour < 1 || hour > 12) return null;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return (hour, minute);
  }
}