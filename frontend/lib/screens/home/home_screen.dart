import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/screens/medications/medication.dart';

import 'dart:async';

class HomeScreen extends StatefulWidget {
  final List<Medication> medications;

  final VoidCallback onViewMedications;

  final Future<String> Function(Medication, DateTime) onMedicationTaken;

  final DateTime Function()? clock;

  const HomeScreen({
    required this.medications,
    required this.onViewMedications,
    required this.onMedicationTaken,
    this.clock,
    super.key,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  DateTime get timeNow => widget.clock?.call() ?? DateTime.now();
  Timer? clockTimer;
  static const earlyDoseWindow = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = timeNow;
    final upcomingMedications = <ScheduledMedication>[
      for (final medication in widget.medications)
        if (medication.nextDoseAt(now) case final nextDose?)
          ScheduledMedication(medication, nextDose),
    ]..sort((a, b) => a.nextDose.compareTo(b.nextDose));

    final nextMedication = upcomingMedications.isEmpty
        ? null
        : upcomingMedications.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Good day', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          'Have a lovely day!',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 22),
        ApplicationFeedbackBannerWidget(
          message: widget.medications.isEmpty
              ? 'No medications in your schedule yet.'
              : upcomingMedications.isEmpty
              ? 'No scheduled medication reminders. As-needed medications are in your list.'
              : '${upcomingMedications.length} upcoming medication'
                    '${upcomingMedications.length == 1 ? '' : 's'} in your schedule.',
          icon: Icons.notifications_active_outlined,
        ),

        const SizedBox(height: 24),
        ApplicationSectionHeadingWidget(
          'Next reminder',
          action: TextButton(
            onPressed: widget.onViewMedications,
            child: const Text('See all'),
          ),
        ),

        const SizedBox(height: 12),
        if (nextMedication == null)
          const ApplicationFeedbackBannerWidget(
            message: 'No scheduled reminders to show right now.',
            icon: Icons.medication_outlined,
          )
        else
          ApplicationCardWidget(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      child: Icon(nextMedication.medication.icon, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextMedication.medication.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${nextMedication.medication.dose}  ·  ${formatDoseTime(context, nextMedication.nextDose, now)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                ApplicationButtonWidget(
                  label: 'I have taken it',
                  icon: Icons.check_circle_outline,
                  onPressed:
                      nextMedication.nextDose.isAfter(now.add(earlyDoseWindow))
                      ? null
                      : () async {
                          final message = await widget.onMedicationTaken(
                            nextMedication.medication,
                            nextMedication.nextDose,
                          );
                          if (!mounted) return;
                          showApplicationFeedback(context, message);
                        },
                ),

                if (nextMedication.nextDose.isAfter(
                  now.add(earlyDoseWindow),
                )) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Available 5 minutes before the scheduled dose.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: 26),
        if (upcomingMedications.length > 1) ...[
          const ApplicationSectionHeadingWidget('Coming up'),
          const SizedBox(height: 12),
          for (final scheduled in upcomingMedications.skip(1)) ...[
            UpcomingReminder(
              title: scheduled.medication.name,
              detail: scheduled.medication.dose,
              time: formatDoseTime(context, scheduled.nextDose, now),
              icon: scheduled.medication.icon,
            ),
            const SizedBox(height: 12),
          ],
        ],

        const SizedBox(height: 24),
        ApplicationButtonWidget(
          label: 'View Reminders',
          secondary: true,
          icon: Icons.medication_outlined,
          onPressed: widget.onViewMedications,
        ),
      ],
    );
  }

  String formatDoseTime(BuildContext context, DateTime doseTime, DateTime now) {
    final formattedTime = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(doseTime));
    if (DateUtils.isSameDay(doseTime, now)) return 'Today, $formattedTime';
    if (DateUtils.isSameDay(doseTime, now.add(const Duration(days: 1)))) {
      return 'Tomorrow, $formattedTime';
    }
    return '${MaterialLocalizations.of(context).formatMediumDate(doseTime)}, $formattedTime';
  }
}

class ScheduledMedication {
  final Medication medication;
  final DateTime nextDose;

  const ScheduledMedication(this.medication, this.nextDose);
}

class UpcomingReminder extends StatelessWidget {
  final String title;
  final String detail;
  final String time;
  final IconData icon;

  const UpcomingReminder({
    required this.title,
    required this.detail,
    required this.time,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationCardWidget(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(detail, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),

          const SizedBox(width: 8),
          Text(
            time,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}