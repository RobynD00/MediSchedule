import 'package:flutter/material.dart';
import '../../core/application_widget.dart';
import '../../services/auth_service.dart';

class LogoutScreen extends StatefulWidget
{
  final VoidCallback? onLogoutConfirmed;

  const LogoutScreen({
    this.onLogoutConfirmed,
    super.key,
  });

  @override
  State<LogoutScreen> createState() => _LogoutScreenState();
}

class _LogoutScreenState extends State<LogoutScreen>
{
  bool _isLoading = false;

  Future<void> _handleLogout() async
  {
    setState(() => _isLoading = true);

    await AuthService().logout();

    if (!mounted) return;

    setState(() => _isLoading = false);

    showApplicationFeedback(context, 'You have been logged out.');

    if (widget.onLogoutConfirmed != null) {
      widget.onLogoutConfirmed!();
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Out'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sign out of MediSchedule', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out? You will need to sign in again to view your reminders.',
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: 24),

            ApplicationCardWidget(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    child: Icon(Icons.person_outline, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Logged in User',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'user@example.com',
                    style: theme.textTheme.bodyMedium,
                  ),

                  const SizedBox(height: 28),

                  ApplicationButtonWidget(
                    label: 'Log Out',
                    icon: Icons.logout,
                    isLoading: _isLoading,
                    onPressed: _handleLogout,
                  ),

                  const SizedBox(height: 12),

                  ApplicationButtonWidget(
                    label: 'Cancel',
                    secondary: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}