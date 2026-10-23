import 'package:flutter/material.dart';
import 'package:medischedule/application/application_routes.dart';
import 'package:medischedule/screens/home/home_screen.dart';
import 'package:medischedule/screens/medications/medication_screen.dart';
import 'package:medischedule/screens/medications/medication.dart';
import 'package:medischedule/screens/medical_information/medical_information.dart';
import 'package:medischedule/screens/profile_settings/settings_screen.dart';
import 'package:medischedule/services/api_client.dart';
import 'package:medischedule/services/dose_service.dart';
import 'package:medischedule/services/medication_service.dart';
import 'package:medischedule/widgets/due_dose_watcher.dart';

class ApplicationShell extends StatefulWidget {
  const ApplicationShell({super.key});

  @override
  State<ApplicationShell> createState() => ApplicationShellState();
}

class ApplicationShellState extends State<ApplicationShell> {
  int selectedIndex = 0;
  bool medicationFormOpen = false;
  bool loading = true;
  String? loadError;

  final List<Medication> medications = [];

  @override
  void initState() {
    super.initState();
    refreshMedications();
  }

  Future<void> refreshMedications() async {
    try {
      final loaded = await MedicationService.load();
      if (!mounted) return;
      setState(() {
        final handled = {for (final m in medications) m.id: m};
        medications
          ..clear()
          ..addAll([
            for (final m in loaded)
              m.copyWith(
                lastTakenDoseAt: handled[m.id]?.lastTakenDoseAt,
                lastSkippedDoseAt: handled[m.id]?.lastSkippedDoseAt,
              ),
          ]);
        loading = false;
        loadError = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        loadError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DueDoseWatcher(
      child: PopScope(
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
                loading: loading,
                loadError: loadError,
                onRefresh: refreshMedications,
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
      ),
    );
  }

  void selectTab(int index) {
    setState(() => selectedIndex = index);
    if (index == 0 || index == 1) refreshMedications();
  }

  Future<String> markMedicationTaken(
    Medication medication,
    DateTime scheduledAt,
  ) async {
    try {
      final due = await DoseService.due();
      final matches = due.where((d) => d.medicationId == medication.id);
      if (matches.isEmpty) {
        return 'This dose is not due yet. You will be reminded when it is time.';
      }
      await DoseService.markTaken(matches.first.id);
      final index = medications.indexWhere((m) => m.id == medication.id);
      if (index != -1 && mounted) {
        setState(
          () => medications[index] = medications[index].copyWith(
            lastTakenDoseAt: scheduledAt,
          ),
        );
      }
      return 'Thanks. Your dose has been recorded.';
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<void> addMedication(Medication medication) async {
    await MedicationService.create(medication);
    await refreshMedications();
  }

  Future<void> updateMedication(Medication previous, Medication updated) async {
    await MedicationService.update(previous, updated);
    await refreshMedications();
  }

  Future<void> removeMedication(Medication medication) async {
    await MedicationService.remove(medication);
    await refreshMedications();
  }
}