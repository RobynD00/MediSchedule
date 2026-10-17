// Reusable form validators for MediSchedule.
class ApplicationValidators {
  ApplicationValidators._();

  // Ensures that a field is not empty.
  static String? requiredField(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    return null;
  }

  // Checks that an email address has a valid format.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  // Checks the phone number formatting and length.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }

    final phone = value.trim();
    if (!RegExp(r'^\+?[0-9 ()-]+$').hasMatch(phone)) {
      return 'Enter a valid phone number.';
    }

    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Phone number must contain 7 to 15 digits.';
    }
    return null;
  }

  // Ensures the confirmation password matches the original password.
  static String? passwordMatch(String? confirmation, String password) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Please confirm your password.';
    }

    if (confirmation != password) {
      return 'Passwords do not match.';
    }
    return null;
  }
}
