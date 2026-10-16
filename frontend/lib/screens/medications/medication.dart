import 'package:flutter/material.dart';

// The Medication class encapsulates the properties and behaviors of a medication, including its name, dose, start date, frequency, time of administration, notes, and icon. It also tracks the last taken and skipped doses, allowing for the calculation of the next scheduled dose based on the medication's schedule and history. The class provides methods to copy instances with updated values and to determine the next eligible dose time based on various scheduling patterns.
class Medication 
{
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
  // Regular expression pattern to match frequency strings like "Every X hours" or "hour".
  static final RegExp _intervalFrequencyPattern = RegExp(
    r'^Every (?:(\d+) hours?|hour)$',
  );
  // Constructs a new Medication instance with the specified properties, including name, dose, start date, frequency, time of administration, notes, icon, and optional last taken and skipped dose timestamps. The constructor initializes the medication's attributes and allows for the creation of medication objects with relevant scheduling information.
  const Medication({
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
  // Returns a human-readable string representation of the medication's schedule, combining the frequency and time of administration. If the frequency starts with "Every", it indicates a recurring schedule starting at the specified time; otherwise, it combines the frequency and time with a separator.
  String get schedule => frequency.startsWith('Every ')
      ? '$frequency starting $time'
      : '$frequency · $time';
  // Returns a new instance of the Medication class with updated values for lastTakenDoseAt and lastSkippedDoseAt.
  //
  // The copyWith method allows creating a new instance of the Medication class with updated values for lastTakenDoseAt and lastSkippedDoseAt while keeping the other properties unchanged. This is useful for maintaining immutability and updating the medication's dose history without modifying the original instance.
  // The method takes two optional parameters, lastTakenDoseAt and lastSkippedDoseAt, which represent the timestamps of the last taken and skipped doses, respectively. If these parameters are not provided, the method retains the existing values from the original instance.
  Medication copyWith
  ({
    DateTime? lastTakenDoseAt,
    DateTime? lastSkippedDoseAt,
  }) {
    return Medication
    (
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
  // Calculates the next scheduled dose based on the medication's schedule and history.
  //
  // Returns null if the medication is "As needed" or if the schedule is unsupported or invalid.
  // The calculation considers the start date, frequency, and the last handled dose (taken or skipped) to determine the next eligible dose time.
  DateTime? nextDoseAt(DateTime now) 
  {
    // If the medication is "As needed", there is no scheduled dose, so return null.
    if (frequency == 'As needed') return null;

    final lastHandledDoseAt = _lastHandledDoseAt;
    final timeParts = _timeParts;
    // If the time parts are null, it indicates an invalid schedule, and the method returns null.
    if (timeParts == null) return null;

    final (hour, minute) = timeParts;
    // The first scheduled dose is anchored to the start date and the specified time.
    final firstDose = DateTime
    (
      startDate.year,
      startDate.month,
      startDate.day,
      hour,
      minute,
    );
    // If the first dose is in the future, return it as the next scheduled dose.
    final intervalMatch = _intervalFrequencyPattern.firstMatch(frequency);
    // Hourly intervals are anchored to the first dose and limited to one day.
    if (intervalMatch != null) 
    {
      final interval = int.tryParse(intervalMatch.group(1) ?? '') ?? 1;
      // If the interval is less than 1 hour, return null to indicate an invalid schedule.
      if (interval < 1) return null;
      return _nextDailyIntervalDose
      (
        firstDose: firstDose,
        now: now,
        intervalHours: interval,
      );
    }
    // Calendar-based schedules are anchored to the first dose and limited to one day.
    final daysBetween = switch (frequency) 
    {
      'Daily' => 1,
      'Every other day' => 2,
      'Weekly' => 7,
      _ => null,
    };

    if (daysBetween == null) return null;
    // For calendar-based schedules, find the next eligible day after the
    // start date or the most recently taken/skipped dose.
    if (lastHandledDoseAt == null && now.isBefore(firstDose)) return firstDose;
    // If the last handled dose is before the first dose, return the first dose.
    if (lastHandledDoseAt != null && lastHandledDoseAt.isBefore(firstDose)) return firstDose;

    final referenceDate = lastHandledDoseAt ?? now;
    final elapsedDays =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day)
            .difference(
              DateTime(firstDose.year, firstDose.month, firstDose.day),
            )
            .inDays;
    var periods = elapsedDays ~/ daysBetween;
    var candidate = DateTime
    (
      firstDose.year,
      firstDose.month,
      firstDose.day + periods * daysBetween,
      firstDose.hour,
      firstDose.minute,
    );
    // If the candidate is not after the last handled dose, move to the next period.
    if (lastHandledDoseAt != null) 
    {
      if (!candidate.isAfter(lastHandledDoseAt)) 
      {
        periods++;
      }
      return DateTime
      (
        firstDose.year,
        firstDose.month,
        firstDose.day + periods * daysBetween,
        firstDose.hour,
        firstDose.minute,
      );
    }
    return candidate;
  }

  // Calculates the next scheduled dose for a daily interval schedule.
  DateTime _nextDailyIntervalDose
  ({
    required DateTime firstDose,
    required DateTime now,
    required int intervalHours,
  }) {
    
    final interval = Duration(hours: intervalHours);

    final lastHandledDoseAt = _lastHandledDoseAt;
    // If the last handled dose is before the first dose, return the first dose.
    if (lastHandledDoseAt != null) 
    {
      if (lastHandledDoseAt.isBefore(firstDose)) return firstDose;

      final takenDayStart = DateTime
      (
        lastHandledDoseAt.year,
        lastHandledDoseAt.month,
        lastHandledDoseAt.day,
        firstDose.hour,
        firstDose.minute,
      );

      final nextDayStart = DateTime
      (
        takenDayStart.year,
        takenDayStart.month,
        takenDayStart.day + 1,
        firstDose.hour,
        firstDose.minute,
      );
      // If the last handled dose is before the start of the day, return the start of the day as the next scheduled dose.
      if (lastHandledDoseAt.isBefore(takenDayStart)) return takenDayStart;

      final elapsed = lastHandledDoseAt.difference(takenDayStart);
      final intervals = elapsed.inMicroseconds ~/ interval.inMicroseconds + 1;
      final nextDose = takenDayStart.add(interval * intervals);
      // If another interval would cross into tomorrow, restart at tomorrow's
      // scheduled first-dose time.
      final isSameScheduleDay =
          nextDose.year == takenDayStart.year &&
          nextDose.month == takenDayStart.month &&
          nextDose.day == takenDayStart.day;
      return isSameScheduleDay ? nextDose : nextDayStart;
    }
    // If the last handled dose is null, check if the first dose is in the future.
    if (now.isBefore(firstDose)) return firstDose;

    final todayStart = DateTime
    (
      now.year,
      now.month,
      now.day,
      firstDose.hour,
      firstDose.minute,
    );
    final tomorrowStart = DateTime
    (
      todayStart.year,
      todayStart.month,
      todayStart.day + 1,
      firstDose.hour,
      firstDose.minute,
    );
    // If the current time is before today's scheduled dose, return today's scheduled dose.
    if (now.isBefore(todayStart)) return todayStart;

    final elapsed = now.difference(todayStart);
    final intervals = elapsed.inMicroseconds ~/ interval.inMicroseconds;
    final candidate = todayStart.add(interval * intervals);

    return candidate.isBefore(tomorrowStart) ? candidate : tomorrowStart;
  }

  // Returns the most recent dose-handling timestamp, or null if none exist.
  DateTime? get _lastHandledDoseAt 
  {
    final taken = lastTakenDoseAt;
    final skipped = lastSkippedDoseAt;
    // If both taken and skipped doses are null, return null to indicate that no doses have been handled yet.
    if (taken == null) return skipped;
    // If the taken dose is after the skipped dose, return the taken dose; otherwise, return the skipped dose.
    if (skipped == null || taken.isAfter(skipped)) return taken;
    return skipped;
  }

  // Returns the hour and minute of the scheduled dose time, or null if invalid.
  (int, int)? get _timeParts 
  {
    if (timeHour != null && timeMinute != null) 
    {
      if (timeHour! < 0 ||
          timeHour! > 23 ||
          timeMinute! < 0 ||
          timeMinute! > 59) {
        return null;
      }
      return (timeHour!, timeMinute!);
    }
    // If timeHour and timeMinute are not provided, parse the time string to extract the hour and minute.
    final match = RegExp
    (
      r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$',
      caseSensitive: false,
    ).firstMatch(time.trim());
    // If the time string does not match the expected format, return null to indicate an invalid time.
    if (match == null) return null;

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)?.toUpperCase();
    // If the hour or minute is out of range, return null to indicate an invalid time.
    if (minute > 59) return null;
    // If the period is not provided, assume a 24-hour format and return the hour and minute.
    if (period == null) 
    {
      if (hour > 23) return null;
      return (hour, minute);
    }
    // If the period is provided, convert the hour to a 24-hour format based on the AM/PM designation.
    if (hour < 1 || hour > 12) return null;
    // If the period is PM and the hour is not 12, add 12 to convert to 24-hour format. If the period is AM and the hour is 12, set the hour to 0 (midnight).
    if (period == 'PM' && hour != 12) hour += 12;
    // If the period is AM and the hour is 12, set the hour to 0 (midnight).
    if (period == 'AM' && hour == 12) hour = 0;
    return (hour, minute);
  }
}
