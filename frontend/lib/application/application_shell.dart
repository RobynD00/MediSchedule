import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/medications/medication_screen.dart';
import '../screens/medications/medication.dart';
import '../screens/profile_settings/settings_screen.dart';
import '../screens/notification/notification_screen.dart';
import '../screens/medical_information/medical_information.dart';
import 'dart:async';

// Keeps the medication list and in-app reminder state in one place.
class AppShell extends StatefulWidget 
{
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver 
{
  // Temporary data:
  // Medication records are stored in memory and Data is lost when the app restarts.
  final List<Medication> _medications = [];
  final Set<String> _shownReminderKeys = {};
  final Map<String, _SnoozedReminder> _snoozedReminders = {};

  static const _snoozeDuration = Duration(minutes: 10);
  int _selectedIndex = 0;
  bool _medicationFormOpen = false;
  bool _appResumed = true;
  bool _reminderDialogOpen = false;
  late final DateTime _reminderTrackingStartedAt;
  Timer? _reminderTimer;

  @override
  void initState() 
  {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reminderTrackingStartedAt = DateTime.now();
    _reminderTimer = Timer.periodic (
      const Duration(seconds: 1),
      (_) => _checkReminders(),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) 
  {
    _appResumed = state == AppLifecycleState.resumed;
    if (_appResumed) _checkReminders();
  }

  @override
  void dispose() 
  {
    _reminderTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  void _addMedication(Medication medication) 
  {
    setState(() => _medications.add(medication));
  }

  void _updateMedication(Medication previous, Medication updated) 
  {
    final index = _medications.indexOf(previous);
    if (index == -1) return;
    _clearReminderState(previous);
    setState(() => _medications[index] = updated);
  }

  void _removeMedication(Medication medication) 
  {
    _clearReminderState(medication);
    setState(() => _medications.remove(medication));
  }

  void _clearReminderState(Medication medication) 
  {
    _snoozedReminders.removeWhere(
      (_, value) => identical(value.medication, medication),
    );
    final prefix = '${identityHashCode(medication)}:';
    _shownReminderKeys.removeWhere((key) => key.startsWith(prefix));
  }

  void _clearSnoozeForDose(Medication medication, DateTime scheduledAt) 
  {
    _snoozedReminders.removeWhere(
      (_, value) => identical(value.medication, medication) &&
          value.scheduledAt == scheduledAt,
    );
  }

  void _markMedicationTaken(Medication medication, DateTime scheduledAt) 
  {
    final index = _medications.indexOf(medication);
    if (index == -1) return;
    _clearSnoozeForDose(medication, scheduledAt);
    setState(() {
      _medications[index] = medication.copyWith(lastTakenDoseAt: scheduledAt);
    });
  }

  void _skipMedicationDose(Medication medication, DateTime scheduledAt) 
  {
    final index = _medications.indexOf(medication);
    if (index == -1) return;
    _clearSnoozeForDose(medication, scheduledAt);
    setState(() {
      _medications[index] = medication.copyWith(lastSkippedDoseAt: scheduledAt);
    });
  }

  String _reminderKey(Medication medication, DateTime scheduledAt) =>'${identityHashCode(medication)}:${scheduledAt.toIso8601String()}';

  // Temporary reminder:
  // Checks for scheduled doses only while the application is running.
  void _checkReminders() 
  {
    if (!mounted || !_appResumed || _reminderDialogOpen || _medicationFormOpen || ModalRoute.of(context)?.isCurrent != true) return;   

    final now = DateTime.now();

    // Snoozed reminders are shown before new scheduled doses.
    final snoozedDue = _snoozedReminders.entries.where((entry) =>
        _medications.contains(entry.value.medication) &&
        !entry.value.remindAt.isAfter(now)).toList()
      ..sort((a, b) => a.value.remindAt.compareTo(b.value.remindAt));

    if (snoozedDue.isNotEmpty) 
    {
      final entry = snoozedDue.first;
      _snoozedReminders.remove(entry.key);
      _showReminder(
        key: entry.key,
        medication: entry.value.medication,
        scheduledAt: entry.value.scheduledAt,
      );
      return;
    }

    // Check each medication. A handled dose moves forward via nextDoseAt().
    // Starting at app launch prevents a flood of old overdue popups.
    final due = <({Medication medication, DateTime scheduledAt, String key})>[];
    for (final medication in _medications) 
    {
      final scheduledAt = medication.nextDoseAt(now);

      if (scheduledAt == null || scheduledAt.isBefore(_reminderTrackingStartedAt) || scheduledAt.isAfter(now)) continue;
      
      final key = _reminderKey(medication, scheduledAt);

      if (!_shownReminderKeys.contains(key)) due.add((medication: medication, scheduledAt: scheduledAt, key: key));   
    }

    if (due.isEmpty) return;

    due.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final first = due.first;
    _shownReminderKeys.add(first.key);
    _showReminder(
      key: first.key,
      medication: first.medication,
      scheduledAt: first.scheduledAt,
    );
  }

  void _showReminder({
    required String key,
    required Medication medication,
    required DateTime scheduledAt,
  }) {
    _reminderDialogOpen = true;
    showMedicationReminderPopup(
      context,
      medication: medication,
      scheduledAt: scheduledAt,
      onTaken: () => _markMedicationTaken(medication, scheduledAt),
      onSkipped: () => _skipMedicationDose(medication, scheduledAt),
      onSnoozed: () {
        _snoozedReminders[key] = _SnoozedReminder(
          medication: medication,
          scheduledAt: scheduledAt,
          remindAt: DateTime.now().add(_snoozeDuration),
        );
      },
    ).whenComplete(() {
      _reminderDialogOpen = false;
      // The next periodic check can display another due reminder.
    });
  }

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
              title: const Text('MediSchedule'),
              actions: [
                IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NotificationScreen(
                          medications: List<Medication>.of(_medications),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen
          (
            medications: _medications,
            onViewMedications: () => _selectTab(1),
            onMedicationTaken: _markMedicationTaken,
          ),
          MedicationScreen
          (
            medications: _medications,
            onAddMedication: _addMedication,
            onUpdateMedication: _updateMedication,
            onRemoveMedication: _removeMedication,
            onFormVisibilityChanged: (isOpen) {
              _medicationFormOpen = isOpen;
            },
          ),
          const MedicalInfoScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Medication',
          ),
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'Medical Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile/Settings',
          ),
        ],
      ),
    );
  }
}

class _SnoozedReminder {
  const _SnoozedReminder({
    required this.medication,
    required this.scheduledAt,
    required this.remindAt,
  });

  final Medication medication;
  final DateTime scheduledAt;
  final DateTime remindAt;
}