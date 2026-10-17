import 'package:flutter/material.dart';

// A placeholder widget that displays an icon indicating that the user can add a photo. This widget is used in the medication form to represent the area where a photo of the medication can be added. It is styled with a border and background color to visually indicate its purpose.
class PhotoPlaceholderWidget extends StatelessWidget {
  const PhotoPlaceholderWidget({super.key});
  // Builds the UI for the photo placeholder, including a container with a border and background color, and an icon indicating that the user can add a photo. The placeholder is sized to 112x112 pixels and has rounded corners for a visually appealing appearance.
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The photo placeholder is a container with a border and background color, indicating that the user can add a photo of the medication. It includes an icon to visually represent the action of adding a photo, providing a clear and intuitive interface for users to interact with.
    return Container(
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
class IntervalHoursDialogWidget extends StatefulWidget {
  const IntervalHoursDialogWidget({super.key});
  // Creates the state for the IntervalHoursDialogWidget, which manages the UI and interactions for entering a custom interval in hours for medication dosing.
  @override
  State<IntervalHoursDialogWidget> createState() => IntervalHoursDialogState();
}

// The IntervalHoursDialogState class manages the state and behavior of the IntervalHoursDialog, including handling user input for the custom interval, validating the input, and returning the entered value to the parent widget. It ensures that the user enters a valid whole number between 1 and 24 for the interval in hours.
class IntervalHoursDialogState extends State<IntervalHoursDialogWidget> {
  final formKey = GlobalKey<FormState>();
  final textEditingController = TextEditingController();

  // Disposes of the controller used for managing user input in the interval hours dialog, ensuring that resources are released when the state object is removed from the widget tree. This prevents memory leaks and ensures proper cleanup of resources associated with the text controller.
  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }

  // Builds the UI for the interval hours dialog, including a form with a text field for entering the number of hours between doses, validation to ensure the input is a whole number between 1 and 24, and buttons for canceling or submitting the input. The dialog returns the entered interval as an integer if valid, or null if the user cancels or enters an invalid value.
  @override
  Widget build(BuildContext context) {
    // The interval hours dialog prompts the user to enter a custom interval in hours for medication dosing. It includes a form with a text field for input, validation to ensure the entered value is a whole number between 1 and 24, and buttons for canceling or submitting the input. The dialog returns the entered interval as an integer if valid, or null if the user cancels or enters an invalid value.
    return AlertDialog(
      title: const Text('Custom interval'),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: textEditingController,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Set interval')),
      ],
    );
  }

  // Validates the form and submits the entered interval hours if valid. If the form is valid, it pops the dialog and returns the entered interval as an integer to the parent widget. If the form is invalid, it does not submit and allows the user to correct their input.
  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.of(context).pop(int.parse(textEditingController.text.trim()));
  }
}

// A tile widget that displays a title, value, and icon, and allows the user to tap on it to trigger an action. It is used in the medication form for selecting start date, frequency, and first dose time. The tile is styled as an outlined button with appropriate padding and rounded corners.
class ReminderPickerTileWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  // Creates a _ReminderPickerTile with the specified title, value, icon, and onTap callback. The tile displays the title and value, along with an icon indicating that it can be tapped to trigger an action. The onTap callback is called when the tile is pressed.
  const ReminderPickerTileWidget({
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    super.key,
  });
  // Builds the UI for the reminder picker tile, including an outlined button with a title, value, and icon. The tile is styled with appropriate padding and rounded corners, and it triggers the onTap callback when pressed. It is used in the medication form for selecting start date, frequency, and first dose time.
  @override
  Widget build(BuildContext context) {
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

String? requiredFieldValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'This field is required.';
  }
  return null;
}
