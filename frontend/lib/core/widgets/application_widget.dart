import 'package:flutter/material.dart';

// Shared card container. Prefer this over directly styling Card on each screen.
class AppCard extends StatelessWidget 
{
  const AppCard({required this.child, this.padding = const EdgeInsets.all(20), super.key});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) 
  {
    return Card(
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
// Shared action button. Supports primary/secondary styles and loading states.
class AppButton extends StatelessWidget 
{
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool expanded;
  // Disables the button and displays a progress indicator during an operation.
  final bool isLoading;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.expanded = true,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) 
  {
    final button = secondary
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: _content,
          )
        : FilledButton(
            onPressed: isLoading ? null : onPressed,
            child: _content,
          );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget get _content 
  {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(label),
      ],
    );
  }
}
// Shared form input using the global theme and optional validation.
class AppTextField extends StatelessWidget 
{
  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? hint;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    required this.label,
    this.controller,
    this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.hint,
    this.obscureText = false,
    this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) 
  {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      ),
    );
  }
}
// Consistent section title with an optional trailing action.
class AppSectionHeading extends StatelessWidget 
{
  const AppSectionHeading(this.title, {this.action, super.key});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) 
  {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?action,
      ],
    );
  }
}
// Inline status banner;
class AppFeedbackBanner extends StatelessWidget 
{
  const AppFeedbackBanner({
    required this.message,
    this.icon = Icons.info_outline,
    this.isError = false,
    super.key,
  });

  final String message;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foregroundColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// Displays a temporary SnackBar for lightweight UI feedback.
void showAppFeedback
(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : colorScheme.primary,
        content: Text(
          message,
          style: TextStyle(
            color: isError ? colorScheme.onError : colorScheme.onPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
}
