import 'package:flutter/material.dart';
import '../../core/widgets/application_widget.dart';
import 'medication.dart';

// Screen for viewing and managing a list of medications, including adding, editing, and removing medication reminders.
class MedicationScreen extends StatefulWidget 
{
  // The list of medications to display and manage on this screen.
  final List<Medication> medications;
  // Callback function that is called when a new medication is added. It takes a Medication object as an argument.
  final ValueChanged<Medication> onAddMedication;
  // Callback function that is called when an existing medication is updated. It takes two Medication objects as arguments: the previous medication and the updated medication.
  final void Function(Medication, Medication) onUpdateMedication;
  // Callback function that is called when a medication is removed. It takes a Medication object as an argument.
  final ValueChanged<Medication> onRemoveMedication;
  // Callback function that is called when the visibility of the medication form changes. It takes a boolean value indicating whether the form is open (true) or closed (false).
  final ValueChanged<bool> onFormVisibilityChanged;

  // Creates a new MedicationScreen with the given medication data and callbacks for adding, updating, and removing medications.
  const MedicationScreen({
    required this.medications,
    required this.onAddMedication,
    required this.onUpdateMedication,
    required this.onRemoveMedication,
    required this.onFormVisibilityChanged,
    super.key,
  });
  // Creates the state for the MedicationScreen, which manages the UI and interactions for viewing and managing medications.
  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}
// The _MedicationScreenState class manages the state and behavior of the MedicationScreen, including displaying the list of medications, handling user interactions for adding, editing, and removing medications, and managing the visibility of the medication form. It also handles form validation and user input for medication details.
class _MedicationScreenState extends State<MedicationScreen> 
{
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _notesController = TextEditingController();
  // These labels are shared with Medication.nextDoseAt's supported schedules.
  static const _frequencies = [
    'Daily',
    'Every other day',
    'Weekly',
    'As needed',
  ];
  
  String _query = '';
  Medication? _editingMedication;
  DateTime _startDate = DateTime.now();
  String _frequency = _frequencies.first;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool get _isEditing => _editingMedication != null;
  // Disposes of the controllers used for managing user input in the medication form, ensuring that resources are released when the state object is removed from the widget tree. This prevents memory leaks and ensures proper cleanup of resources associated with the text controllers.
  @override
  void dispose() 
  {
    _searchController.dispose();
    _nameController.dispose();
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  // Validates that a form field is not empty. Returns an error message if the value is null or empty; otherwise, returns null to indicate that the field is valid.
  @override
  Widget build(BuildContext context) 
  {
    if (_formIsOpen) return _buildMedicationForm(context);
    return _buildMedicationList(context);
  }
  // Validates that a form field is not empty. Returns an error message if the value is null or empty; otherwise, returns null to indicate that the field is valid.
  bool _formIsOpen = false;
  // Builds the UI for displaying the list of medications, including a search field, medication cards, and an "Add medication" button. The list is filtered based on the user's search query, and appropriate feedback is shown when there are no medications or no matches for the search.
  Widget _buildMedicationList(BuildContext context) 
  {
    // Normalize the query once rather than once for every medication.
    final normalizedQuery = _query.toLowerCase();
    final visibleMedications = widget.medications
        .where(
          (medication) =>
              medication.name.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
    // Sort the visible medications by their next scheduled dose time, with medications that have no upcoming doses placed at the end of the list.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'My Medications',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Your medication schedules.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: 'Find a medication',
                controller: _searchController,
                prefixIcon: Icons.search,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 20),
              AppSectionHeading('${visibleMedications.length} medications'),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        // Show a feedback banner when there are no medications or no matches for the search query, providing appropriate messages and icons based on the situation.
        if (visibleMedications.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverToBoxAdapter(
              child: AppFeedbackBanner(
                message: widget.medications.isEmpty
                    ? 'No medications added yet.'
                    : 'No medications match your search.',
                icon: widget.medications.isEmpty
                    ? Icons.medication_outlined
                    : Icons.search_off,
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) return const SizedBox(height: 12);
                return _buildMedicationCard(
                  context,
                  visibleMedications[index ~/ 2],
                );
              }, childCount: visibleMedications.length * 2 - 1),
            ),
          ),
          
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AppButton(
                label: 'Create Reminder',
                icon: Icons.add,
                onPressed: () => _openForm(),
              ),
            ]),
          ),
        ),
      ],
    );
  }
  // Builds a card widget for displaying a single medication's details, including its name, dose, schedule, and action buttons for editing or removing the medication. The card is styled with a CircleAvatar for the medication icon and provides a user-friendly interface for managing individual medications.
  Widget _buildMedicationCard(BuildContext context, Medication medication) 
  {
    final colorScheme = Theme.of(context).colorScheme;
    // The medication card displays the medication's name, dose, and schedule, along with action buttons for editing and removing the medication. It uses a CircleAvatar to show the medication's icon and provides a visually appealing layout for managing individual medications in the list.
    return AppCard
    (
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          CircleAvatar
          (
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Icon(medication.icon),
          ),
          // The medication details are displayed in a column, including the medication's name, dose, and schedule. The name is styled as a title, while the dose and schedule are shown as a subtitle. This layout provides clear information about the medication at a glance.
          const SizedBox(width: 14),
          Expanded
          (
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.dose} · ${medication.schedule}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // The action buttons for editing and removing the medication are placed at the end of the card, allowing users to easily manage their medications. The edit button opens the medication form with the selected medication's details pre-filled, while the remove button prompts the user for confirmation before deleting the medication from the list.
          IconButton
          (
            tooltip: 'Edit ${medication.name}',
            onPressed: () => _openForm(medication),
            icon: const Icon(Icons.edit_outlined),
          ),
          // The remove button allows users to delete a medication from their list. When pressed, it triggers a confirmation dialog to ensure that the user intends to remove the medication, preventing accidental deletions. If confirmed, the medication is removed, and feedback is provided to the user.
          IconButton
          (
            tooltip: 'Remove ${medication.name}',
            onPressed: () => _removeMedication(medication),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
  // Opens the medication form for adding a new medication or editing an existing one. If a medication is provided, the form is populated with its details for editing; otherwise, the form is initialized with default values for adding a new medication. The form visibility state is updated accordingly.
  Widget _buildMedicationForm(BuildContext context) 
  {
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = MaterialLocalizations.of(context)
        .formatMediumDate(_startDate);
    // The medication form allows users to input details for a new medication or edit an existing one. It includes fields for the medication name, dose, start date, frequency, first dose time, and notes. The form is validated to ensure that required fields are filled out before saving the medication. Upon saving, the appropriate callback is triggered to add or update the medication in the list, and feedback is provided to the user.
    return Form
    (
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row
          (
            children: [
              IconButton(
                tooltip: 'Back to Medications',
                onPressed: _closeForm,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                _isEditing ? 'Edit Reminder' : 'Add Reminder',
                style: textTheme.headlineSmall,
              ),
            ],
          ),
          // The medication form includes input fields for the medication name, dose, start date, frequency, first dose time, and notes. Each field is accompanied by appropriate labels and icons to guide the user in providing the necessary information. The form also includes validation to ensure that required fields are filled out before saving the medication.
          const SizedBox(height: 12),
          TextFormField
          (
            key: const ValueKey('medication-name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Medication Name'),
            validator: _requiredField,
          ),

          const SizedBox(height: 16),
          const _PhotoPlaceholder(),
          const SizedBox(height: 20),
          // The medication form includes a section for selecting the start date and frequency of the medication schedule. Users can tap on the respective fields to open date and frequency pickers, allowing them to customize their medication schedule according to their needs. The selected values are displayed in the form for easy reference.
          Row
          (
            children: [
              Expanded(
                child: _ReminderPickerTile(
                  title: 'Start Date',
                  value: formattedDate,
                  icon: Icons.calendar_month_outlined,
                  onTap: _selectStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReminderPickerTile(
                  title: 'Frequency',
                  value: _frequency,
                  icon: Icons.alarm_outlined,
                  onTap: _selectFrequency,
                ),
              ),
            ],
          ),
          // The medication form includes input fields for the dose amount and first dose time. Users can enter the dose amount in a text field and select the first dose time using a time picker. The selected values are displayed in the form, allowing users to easily manage their medication schedule.
          const SizedBox(height: 12),
          Row
          (
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('medication-dose'),
                  controller: _doseController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Dose Amount',
                    hintText: 'e.g. 1 tablet or 2 capsules',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: _requiredField,
                ),
              ),

              const SizedBox(width: 12),
              Expanded
              (
                child: _ReminderPickerTile(
                  title: 'First Dose Time',
                  value: _time.format(context),
                  icon: Icons.access_time,
                  onTap: _selectTime,
                ),
              ),
            ],
          ),
          // The medication form includes a notes section where users can add any additional information or instructions related to the medication. This section is implemented as a multi-line text field, allowing users to provide detailed notes about their medication regimen. The notes are saved along with the other medication details when the user submits the form.
          const SizedBox(height: 16),
          TextFormField
          (
            key: const ValueKey('medication-notes'),
            controller: _notesController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          // The "Save changes" or "Save Reminder" button is displayed at the bottom of the medication form, allowing users to submit their input and save the medication details. When pressed, the button triggers the _saveMedication method, which validates the form and either adds a new medication or updates an existing one based on the user's input. Feedback is provided to the user upon successful saving of the medication.
          const SizedBox(height: 20),
          AppButton
          (
            label: _isEditing ? 'Save Changes' : 'Save Reminder',
            icon: Icons.check,
            onPressed: _saveMedication,
          ),
        ],
      ),
    );
  }
  // Validates that a form field is not empty. Returns an error message if the value is null or empty; otherwise, returns null to indicate that the field is valid.
  void _openForm([Medication? medication]) 
  {
    // If a medication is provided, the form is populated with its details for editing; otherwise, the form is initialized with default values for adding a new medication. The form visibility state is updated accordingly.
    setState(() 
    {
      _editingMedication = medication;
      _formIsOpen = true;
      _nameController.text = medication?.name ?? '';
      _doseController.text = medication?.dose ?? '';
      _notesController.text = medication?.notes ?? '';
      _startDate = medication?.startDate ?? DateTime.now();
      _frequency = medication?.frequency ?? _frequencies.first;
      _time = medication == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : medication.timeHour != null && medication.timeMinute != null
          ? TimeOfDay(
              hour: medication.timeHour!,
              minute: medication.timeMinute!,
            )
          : _parseTime(medication.time);
    });
    widget.onFormVisibilityChanged(true);
  }
  // Closes the medication form and resets the form state, including clearing the input fields and resetting the editing medication. The form visibility state is updated accordingly, and focus is removed from any active input fields to dismiss the keyboard.
  void _closeForm() 
  {
    FocusScope.of(context).unfocus();
    setState(() {
      _formIsOpen = false;
      _editingMedication = null;
    });
    // The onFormVisibilityChanged callback is called with false to indicate that the form is no longer visible, allowing the parent widget to update its state accordingly.
    widget.onFormVisibilityChanged(false);
  }
  // Saves the medication details entered in the form, either adding a new medication or updating an existing one based on the current editing state. The method validates the form, constructs a Medication object with the input values, and triggers the appropriate callback to add or update the medication in the list. Feedback is provided to the user upon successful saving of the medication.
  void _saveMedication() 
  {
    // Validate the form fields and return early if any required fields are empty or invalid. This ensures that the medication details are complete and valid before proceeding with saving the medication.
    if (!_formKey.currentState!.validate()) return;
    // Construct a new Medication object with the input values from the form, including name, dose, start date, frequency, time, notes, and icon. If editing an existing medication, retain its last taken and skipped dose timestamps.
    final medication = Medication(
      name: _nameController.text.trim(),
      dose: _doseController.text.trim(),
      startDate: _startDate,
      frequency: _frequency,
      time: _time.format(context),
      notes: _notesController.text.trim(),
      icon: _editingMedication?.icon ?? Icons.medication_outlined,
      lastTakenDoseAt: _editingMedication?.lastTakenDoseAt,
      lastSkippedDoseAt: _editingMedication?.lastSkippedDoseAt,
      timeHour: _time.hour,
      timeMinute: _time.minute,
    );
    // Determine whether we are adding a new medication or updating an existing one, and call the appropriate callback function. Provide feedback to the user indicating whether the medication was added or updated successfully.
    final previous = _editingMedication;
    if (previous == null) 
    {
      widget.onAddMedication(medication);
      showAppFeedback(context, '${medication.name} added.');
    } 
    else 
    {
      widget.onUpdateMedication(previous, medication);
      showAppFeedback(context, '${medication.name} updated.');
    }
    // Close the form and reset the form state after saving the medication, ensuring that the input fields are cleared and the editing state is reset. The form visibility state is updated accordingly, and focus is removed from any active input fields to dismiss the keyboard.
    FocusScope.of(context).unfocus();

    setState(() 
    {
      _formIsOpen = false;
      _editingMedication = null;
      _query = '';
      _searchController.clear();
    });
    // The onFormVisibilityChanged callback is called with false to indicate that the form is no longer visible, allowing the parent widget to update its state accordingly.
    widget.onFormVisibilityChanged(false);
  }
  // Validates that a form field is not empty. Returns an error message if the value is null or empty; otherwise, returns null to indicate that the field is valid.
  Future<void> _selectStartDate() async 
  {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    // If the user cancels the date picker or the widget is no longer mounted, return early without making any changes to the start date.
    if (selectedDate == null || !mounted) return;
    setState(() => _startDate = selectedDate);
  }
  // Validates that a form field is not empty. Returns an error message if the value is null or empty; otherwise, returns null to indicate that the field is valid.
  Future<void> _selectTime() async 
  {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    // If the user cancels the time picker or the widget is no longer mounted, return early without making any changes to the selected time.
    if (selectedTime == null || !mounted) return;
    setState(() => _time = selectedTime);
  }
  // Validates that a form field is not empty. Returns an error message if the value is null or empty; otherwise, returns null to indicate that the field is valid.
  Future<void> _selectFrequency() async 
  {
    // Offer common schedules plus the existing custom schedule, if any.
    final selectedFrequency = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final frequency in {
              ..._frequencies,
              if (_frequency.startsWith('Every ') &&
                  !_frequencies.contains(_frequency))
                _frequency,
            })
              ListTile(
                title: Text(frequency),
                trailing: frequency == _frequency
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(frequency),
              ),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Custom interval…'),
              onTap: () => Navigator.of(context).pop('custom'),
            ),
          ],
        ),
      ),
    );
    // If the user cancels the frequency selection or the widget is no longer mounted, return early without making any changes to the selected frequency.
    if (selectedFrequency == null || !mounted) return;
    // If the user selects a custom interval, prompt them to enter the number of hours between doses. If the user cancels or enters an invalid value, return early without making any changes to the selected frequency.
    if (selectedFrequency == 'custom') 
    {
      final intervalHours = await _askForIntervalHours();
      // If the user cancels the custom interval input or the widget is no longer mounted, return early without making any changes to the selected frequency.
      if (intervalHours == null || !mounted) return;
      // Update the selected frequency to reflect the custom interval entered by the user, displaying it in a user-friendly format (e.g., "Every 3 hours"). The state is updated to reflect the new frequency selection.
      setState(() 
      {
        _frequency = intervalHours == 1
            ? 'Every Hour'
            : 'Every $intervalHours hours';
      });
      return;
    }
    setState(() => _frequency = selectedFrequency);
  }
  // Prompts the user to enter a custom interval in hours for medication dosing. Displays a dialog with a text field for input and validates that the entered value is a whole number between 1 and 24. Returns the entered interval as an integer if valid, or null if the user cancels or enters an invalid value.
  Future<int?> _askForIntervalHours() async 
  {
    return showDialog<int>(
      context: context,
      builder: (context) => const _IntervalHoursDialog(),
    );
  }
  // Removes a medication from the list after confirming with the user. Displays a confirmation dialog to ensure that the user intends to remove the medication, preventing accidental deletions. If confirmed, the medication is removed using the onRemoveMedication callback, and feedback is provided to the user indicating that the medication has been removed.
  Future<void> _removeMedication(Medication medication) async 
  {
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
    showAppFeedback(context, '${medication.name} removed.');
  }
  // Parses a time string in the format "hh:mm AM/PM" and returns a TimeOfDay object representing the parsed time. If the input string is invalid or does not match the expected format, a default time of 9:00 AM is returned. This method is used to convert user input or stored time values into a TimeOfDay object for use in the medication scheduling logic.
  TimeOfDay _parseTime(String value) 
  {
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$').firstMatch(value);
    if (match == null) return const TimeOfDay(hour: 9, minute: 0);

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (match.group(3) == 'PM' && hour != 12) hour += 12;
    if (match.group(3) == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
// A placeholder widget that displays an icon indicating that the user can add a photo. This widget is used in the medication form to represent the area where a photo of the medication can be added. It is styled with a border and background color to visually indicate its purpose.
class _PhotoPlaceholder extends StatelessWidget 
{
  const _PhotoPlaceholder();
  // Builds the UI for the photo placeholder, including a container with a border and background color, and an icon indicating that the user can add a photo. The placeholder is sized to 112x112 pixels and has rounded corners for a visually appealing appearance.
  @override
  Widget build(BuildContext context) 
  {
    final colorScheme = Theme.of(context).colorScheme;
    // The photo placeholder is a container with a border and background color, indicating that the user can add a photo of the medication. It includes an icon to visually represent the action of adding a photo, providing a clear and intuitive interface for users to interact with.
    return Container
    (
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.add_a_photo_outlined,
        size: 32,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
// A dialog widget that prompts the user to enter a custom interval in hours for medication dosing. It includes a text field for input, validation to ensure the entered value is a whole number between 1 and 24, and buttons for canceling or submitting the input. The dialog returns the entered interval as an integer if valid, or null if the user cancels or enters an invalid value.
class _IntervalHoursDialog extends StatefulWidget 
{
  const _IntervalHoursDialog();
  // Creates the state for the _IntervalHoursDialog, which manages the UI and interactions for entering a custom interval in hours for medication dosing.
  @override
  State<_IntervalHoursDialog> createState() => _IntervalHoursDialogState();
}
// The _IntervalHoursDialogState class manages the state and behavior of the _IntervalHoursDialog, including handling user input for the custom interval, validating the input, and returning the entered value to the parent widget. It ensures that the user enters a valid whole number between 1 and 24 for the interval in hours.
class _IntervalHoursDialogState extends State<_IntervalHoursDialog> 
{
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  // Disposes of the controller used for managing user input in the interval hours dialog, ensuring that resources are released when the state object is removed from the widget tree. This prevents memory leaks and ensures proper cleanup of resources associated with the text controller.
  @override
  void dispose() 
  {
    _controller.dispose();
    super.dispose();
  }
  // Builds the UI for the interval hours dialog, including a form with a text field for entering the number of hours between doses, validation to ensure the input is a whole number between 1 and 24, and buttons for canceling or submitting the input. The dialog returns the entered interval as an integer if valid, or null if the user cancels or enters an invalid value.
  @override
  Widget build(BuildContext context) 
  {
    // The interval hours dialog prompts the user to enter a custom interval in hours for medication dosing. It includes a form with a text field for input, validation to ensure the entered value is a whole number between 1 and 24, and buttons for canceling or submitting the input. The dialog returns the entered interval as an integer if valid, or null if the user cancels or enters an invalid value.
    return AlertDialog
    (
      title: const Text('Custom interval'),
      content: Form
      (
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Hours Between Doses',
            hintText: 'Enter 1 to 24',
          ),
          validator: (value) {
            final hours = int.tryParse(value?.trim() ?? '');
            if (hours == null || hours < 1 || hours > 24) {
              return 'Enter a number from 1 to 24.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton
        (
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Set interval')),
      ],
    );
  }
  // Validates the form and submits the entered interval hours if valid. If the form is valid, it pops the dialog and returns the entered interval as an integer to the parent widget. If the form is invalid, it does not submit and allows the user to correct their input.
  void _submit() 
  {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(int.parse(_controller.text.trim()));
  }
}
// A tile widget that displays a title, value, and icon, and allows the user to tap on it to trigger an action. It is used in the medication form for selecting start date, frequency, and first dose time. The tile is styled as an outlined button with appropriate padding and rounded corners.
class _ReminderPickerTile extends StatelessWidget 
{
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  // Creates a _ReminderPickerTile with the specified title, value, icon, and onTap callback. The tile displays the title and value, along with an icon indicating that it can be tapped to trigger an action. The onTap callback is called when the tile is pressed.
  const _ReminderPickerTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
  });
  // Builds the UI for the reminder picker tile, including an outlined button with a title, value, and icon. The tile is styled with appropriate padding and rounded corners, and it triggers the onTap callback when pressed. It is used in the medication form for selecting start date, frequency, and first dose time.
  @override
  Widget build(BuildContext context) 
  {
    final textTheme = Theme.of(context).textTheme;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium,
                ),
              ),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String? _requiredField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}
