import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';

class MedicalInfoScreen extends StatelessWidget {
  const MedicalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Health Info', style: theme.textTheme.headlineSmall),

        const SizedBox(height: 8),
        Text('Important Details.', style: theme.textTheme.bodyLarge),

        const SizedBox(height: 20),
        const HealthInfoCard(
          icon: Icons.person_outline,
          title: 'Personal details',
          value: 'Profile information',
        ),

        const SizedBox(height: 12),
        const HealthInfoCard(
          icon: Icons.medication_outlined,
          title: 'Allergies',
          value: 'Allergies information',
        ),

        const SizedBox(height: 12),
        const HealthInfoCard(
          icon: Icons.local_hospital_outlined,
          title: 'Medical conditions',
          value: 'Medical conditions information',
        ),

        const SizedBox(height: 24),
        ApplicationButtonWidget(
          label: 'QR code',
          icon: Icons.qr_code_2,
          onPressed: () =>
              showApplicationFeedback(context, 'Emergency QR Pressed.'),
        ),
      ],
    );
  }
}

class HealthInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const HealthInfoCard({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ApplicationCardWidget(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Icon(icon, size: 26, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
