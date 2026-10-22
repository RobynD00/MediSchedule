import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/models/reminder_schedule.dart';
import 'package:medischedule/services/dose_service.dart';

// Add, view and delete the reminder times of ONE medication (UC04).
// Needs the backend medication id, so open it from the medication screen once Step 4 is connected:
//   Navigator.of(context).push(MaterialPageRoute<void>(
//     builder: (_) => ReminderScheduleScreen(medicationId: id, medicationName: name)));
class ReminderScheduleScreen extends StatefulWidget {
  final int medicationId;
  final String medicationName;

  const ReminderScheduleScreen({
    required this.medicationId,
    required this.medicationName,
    super.key,
  });

  @override
  State<ReminderScheduleScreen> createState() => _ReminderScheduleScreenState();
}

class _ReminderScheduleScreenState extends State<ReminderScheduleScreen> {
  static const allDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  bool loading = true;
  bool saving = false;
  String? error;
  List<ReminderSchedule> reminders = [];

  // New reminder form state.
  TimeOfDay time = const TimeOfDay(hour: 8, minute: 0);
  bool daily = true;
  final Set<String> chosenDays = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await DoseService.reminders(widget.medicationId);
      if (!mounted) return;
      setState(() => reminders = result);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: time);
    if (picked != null) setState(() => time = picked);
  }

  Future<void> save() async {
    // Input validation: specific days needs at least one day.
    if (!daily && chosenDays.isEmpty) {
      showApplicationFeedback(context, 'Please choose at least one day.', isError: true);
      return;
    }
    setState(() => saving = true);
    try {
      final hh = time.hour.toString().padLeft(2, '0');
      final mm = time.minute.toString().padLeft(2, '0');
      await DoseService.addReminder(
        medicationId: widget.medicationId,
        time: '$hh:$mm',
        daily: daily,
        // Keep Mon..Sun order.
        days: allDays.where(chosenDays.contains).toList(),
      );
      if (!mounted) return;
      showApplicationFeedback(context, 'Reminder saved.');
      await load();
    } on Exception catch (e) {
      if (mounted) showApplicationFeedback(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> confirmDelete(ReminderSchedule r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this reminder?'),
        content: Text('${r.reminderTime} · ${r.repeatsText}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await DoseService.deleteReminder(r.id);
      if (!mounted) return;
      showApplicationFeedback(context, 'Reminder deleted.');
      await load();
    } on Exception catch (e) {
      if (mounted) showApplicationFeedback(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('${widget.medicationName} reminders')),
      body: loading
          ? const ApplicationLoadingWidget()
          : error != null
          ? ApplicationErrorWidget(message: error!, onRetry: load)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const ApplicationSectionHeadingWidget('Add a reminder'),
                const SizedBox(height: 12),
                ApplicationCardWidget(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ApplicationButtonWidget(
                        label: 'Time: ${time.format(context)}',
                        icon: Icons.access_time,
                        secondary: true,
                        onPressed: pickTime,
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Every day')),
                          ButtonSegment(value: false, label: Text('Chosen days')),
                        ],
                        selected: {daily},
                        onSelectionChanged: (s) => setState(() => daily = s.first),
                      ),
                      if (!daily) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final day in allDays)
                              FilterChip(
                                label: Text(day[0] + day.substring(1).toLowerCase(),
                                    style: const TextStyle(fontSize: 16)),
                                selected: chosenDays.contains(day),
                                onSelected: (on) => setState(
                                  () => on ? chosenDays.add(day) : chosenDays.remove(day),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      ApplicationButtonWidget(
                        label: 'Save reminder',
                        icon: Icons.check,
                        isLoading: saving,
                        onPressed: save,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const ApplicationSectionHeadingWidget('Saved reminders'),
                const SizedBox(height: 12),
                if (reminders.isEmpty)
                  const ApplicationFeedbackBannerWidget(
                    message: 'No reminders yet. Add a time above.',
                    icon: Icons.notifications_none,
                  )
                else
                  for (final r in reminders) ...[
                    ApplicationCardWidget(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.reminderTime, style: theme.textTheme.titleLarge),
                                Text(r.repeatsText, style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete reminder',
                            iconSize: 30,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => confirmDelete(r),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
    );
  }
}
