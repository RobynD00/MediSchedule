import 'package:flutter/material.dart';
import 'package:medischedule/core/application_theme.dart';
import 'package:medischedule/core/application_widget.dart';
import '../auth/logout_screen.dart';

// Displays the profile and settings screen, allowing users to manage their preferences and access help information. The screen includes sections for personal details, preferences, and a help button. It uses a ListView to display the content, with various cards and buttons for user interaction.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Builds the settings screen UI, displaying profile information, preferences, and a help button. It uses a ListView to organize the content and provides a user-friendly interface for managing settings.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The settings screen is structured using a ListView, which allows for vertical scrolling of the content. It includes a title, description, profile card, preference cards, and a help button. The profile card displays a welcome message and placeholder information, while the preference cards provide options for managing display and reminder settings. The help button allows users to access assistance or support.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text('Profile & settings', style: theme.textTheme.headlineSmall),

        const SizedBox(height: 8),
        Text(
          'Manage your preferences or get help.',
          style: theme.textTheme.bodyLarge,
        ),

        // The profile card is displayed using the AppCard widget, which provides a consistent styling for cards throughout the application. It contains a CircleAvatar for the user's profile picture, a welcome message, and placeholder text indicating that the user's profile information will appear in this section. The card is padded and styled to create a visually appealing layout.
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
                    Text('Welcome', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('Profile.', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        // The preferences section is introduced with a heading using the AppSectionHeading widget, which displays the title "Preferences" and can optionally include an action widget. Below the heading, two preference cards are displayed using the _PreferenceCard widget, which presents options for managing readable display settings and reminders. Each card includes an icon, title, and subtitle to provide clear information about the preference option.
        const SizedBox(height: 20),
        const ApplicationSectionHeadingWidget('Preferences'),
        // The preference cards are displayed using the _PreferenceCard widget, which is a custom widget that takes an icon, title, and subtitle as parameters. The first card allows users to manage readable display settings, while the second card provides information about reminder settings. Each card is styled consistently with the rest of the application and provides a clear representation of the preference option for the user.
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
        // The second preference card provides information about reminder settings, indicating that reminder settings will appear in this section. It uses the same _PreferenceCard widget to maintain consistency in the UI design.
        const SizedBox(height: 12),
        const PreferenceCard(
          icon: Icons.notifications_outlined,
          title: 'Reminders',
          subtitle: 'Reminder Settings',
        ),
        // The help button is displayed using the AppButton widget, which provides a consistent styling for buttons throughout the application. When pressed, it shows a feedback message indicating that help options will be available soon. The button includes an icon and label to clearly indicate its purpose to the user.
        const SizedBox(height: 24),
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

// A card widget that displays a preference option with an icon, title, and subtitle. It is used in the settings screen to present user preferences in a visually appealing manner.
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

  // Builds the preference card UI, displaying the icon, title, and subtitle in a row layout. The card is styled using the AppCard widget and provides a clear representation of the preference option for the user.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The preference card is displayed using the AppCard widget, which provides consistent styling for cards throughout the application. It contains a row layout with an icon, title, and subtitle, allowing users to easily understand the preference option being presented. The card is padded and styled to create a visually appealing layout that aligns with the overall design of the settings screen.
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
