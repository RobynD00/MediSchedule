import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/screens/medications/medication_form.dart';
import 'package:medischedule/screens/medications/medication_list.dart';
import 'package:medischedule/screens/medications/medication.dart';

// Screen for viewing and managing a list of medications, including adding, editing, and removing medication reminders.
class MedicationScreen extends StatefulWidget {
  // The list of medications to display and manage on this screen.
  final List<Medication> medications;
  // Callback function that is called when a new medication is added. It takes a Medication object as an argument.
  final ValueChanged<Medication> onAddMedication;
  // Callback function that is called when an existing medication is updated. It takes two Medication objects as arguments: the previous medication and the updated medication.
  final void Function(Medication, Medication) onUpdateMedication;
  // Callback function that is called when a medication is removed. It takes a Medication object as an argument.
  final ValueChanged<Medication> onRemoveMedication;
  // Callback function that is called when the visibility of the medication form changes. It takes a boolean value indicating whether the form is open (true) or closed (false).
  final ValueChanged<bool> onMedicationFormVisibilityChanged;

  // Creates a new MedicationScreen with the given medication data and callbacks for adding, updating, and removing medications.
  const MedicationScreen({
    required this.medications,
    required this.onAddMedication,
    required this.onUpdateMedication,
    required this.onRemoveMedication,
    required this.onMedicationFormVisibilityChanged,
    super.key,
  });
  // Creates the state for the MedicationScreen, which manages the UI and interactions for viewing and managing medications.
  @override
  State<MedicationScreen> createState() => MedicationScreenState();
}

// The _MedicationScreenState class manages the state and behavior of the MedicationScreen, including displaying the list of medications, handling user interactions for adding, editing, and removing medications, and managing the visibility of the medication form. It also handles form validation and user input for medication details.
class MedicationScreenState extends State<MedicationScreen> {
  // Allow split UI extensions to request a rebuild through this State class.
  String query = '';
  Medication? editingMedication;
  DateTime startDate = DateTime.now();
  String frequency = frequencies.first;
  TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
  bool get isEditing => editingMedication != null;
  bool medicationFormIsOpen = false;

  final formKey = GlobalKey<FormState>();
  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final doseController = TextEditingController();
  final notesController = TextEditingController();
  // These labels are shared with Medication.nextDoseAt's supported schedules.
  static const frequencies = [
    'Daily',
    'Every other day',
    'Weekly',
    'As needed',
  ];

  // Disposes of the controllers used for managing user input in the medication form, ensuring that resources are released when the state object is removed from the widget tree. This prevents memory leaks and ensures proper cleanup of resources associated with the text controllers.
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
    // If a medication is provided, the form is populated with its details for editing; otherwise, the form is initialized with default values for adding a new medication. The form visibility state is updated accordingly.
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

  // Saves the medication details entered in the form, either adding a new medication or updating an existing one based on the current editing state. The method validates the form, constructs a Medication object with the input values, and triggers the appropriate callback to add or update the medication in the list. Feedback is provided to the user upon successful saving of the medication.
  void saveMedication() {
    // Validate the form fields and return early if any required fields are empty or invalid. This ensures that the medication details are complete and valid before proceeding with saving the medication.
    if (!formKey.currentState!.validate()) return;
    // Construct a new Medication object with the input values from the form, including name, dose, start date, frequency, time, notes, and icon. If editing an existing medication, retain its last taken and skipped dose timestamps.
    final medication = Medication(
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
    // Determine whether we are adding a new medication or updating an existing one, and call the appropriate callback function. Provide feedback to the user indicating whether the medication was added or updated successfully.
    final previous = editingMedication;
    if (previous == null) {
      widget.onAddMedication(medication);
      showApplicationFeedback(context, '${medication.name} added.');
    } else {
      widget.onUpdateMedication(previous, medication);
      showApplicationFeedback(context, '${medication.name} updated.');
    }
    // Close the form and reset the form state after saving the medication, ensuring that the input fields are cleared and the editing state is reset. The form visibility state is updated accordingly, and focus is removed from any active input fields to dismiss the keyboard.
    FocusScope.of(context).unfocus();

    setState(() {
      medicationFormIsOpen = false;
      editingMedication = null;
      query = '';
      searchController.clear();
    });
    // The onMedicationFormVisibilityChanged callback is called with false to indicate that the form is no longer visible, allowing the parent widget to update its state accordingly.
    widget.onMedicationFormVisibilityChanged(false);
  }

  // Removes a medication from the list after confirming with the user. Displays a confirmation dialog to ensure that the user intends to remove the medication, preventing accidental deletions. If confirmed, the medication is removed using the onRemoveMedication callback, and feedback is provided to the user indicating that the medication has been removed.
  Future<void> removeMedication(Medication medication) async {
    // Confirm before deleting so an accidental tap does not remove a schedule.
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
    // If the user cancels the removal or the widget is no longer mounted, return early without removing the medication.
    if (shouldRemove != true || !mounted) return;
    // Call the onRemoveMedication callback to remove the medication from the list and provide feedback to the user indicating that the medication has been removed.
    widget.onRemoveMedication(medication);
    // Show feedback to the user that the medication has been successfully removed from the list.
    showApplicationFeedback(context, '${medication.name} removed.');
  }

  // Closes the medication form and resets the form state, including clearing the input fields and resetting the editing medication. The form visibility state is updated accordingly, and focus is removed from any active input fields to dismiss the keyboard.
  void closeMedicationForm() {
    FocusScope.of(context).unfocus();
    setState(() {
      medicationFormIsOpen = false;
      editingMedication = null;
    });
    // The onMedicationFormVisibilityChanged callback is called with false to indicate that the form is no longer visible, allowing the parent widget to update its state accordingly.
    widget.onMedicationFormVisibilityChanged(false);
  }

  // Parses a time string in the format "hh:mm AM/PM" and returns a TimeOfDay object representing the parsed time. If the input string is invalid or does not match the expected format, a default time of 9:00 AM is returned. This method is used to convert user input or stored time values into a TimeOfDay object for use in the medication scheduling logic.
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
