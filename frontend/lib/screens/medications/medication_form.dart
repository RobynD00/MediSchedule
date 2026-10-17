import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/screens/medications/medication_screen.dart';
import 'package:medischedule/screens/medications/medication_widget.dart';

extension MedicationForm on MedicationScreenState {
  Widget buildMedicationForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = MaterialLocalizations.of(context)
        .formatMediumDate(startDate);
    // The medication form allows users to input details for a new medication or edit an existing one. It includes fields for the medication name, dose, start date, frequency, first dose time, and notes. The form is validated to ensure that required fields are filled out before saving the medication. Upon saving, the appropriate callback is triggered to add or update the medication in the list, and feedback is provided to the user.
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back to Medications',
                onPressed: closeMedicationForm,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                isEditing ? 'Edit Reminder' : 'Add Reminder',
                style: textTheme.headlineSmall,
              ),
            ],
          ),
          // The medication form includes input fields for the medication name, dose, start date, frequency, first dose time, and notes. Each field is accompanied by appropriate labels and icons to guide the user in providing the necessary information. The form also includes validation to ensure that required fields are filled out before saving the medication.
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('medication-name'),
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Medication Name'),
            validator: requiredFieldValidator,
          ),

          const SizedBox(height: 16),
          const PhotoPlaceholderWidget(),
          const SizedBox(height: 20),
          // The medication form includes a section for selecting the start date and frequency of the medication schedule. Users can tap on the respective fields to open date and frequency pickers, allowing them to customize their medication schedule according to their needs. The selected values are displayed in the form for easy reference.
          Row(
            children: [
              Expanded(
                child: ReminderPickerTileWidget(
                  title: 'Start Date',
                  value: formattedDate,
                  icon: Icons.calendar_month_outlined,
                  onTap: selectStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ReminderPickerTileWidget(
                  title: 'Frequency',
                  value: frequency,
                  icon: Icons.alarm_outlined,
                  onTap: selectFrequency,
                ),
              ),
            ],
          ),
          // The medication form includes input fields for the dose amount and first dose time. Users can enter the dose amount in a text field and select the first dose time using a time picker. The selected values are displayed in the form, allowing users to easily manage their medication schedule.
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('medication-dose'),
                  controller: doseController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Dose Amount',
                    hintText: 'e.g. 1 tablet or 2 capsules',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                  validator: requiredFieldValidator,
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: ReminderPickerTileWidget(
                  title: 'First Dose Time',
                  value: time.format(context),
                  icon: Icons.access_time,
                  onTap: selectTime,
                ),
              ),
            ],
          ),
          // The medication form includes a notes section where users can add any additional information or instructions related to the medication. This section is implemented as a multi-line text field, allowing users to provide detailed notes about their medication regimen. The notes are saved along with the other medication details when the user submits the form.
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('medication-notes'),
            controller: notesController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          // The "Save changes" or "Save Reminder" button is displayed at the bottom of the medication form, allowing users to submit their input and save the medication details. When pressed, the button triggers the _saveMedication method, which validates the form and either adds a new medication or updates an existing one based on the user's input. Feedback is provided to the user upon successful saving of the medication.
          const SizedBox(height: 20),
          ApplicationButtonWidget(
            label: isEditing ? 'Save Changes' : 'Save Reminder',
            icon: Icons.check,
            onPressed: saveMedication,
          ),
        ],
      ),
    );
  }

  Future<void> selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    // If the user cancels the date picker or the widget is no longer mounted, return early without making any changes to the start date.
    if (selectedDate == null || !mounted) return;
    updateMedicationFormState(() => startDate = selectedDate);
  }

  Future<void> selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: time,
    );
    // If the user cancels the time picker or the widget is no longer mounted, return early without making any changes to the selected time.
    if (selectedTime == null || !mounted) return;
    updateMedicationFormState(() => time = selectedTime);
  }

  Future<void> selectFrequency() async {
    // Offer common schedules plus the existing custom schedule, if any.
    final selectedFrequency = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final frequency in {
              ...MedicationScreenState.frequencies,
              if (frequency.startsWith('Every ') &&
                  !MedicationScreenState.frequencies.contains(frequency))
                frequency,
            })
              ListTile(
                title: Text(frequency),
                trailing: frequency == frequency
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
    if (selectedFrequency == 'custom') {
      final intervalHours = await askForIntervalHours();
      // If the user cancels the custom interval input or the widget is no longer mounted, return early without making any changes to the selected frequency.
      if (intervalHours == null || !mounted) return;
      // Update the selected frequency to reflect the custom interval entered by the user, displaying it in a user-friendly format (e.g., "Every 3 hours"). The state is updated to reflect the new frequency selection.
      updateMedicationFormState(() {
        frequency = intervalHours == 1
            ? 'Every Hour'
            : 'Every $intervalHours hours';
      });
      return;
    }
    updateMedicationFormState(() => frequency = selectedFrequency);
  }

  Future<int?> askForIntervalHours() async {
    return showDialog<int>(
      context: context,
      builder: (context) => const IntervalHoursDialogWidget(),
    );
  }
}
