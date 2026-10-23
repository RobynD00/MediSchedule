import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/screens/medications/medication_screen.dart';
import 'package:medischedule/screens/medications/medication_widget.dart';

extension MedicationForm on MedicationScreenState {
  Widget buildMedicationForm(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final formattedDate = MaterialLocalizations.of(context)
        .formatMediumDate(startDate);
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
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('medication-notes'),
            controller: notesController,
            textCapitalization: TextCapitalization.sentences,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          ApplicationButtonWidget(
            label: isEditing ? 'Save Changes' : 'Save Reminder',
            icon: Icons.check,
            isLoading: saving,
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
    if (selectedDate == null || !mounted) return;
    updateMedicationFormState(() => startDate = selectedDate);
  }

  Future<void> selectTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (selectedTime == null || !mounted) return;
    updateMedicationFormState(() => time = selectedTime);
  }

  Future<void> selectFrequency() async {
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
    if (selectedFrequency == null || !mounted) return;
    if (selectedFrequency == 'custom') {
      final intervalHours = await askForIntervalHours();
      if (intervalHours == null || !mounted) return;
      updateMedicationFormState(() {
        frequency = intervalHours == 1
            ? 'Every hour'
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