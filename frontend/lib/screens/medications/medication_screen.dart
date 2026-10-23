import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/screens/medications/medication_form.dart';
import 'package:medischedule/screens/medications/medication_list.dart';
import 'package:medischedule/screens/medications/medication.dart';
import 'package:medischedule/screens/reminders/reminder_schedule_screen.dart';
import 'package:medischedule/services/api_client.dart';

class MedicationScreen extends StatefulWidget {
  final List<Medication> medications;
  final Future<void> Function(Medication) onAddMedication;
  final Future<void> Function(Medication, Medication) onUpdateMedication;
  final Future<void> Function(Medication) onRemoveMedication;
  final ValueChanged<bool> onMedicationFormVisibilityChanged;
  final Future<void> Function() onRefresh;
  final bool loading;
  final String? loadError;

  const MedicationScreen({
    required this.medications,
    required this.onAddMedication,
    required this.onUpdateMedication,
    required this.onRemoveMedication,
    required this.onMedicationFormVisibilityChanged,
    required this.onRefresh,
    this.loading = false,
    this.loadError,
    super.key,
  });
  @override
  State<MedicationScreen> createState() => MedicationScreenState();
}

class MedicationScreenState extends State<MedicationScreen> {
  String query = '';
  Medication? editingMedication;
  DateTime startDate = DateTime.now();
  String frequency = frequencies.first;
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  bool get isEditing => editingMedication != null;
  bool medicationFormIsOpen = false;
  bool saving = false;

  final formKey = GlobalKey<FormState>();
  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final doseController = TextEditingController();
  final notesController = TextEditingController();
  static const frequencies = [
    'Daily',
    'Weekly',
    'As needed',
  ];

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    doseController.dispose();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (medicationFormIsOpen) return buildMedicationForm(context);
    return buildMedicationList(context);
  }

  void openMedicationForm([Medication? medication]) {
    setState(() {
      editingMedication = medication;
      medicationFormIsOpen = true;
      nameController.text = medication?.name ?? '';
      doseController.text = medication?.dose ?? '';
      notesController.text = medication?.notes ?? '';
      startDate = medication?.startDate ?? DateTime.now();
      frequency = medication?.frequency ?? frequencies.first;
      time = medication == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : medication.timeHour != null && medication.timeMinute != null
          ? TimeOfDay(
              hour: medication.timeHour!,
              minute: medication.timeMinute!,
            )
          : parseTime(medication.time);
    });
    widget.onMedicationFormVisibilityChanged(true);
  }

  void updateMedicationFormState(VoidCallback update) {
    setState(update);
  }

  Future<void> saveMedication() async {
    if (saving || !formKey.currentState!.validate()) return;
    final medication = Medication(
      id: editingMedication?.id,
      name: nameController.text.trim(),
      dose: doseController.text.trim(),
      startDate: startDate,
      frequency: frequency,
      time: time.format(context),
      notes: notesController.text.trim(),
      icon: editingMedication?.icon ?? Icons.medication_outlined,
      lastTakenDoseAt: editingMedication?.lastTakenDoseAt,
      lastSkippedDoseAt: editingMedication?.lastSkippedDoseAt,
      timeHour: time.hour,
      timeMinute: time.minute,
    );
    final previous = editingMedication;
    setState(() => saving = true);
    try {
      if (previous == null) {
        await widget.onAddMedication(medication);
      } else {
        await widget.onUpdateMedication(previous, medication);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => saving = false);
      showApplicationFeedback(context, e.message, isError: true);
      return;
    }
    if (!mounted) return;
    showApplicationFeedback(
      context,
      previous == null
          ? '${medication.name} added.'
          : '${medication.name} updated.',
    );
    FocusScope.of(context).unfocus();

    setState(() {
      saving = false;
      medicationFormIsOpen = false;
      editingMedication = null;
      query = '';
      searchController.clear();
    });
    widget.onMedicationFormVisibilityChanged(false);
  }

  Future<void> removeMedication(Medication medication) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Medication?'),
        content: Text('${medication.name} will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (shouldRemove != true || !mounted) return;
    try {
      await widget.onRemoveMedication(medication);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApplicationFeedback(context, e.message, isError: true);
      return;
    }
    if (!mounted) return;
    showApplicationFeedback(context, '${medication.name} removed.');
  }

  void closeMedicationForm() {
    FocusScope.of(context).unfocus();
    setState(() {
      medicationFormIsOpen = false;
      editingMedication = null;
    });
    widget.onMedicationFormVisibilityChanged(false);
  }

  Future<void> openReminderSchedule(Medication medication) async {
    final id = medication.id;
    if (id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderScheduleScreen(
          medicationId: id,
          medicationName: medication.name,
        ),
      ),
    );
    if (!mounted) return;
    await widget.onRefresh();
  }

  TimeOfDay parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(value);
    if (match == null) return const TimeOfDay(hour: 9, minute: 0);

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (match.group(3) == 'PM' && hour != 12) hour += 12;
    if (match.group(3) == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}