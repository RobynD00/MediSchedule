import 'package:flutter/material.dart';

// Shared action button. Supports primary/secondary styles and loading states.
class ApplicationButtonWidget extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final bool expanded;
  // Disables the button and displays a progress indicator during an operation.
  final bool isLoading;

  const ApplicationButtonWidget({
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
    this.expanded = true,
    this.isLoading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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

  Widget get _content {
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
      children: [Icon(icon, size: 20), const SizedBox(width: 10), Text(label)],
    );
  }
}

// Shared form input using the global theme and optional validation.
class ApplicationTextFieldWidget extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final String? hint;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  const ApplicationTextFieldWidget({
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
  Widget build(BuildContext context) {
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
class ApplicationSectionHeadingWidget extends StatelessWidget {
  final String title;
  final Widget? action;

  const ApplicationSectionHeadingWidget(this.title, {this.action, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action case final actionWidget?) actionWidget,
      ],
    );
  }
}

// Shared card container. Prefer this over directly styling Card on each screen.
class ApplicationCardWidget extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const ApplicationCardWidget({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: padding, child: child),
    );
  }
}

// Inline status banner;
class ApplicationFeedbackBannerWidget extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool isError;

  const ApplicationFeedbackBannerWidget({
    required this.message,
    this.icon = Icons.info_outline,
    this.isError = false,
    super.key,
  });

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

// Reusable loading state for a screen or section.
class ApplicationLoadingWidget extends StatelessWidget {
  final String message;

  const ApplicationLoadingWidget({this.message = 'Loading...', super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

// Reusable error state with an optional retry action.
class ApplicationErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ApplicationErrorWidget({
    required this.message,
    this.onRetry,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Displays a temporary SnackBar for lightweight UI feedback.
void showApplicationFeedback(
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
