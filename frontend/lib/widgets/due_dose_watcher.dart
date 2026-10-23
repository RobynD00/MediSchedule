import 'dart:async';
import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/models/dose_record.dart';
import 'package:medischedule/services/api_client.dart';
import 'package:medischedule/services/dose_service.dart';

// Wrap a screen with this to show the reminder popup for doses the BACKEND says are due.
// Every answer (taken, later, skip) is saved on the server, so History and caregiver alerts stay correct.
//   DueDoseWatcher(child: <your screen>)
// Do not use it together with the old in-memory popup timer in ApplicationShell, or you will get two popups.
class DueDoseWatcher extends StatefulWidget {
  final Widget child;
  final Duration interval;

  const DueDoseWatcher({
    required this.child,
    this.interval = const Duration(seconds: 30),
    super.key,
  });

  @override
  State<DueDoseWatcher> createState() => _DueDoseWatcherState();
}

class _DueDoseWatcherState extends State<DueDoseWatcher> with WidgetsBindingObserver {
  Timer? timer;
  bool dialogOpen = false;
  bool appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(widget.interval, (_) => check());
    check();
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appResumed = state == AppLifecycleState.resumed;
    if (appResumed) check(); // catch up as soon as the user opens the app
  }

  Future<void> check() async {
    if (!mounted || dialogOpen || !appResumed || ApiClient.token == null) return;
    try {
      final due = await DoseService.due();
      if (!mounted || dialogOpen || due.isEmpty) return;
      await show(due.first);
    } on Exception {
      // Quietly ignore: the next check will try again.
    }
  }

  Future<void> show(DoseRecord dose) async {
    dialogOpen = true;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final time = MaterialLocalizations.of(ctx)
            .formatTimeOfDay(TimeOfDay.fromDateTime(dose.scheduledAt));
        return Dialog(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.notifications_active, size: 58, color: scheme.primary),
                const SizedBox(height: 12),
                Text('Medication reminder', style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(dose.medicationName,
                    textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text('${dose.dosage} · Scheduled for $time',
                    textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodyLarge),
                if ((dose.notes ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(dose.notes!,
                      textAlign: TextAlign.center, style: Theme.of(ctx).textTheme.bodyMedium),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, 'taken'),
                    child: const Text('I have taken it'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: scheme.secondary,
                      foregroundColor: scheme.onSecondary,
                    ),
                    onPressed: () => Navigator.pop(ctx, 'snooze'),
                    child: const Text('Remind me later'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 'skip'),
                  child: const Text('Skip the medication'),
                ),
              ],
            ),
          ),
        );
      },
    );
    dialogOpen = false;
    if (choice == null || !mounted) return;

    // Save the answer on the server and tell the user it worked.
    try {
      switch (choice) {
        case 'taken':
          await DoseService.markTaken(dose.id);
          if (mounted) showApplicationFeedback(context, 'Well done. Dose recorded.');
        case 'snooze':
          await DoseService.snooze(dose.id);
          if (mounted) showApplicationFeedback(context, 'OK, we will remind you again soon.');
        default:
          await DoseService.skip(dose.id);
          if (mounted) showApplicationFeedback(context, 'Dose skipped.');
      }
    } on Exception catch (e) {
      if (mounted) showApplicationFeedback(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
