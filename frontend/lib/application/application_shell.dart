import 'package:flutter/material.dart';
import 'package:medischedule/application/application_routes.dart';
import 'package:medischedule/screens/home/home_screen.dart';
import 'package:medischedule/screens/medications/medication_screen.dart';
import 'package:medischedule/screens/medications/medication.dart';
import 'package:medischedule/screens/medical_information/medical_information.dart';
import 'package:medischedule/screens/profile_settings/settings_screen.dart';
import 'package:medischedule/screens/notification/notification_screen.dart';

import 'dart:async';

// Keeps the medication list and in-app reminder state in one place.
class ApplicationShell extends StatefulWidget {
  const ApplicationShell({super.key});

  @override
  State<ApplicationShell> createState() => ApplicationShellState();
}

class ApplicationShellState extends State<ApplicationShell>
    with WidgetsBindingObserver {
  int selectedIndex = 0;
  bool medicationFormOpen = false;
  bool appResumed = true;
  bool notificationDialogOpen = false;
  Timer? notificationTimer;

  late final DateTime notificationTrackingStartedAt;
  static const snoozeDuration = Duration(minutes: 2);

  // Temporary data: Medication records are stored in memory and Data is lost when the app restarts.
  final List<Medication> medications = [];
  final Set<String> shownNotificationKeys = {};
  final Map<String, SnoozedNotification> snoozedNotifications = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    notificationTrackingStartedAt = DateTime.now();
    notificationTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => checkNotifications(),
    );
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    appResumed = state == AppLifecycleState.resumed;
    if (appResumed) {
      checkNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // On the Home page, Android back button can exit. On another tab it will return to the Home page.
      // When the add medication form is open, Back will be blocked to protect adding and edits.
      canPop: selectedIndex == 0 && !medicationFormOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (medicationFormOpen) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please close the medication form before going back.',
              ),
            ),
          );
        } else if (selectedIndex != 0) {
          selectTab(0);
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: const Text('MediSchedule'),
          actions: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  ApplicationRoutes.notifications,
                  arguments: List<Medication>.of(medications),
                );
              },
            ),
          ],
        ),

        body: IndexedStack(
          index: selectedIndex,
          children: [
            HomeScreen(
              medications: medications,
              onViewMedications: () => selectTab(1),
              onMedicationTaken: markMedicationTaken,
            ),

            MedicationScreen(
              medications: medications,
              onAddMedication: addMedication,
              onUpdateMedication: updateMedication,
              onRemoveMedication: removeMedication,
              onMedicationFormVisibilityChanged: (isOpen) {
                medicationFormOpen = isOpen;
              },
            ),

            const MedicalInfoScreen(),

            const SettingsScreen(),
          ],
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: selectTab,
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
      ),
    );
  }

  void selectTab(int index) {
    setState(() => selectedIndex = index);
  }

  // Notification:
  void showNotification({
    required Medication medication,
    required DateTime scheduledAt,
    required String key,
  }) {
    notificationDialogOpen = true;
    showNoticationScreen(
      context,
      medication: medication,
      scheduledAt: scheduledAt,
      onTaken: () => markMedicationTaken(medication, scheduledAt),
      onSkipped: () => skipMedicationDose(medication, scheduledAt),
      onSnoozed: () {
        snoozedNotifications[key] = SnoozedNotification(
          medication: medication,
          scheduledAt: scheduledAt,
          remindAt: DateTime.now().add(snoozeDuration),
        );
      },
    ).whenComplete(() {
      notificationDialogOpen = false;
    });
    // The next periodic check can display another due reminder.
  }

  void markMedicationTaken(Medication medication, DateTime scheduledAt) {
    final index = medications.indexOf(medication);
    if (index == -1) return;
    clearSnoozeForDose(medication, scheduledAt);
    setState(
      () => medications[index] = medication.copyWith(
        lastTakenDoseAt: scheduledAt,
      ),
    );
  }

  void skipMedicationDose(Medication medication, DateTime scheduledAt) {
    final index = medications.indexOf(medication);
    if (index == -1) {
      return;
    }
    clearSnoozeForDose(medication, scheduledAt);
    setState(
      () => medications[index] = medication.copyWith(
        lastSkippedDoseAt: scheduledAt,
      ),
    );
  }

  void clearSnoozeForDose(Medication medication, DateTime scheduledAt) {
    snoozedNotifications.removeWhere(
      (_, value) =>
          identical(value.medication, medication) &&
          value.scheduledAt == scheduledAt,
    );
  }

  // Checks for scheduled doses only while the application is running.
  void checkNotifications() {
    if (!mounted ||
        !appResumed ||
        notificationDialogOpen ||
        medicationFormOpen ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }

    final now = DateTime.now();
    // Snoozed reminders are shown before new scheduled doses.
    final snoozedDue =
        snoozedNotifications.entries
            .where(
              (entry) =>
                  medications.contains(entry.value.medication) &&
                  !entry.value.remindAt.isAfter(now),
            )
            .toList()
          ..sort((a, b) => a.value.remindAt.compareTo(b.value.remindAt));

    if (snoozedDue.isNotEmpty) {
      final entry = snoozedDue.first;
      snoozedNotifications.remove(entry.key);
      showNotification(
        key: entry.key,
        medication: entry.value.medication,
        scheduledAt: entry.value.scheduledAt,
      );
      return;
    }
    // Check each medication. A handled dose moves forward via nextDoseAt().
    // Starting at app launch prevents a flood of old overdue popups.
    final due = <({Medication medication, DateTime scheduledAt, String key})>[];
    for (final medication in medications) {
      final scheduledAt = medication.nextDoseAt(now);
      if (scheduledAt == null ||
          scheduledAt.isBefore(notificationTrackingStartedAt) ||
          scheduledAt.isAfter(now)) {
        continue;
      }

      final key = notificationKey(medication, scheduledAt);
      if (!shownNotificationKeys.contains(key)) {
        due.add((medication: medication, scheduledAt: scheduledAt, key: key));
      }
    }

    if (due.isEmpty) {
      return;
    }

    due.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final first = due.first;
    shownNotificationKeys.add(first.key);
    showNotification(
      key: first.key,
      medication: first.medication,
      scheduledAt: first.scheduledAt,
    );
  }

  void clearNotificationState(Medication medication) {
    snoozedNotifications.removeWhere(
      (_, value) => identical(value.medication, medication),
    );
    final prefix = '${identityHashCode(medication)}:';
    shownNotificationKeys.removeWhere((key) => key.startsWith(prefix));
  }

  String notificationKey(Medication medication, DateTime scheduledAt) {
    String rkey =
        '${identityHashCode(medication)}:${scheduledAt.toIso8601String()}';
    return rkey;
  }

  // Add Medication.
  void addMedication(Medication medication) {
    setState(() => medications.add(medication));
  }

  // Update Medication.
  void updateMedication(Medication previous, Medication updated) {
    final index = medications.indexOf(previous);
    if (index == -1) {
      return;
    }
    clearNotificationState(previous);
    setState(() => medications[index] = updated);
  }

  // Remove Medication.
  void removeMedication(Medication medication) {
    clearNotificationState(medication);
    setState(() => medications.remove(medication));
  }
}

class SnoozedNotification {
  final Medication medication;
  final DateTime scheduledAt;
  final DateTime remindAt;

  const SnoozedNotification({
    required this.medication,
    required this.scheduledAt,
    required this.remindAt,
  });
}
