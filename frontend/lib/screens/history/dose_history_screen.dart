import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/models/dose_record.dart';
import 'package:medischedule/services/dose_service.dart';
import 'package:medischedule/widgets/dose_tile.dart';

// History of taken, missed and skipped doses (UC09). Open it with:
//   Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DoseHistoryScreen()));
class DoseHistoryScreen extends StatefulWidget {
  const DoseHistoryScreen({super.key});

  @override
  State<DoseHistoryScreen> createState() => _DoseHistoryScreenState();
}

class _DoseHistoryScreenState extends State<DoseHistoryScreen> {
  bool loading = true;
  String? error;
  List<DoseRecord> doses = [];
  String filter = 'ALL'; // ALL, TAKEN, MISSED or SKIPPED

  static const filters = {
    'ALL': 'All',
    'TAKEN': 'Taken',
    'MISSED': 'Missed',
    'SKIPPED': 'Skipped',
  };

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
      final result = await DoseService.history();
      if (!mounted) return;
      setState(() => doses = result);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Waiting/snoozed doses only show under "All".
    final visible = filter == 'ALL'
        ? doses
        : doses.where((d) => d.status == filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My history')),
      body: loading
          ? const ApplicationLoadingWidget(message: 'Loading your history...')
          : error != null
          ? ApplicationErrorWidget(message: error!, onRetry: load)
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final entry in filters.entries)
                        ChoiceChip(
                          label: Text(entry.value, style: const TextStyle(fontSize: 16)),
                          selected: filter == entry.key,
                          onSelected: (_) => setState(() => filter = entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (visible.isEmpty)
                    const ApplicationFeedbackBannerWidget(
                      message:
                          'Nothing here yet. Your taken and missed medications will show up here.',
                      icon: Icons.history,
                    )
                  else
                    for (final dose in visible) ...[
                      DoseTile(dose: dose),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            ),
    );
  }
}
