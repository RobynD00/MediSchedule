import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/models/caregiver_link.dart';
import 'package:medischedule/models/dose_record.dart';
import 'package:medischedule/services/caregiver_service.dart';
import 'package:medischedule/widgets/dose_tile.dart';

// Caregiver: accept invitations, see missed-dose alerts and adherence (UC08, UC10).
class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() => _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  bool loading = true;
  String? error;
  List<CaregiverLink> invitations = [];
  List<CaregiverLink> patients = [];
  List<DoseRecord> alerts = [];

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
      // The three requests are independent, so run them together.
      final results = await Future.wait([
        CaregiverService.invitations(),
        CaregiverService.patients(),
        CaregiverService.alerts(),
      ]);
      if (!mounted) return;
      setState(() {
        invitations = results[0] as List<CaregiverLink>;
        patients = results[1] as List<CaregiverLink>;
        alerts = results[2] as List<DoseRecord>;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> accept(CaregiverLink link) async {
    try {
      await CaregiverService.accept(link.id);
      if (!mounted) return;
      showApplicationFeedback(context, 'You are now looking after ${link.patientName}.');
      await load();
    } on Exception catch (e) {
      if (mounted) showApplicationFeedback(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver dashboard')),
      body: loading
          ? const ApplicationLoadingWidget()
          : error != null
          ? ApplicationErrorWidget(message: error!, onRetry: load)
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (invitations.isNotEmpty) ...[
                    const ApplicationSectionHeadingWidget('Invitations'),
                    const SizedBox(height: 12),
                    for (final inv in invitations) ...[
                      ApplicationCardWidget(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${inv.patientName} would like you as their caregiver.',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 12),
                            ApplicationButtonWidget(
                              label: 'Accept',
                              icon: Icons.check,
                              onPressed: () => accept(inv),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 12),
                  ],
                  const ApplicationSectionHeadingWidget('Missed doses (last 7 days)'),
                  const SizedBox(height: 12),
                  if (alerts.isEmpty)
                    const ApplicationFeedbackBannerWidget(
                      message: 'No missed doses. Good news!',
                      icon: Icons.check_circle_outline,
                    )
                  else
                    for (final dose in alerts) ...[
                      DoseTile(dose: dose, showPatient: true),
                      const SizedBox(height: 12),
                    ],
                  const SizedBox(height: 12),
                  const ApplicationSectionHeadingWidget('People I look after'),
                  const SizedBox(height: 12),
                  if (patients.isEmpty)
                    const ApplicationFeedbackBannerWidget(
                      message: 'Nobody yet. Accept an invitation to get started.',
                      icon: Icons.people_outline,
                    )
                  else
                    for (final p in patients) ...[
                      ApplicationCardWidget(
                        padding: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: const Icon(Icons.person_outline, size: 32),
                          title: Text(p.patientName, style: theme.textTheme.titleMedium),
                          subtitle: const Text('See how they are doing'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => PatientAdherenceScreen(
                                patientId: p.patientId,
                                patientName: p.patientName,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
    );
  }
}

// Taken vs missed numbers and recent doses for one patient.
class PatientAdherenceScreen extends StatefulWidget {
  final int patientId;
  final String patientName;

  const PatientAdherenceScreen({
    required this.patientId,
    required this.patientName,
    super.key,
  });

  @override
  State<PatientAdherenceScreen> createState() => _PatientAdherenceScreenState();
}

class _PatientAdherenceScreenState extends State<PatientAdherenceScreen> {
  late Future<AdherenceSummary> future = CaregiverService.adherence(widget.patientId);

  void retry() => setState(() => future = CaregiverService.adherence(widget.patientId));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(widget.patientName)),
      body: FutureBuilder<AdherenceSummary>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const ApplicationLoadingWidget();
          }
          if (snapshot.hasError) {
            return ApplicationErrorWidget(message: snapshot.error.toString(), onRetry: retry);
          }
          final s = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ApplicationCardWidget(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last ${s.days} days', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('${s.adherencePercent}% of doses taken',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Taken: ${s.taken}   Missed: ${s.missed}   Skipped: ${s.skipped}',
                        style: theme.textTheme.bodyLarge),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const ApplicationSectionHeadingWidget('Recent doses'),
              const SizedBox(height: 12),
              if (s.recent.isEmpty)
                const ApplicationFeedbackBannerWidget(
                  message: 'No doses recorded yet.',
                  icon: Icons.history,
                )
              else
                for (final dose in s.recent) ...[
                  DoseTile(dose: dose),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}
