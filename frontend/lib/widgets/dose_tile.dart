import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/models/dose_record.dart';

// One dose in a list. Status is shown with an icon AND a word, never colour alone.
class DoseTile extends StatelessWidget {
  final DoseRecord dose;
  final bool showPatient; // caregiver views show whose dose it was

  const DoseTile({required this.dose, this.showPatient = false, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, label, color) = switch (dose.status) {
      'TAKEN' => (Icons.check_circle, 'Taken', theme.colorScheme.primary),
      'MISSED' => (Icons.cancel, 'Missed', theme.colorScheme.error),
      'SKIPPED' => (Icons.remove_circle_outline, 'Skipped', theme.colorScheme.outline),
      _ => (Icons.schedule, 'Waiting', theme.colorScheme.secondary),
    };
    final loc = MaterialLocalizations.of(context);
    final when =
        '${loc.formatMediumDate(dose.scheduledAt)}, ${loc.formatTimeOfDay(TimeOfDay.fromDateTime(dose.scheduledAt))}';

    return ApplicationCardWidget(
      padding: const EdgeInsets.all(16),
      child: Semantics(
        label: '${dose.medicationName}, $label, $when',
        child: Row(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dose.medicationName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('${dose.dosage} · $when', style: theme.textTheme.bodyMedium),
                  if (showPatient && dose.patientName.isNotEmpty)
                    Text('For ${dose.patientName}', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
