import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/screens/medications/medication_screen.dart';
import 'package:medischedule/screens/medications/medication.dart';

extension MedicationList on MedicationScreenState {
  Widget buildMedicationList(BuildContext context) {
    final normalizedQuery = query.toLowerCase();
    final visibleMedications = widget.medications
        .where(
          (medication) =>
              medication.name.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);

    if (widget.loading && widget.medications.isEmpty) {
      return const ApplicationLoadingWidget(message: 'Loading medications...');
    }
    if (widget.loadError != null && widget.medications.isEmpty) {
      return ApplicationErrorWidget(
        message: widget.loadError!,
        onRetry: widget.onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                ApplicationTextFieldWidget(
                  label: 'Find a medication',
                  controller: searchController,
                  prefixIcon: Icons.search,
                  onChanged: (value) =>
                      updateMedicationFormState(() => query = value),
                ),
                const SizedBox(height: 20),
                ApplicationSectionHeadingWidget(
                  '${visibleMedications.length} medications',
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),
          if (visibleMedications.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: ApplicationFeedbackBannerWidget(
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
                  return buildMedicationCard(
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
                ApplicationButtonWidget(
                  label: 'Create Reminder',
                  icon: Icons.add,
                  onPressed: () => openMedicationForm(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMedicationCard(BuildContext context, Medication medication) {
    final colorScheme = Theme.of(context).colorScheme;
    return ApplicationCardWidget(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Icon(medication.icon),
          ),
          const SizedBox(width: 14),
          Expanded(
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
          IconButton(
            tooltip: 'Reminder times for ${medication.name}',
            onPressed: () => openReminderSchedule(medication),
            icon: const Icon(Icons.alarm_outlined),
          ),
          IconButton(
            tooltip: 'Edit ${medication.name}',
            onPressed: () => openMedicationForm(medication),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Remove ${medication.name}',
            onPressed: () => removeMedication(medication),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}