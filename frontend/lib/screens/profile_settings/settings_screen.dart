import 'package:flutter/material.dart';
import 'package:medischedule/core/application_theme.dart';
import 'package:medischedule/core/application_widget.dart';
import '../auth/logout_screen.dart';
import '../../services/auth_service.dart';
import '../caregiver/caregiver_dashboard_screen.dart';
import '../caregiver/caregiver_screen.dart';
import '../history/dose_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Profile & settings', style: theme.textTheme.headlineSmall),

        const SizedBox(height: 8),
        Text(
          'Manage your preferences or get help.',
          style: theme.textTheme.bodyLarge,
        ),

        const SizedBox(height: 20),
        ApplicationCardWidget(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 28,
                child: Icon(Icons.person_outline, size: 30),
              ),

              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AuthService.fullName.isEmpty
                          ? 'Welcome'
                          : 'Welcome, ${AuthService.fullName}',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AuthService.isCaregiver ? 'Caregiver account' : 'Patient account',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const ApplicationSectionHeadingWidget('Preferences'),
        const SizedBox(height: 12),
        const PreferenceCard(
          icon: Icons.text_fields,
          title: 'Readable display',
          subtitle: 'Large text are enabled',
        ),

        const SizedBox(height: 12),
        ValueListenableBuilder<bool>(
          valueListenable: highContrastEnabled,
          builder: (context, enabled, _) => ApplicationCardWidget(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.contrast),
              title: const Text('High contrast'),
              subtitle: const Text('Use stronger colors and clearer borders'),
              value: enabled,
              onChanged: (value) => highContrastEnabled.value = value,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const PreferenceCard(
          icon: Icons.notifications_outlined,
          title: 'Reminders',
          subtitle: 'Reminder Settings',
        ),
        const SizedBox(height: 24),
        ApplicationButtonWidget(
          label: 'Dose history',
          icon: Icons.history,
          secondary: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DoseHistoryScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (AuthService.isCaregiver)
          ApplicationButtonWidget(
            label: 'Caregiver dashboard',
            icon: Icons.groups_outlined,
            secondary: true,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CaregiverDashboardScreen(),
                ),
              );
            },
          )
        else
          ApplicationButtonWidget(
            label: 'My caregivers',
            icon: Icons.family_restroom_outlined,
            secondary: true,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CaregiverScreen(),
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        ApplicationButtonWidget(
          label: 'Get Help',
          icon: Icons.help_outline,
          secondary: true,
          onPressed: () => showApplicationFeedback(context, 'Help Options.'),
        ),

        const SizedBox(height: 12),
        ApplicationButtonWidget(
          label: 'Log Out',
          icon: Icons.logout,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const LogoutScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class PreferenceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const PreferenceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
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
                Text(subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}