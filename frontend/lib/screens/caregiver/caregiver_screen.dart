import 'package:flutter/material.dart';
import 'package:medischedule/core/application_validators.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/models/caregiver_link.dart';
import 'package:medischedule/services/caregiver_service.dart';

// Elderly user: add, view and remove caregivers (UC13).
class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final contactController = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool consent = false;
  String? error;
  List<CaregiverLink> caregivers = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    nameController.dispose();
    contactController.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await CaregiverService.myCaregivers();
      if (!mounted) return;
      setState(() => caregivers = result);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> invite() async {
    if (!formKey.currentState!.validate()) return;
    // The patient must agree before anything is shared.
    if (!consent) {
      showApplicationFeedback(
        context,
        'Please agree to share your medication history first.',
        isError: true,
      );
      return;
    }
    setState(() => saving = true);
    try {
      await CaregiverService.invite(
        name: nameController.text.trim(),
        contact: contactController.text.trim(),
        canViewAdherence: consent,
      );
      if (!mounted) return;
      nameController.clear();
      contactController.clear();
      setState(() => consent = false);
      showApplicationFeedback(context, 'Invitation saved. They need to accept it in their app.');
      await load();
    } on Exception catch (e) {
      if (mounted) showApplicationFeedback(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> remove(CaregiverLink link) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${link.caregiverName}?'),
        content: const Text('They will no longer see your medication history or get alerts.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await CaregiverService.remove(link.id);
      if (!mounted) return;
      showApplicationFeedback(context, 'Caregiver removed.');
      await load();
    } on Exception catch (e) {
      if (mounted) showApplicationFeedback(context, e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My caregivers')),
      body: loading
          ? const ApplicationLoadingWidget()
          : error != null
          ? ApplicationErrorWidget(message: error!, onRetry: load)
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const ApplicationSectionHeadingWidget('Add a caregiver'),
                const SizedBox(height: 12),
                ApplicationCardWidget(
                  child: Form(
                    key: formKey,
                    child: Column(
                      children: [
                        ApplicationTextFieldWidget(
                          label: 'Their name',
                          controller: nameController,
                          prefixIcon: Icons.person_outline,
                          validator: (v) => ApplicationValidators.requiredField(v, fieldName: 'Name'),
                        ),
                        const SizedBox(height: 14),
                        ApplicationTextFieldWidget(
                          label: 'Their email or phone number',
                          controller: contactController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.alternate_email,
                          validator: (v) =>
                              ApplicationValidators.requiredField(v, fieldName: 'Email or phone'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Share my medication history with them'),
                          subtitle: const Text('They will be told if I miss a dose'),
                          value: consent,
                          onChanged: (v) => setState(() => consent = v),
                        ),
                        const SizedBox(height: 8),
                        ApplicationButtonWidget(
                          label: 'Add caregiver',
                          icon: Icons.person_add_alt,
                          isLoading: saving,
                          onPressed: invite,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const ApplicationSectionHeadingWidget('My caregivers'),
                const SizedBox(height: 12),
                if (caregivers.isEmpty)
                  const ApplicationFeedbackBannerWidget(
                    message: 'You have not added a caregiver yet.',
                    icon: Icons.people_outline,
                  )
                else
                  for (final c in caregivers) ...[
                    ApplicationCardWidget(
                      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
                      child: Row(
                        children: [
                          Icon(c.isAccepted ? Icons.check_circle : Icons.hourglass_top,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.caregiverName, style: theme.textTheme.titleMedium),
                                Text(c.caregiverContact, style: theme.textTheme.bodyMedium),
                                Text(
                                  c.isAccepted ? 'Connected' : 'Waiting for them to accept',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove caregiver',
                            iconSize: 30,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => remove(c),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
    );
  }
}
