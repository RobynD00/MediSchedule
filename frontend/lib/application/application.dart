import 'package:flutter/material.dart';
import 'package:medischedule/application/application_routes.dart';
import 'package:medischedule/application/application_shell.dart';
import 'package:medischedule/core/application_theme.dart';
import 'package:medischedule/screens/medications/medication.dart';
import 'package:medischedule/screens/notification/notification_screen.dart';

// Root application: applies the shared theme and launches the navigation shell.
class MediScheduleApplication extends StatelessWidget {
  const MediScheduleApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: highContrastEnabled,
      builder: (context, enabled, _) => MaterialApp(
        title: 'MediSchedule',
        debugShowCheckedModeBanner: false,
        theme: enabled
            ? ApplicationTheme.highContrastTheme
            : ApplicationTheme.lightTheme,
        initialRoute: ApplicationRoutes.home,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case ApplicationRoutes.home:
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const ApplicationShell(),
              );
            case ApplicationRoutes.notifications:
              final arguments = settings.arguments;
              if (arguments is! List<Medication>) {
                return MaterialPageRoute<void>(
                  settings: settings,
                  builder: (_) => const Scaffold(
                    body: Center(child: Text('Notification data unavailable.')),
                  ),
                );
              }
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => NotificationScreen(medications: arguments),
              );
            default:
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => const Scaffold(
                  body: Center(child: Text('We cant find it :<.')),
                ),
              );
          }
        },
      ),
    );
  }
}
