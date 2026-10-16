import 'package:flutter/material.dart';
import '../core/theme/application_theme.dart';
import 'application_shell.dart';

// Root application: applies the shared theme and launches the navigation shell.
class MediScheduleApp extends StatelessWidget 
{
  const MediScheduleApp({super.key});

  @override
  Widget build(BuildContext context) 
  {
    return MaterialApp
    (
      title: 'MediSchedule',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppShell(),
    );
  }
}
