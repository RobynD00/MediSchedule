import 'package:flutter/material.dart';
import 'package:medischedule/core/application_widget.dart';
import 'package:medischedule/screens/medications/medication_screen.dart';
import 'package:medischedule/screens/medications/medication.dart';

extension MedicationList on MedicationScreenState {
  Widget buildMedicationList(BuildContext context) {
    // Normalize the query once rather than once for every medication.
    final normalizedQuery = query.toLowerCase();
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
        // Show a feedback banner when there are no medications or no matches for the search query, providing appropriate messages and icons based on the situation.
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
    );
  }

  Widget buildMedicationCard(BuildContext context, Medication medication) {
    final colorScheme = Theme.of(context).colorScheme;
    // The medication card displays the medication's name, dose, and schedule, along with action buttons for editing and removing the medication. It uses a CircleAvatar to show the medication's icon and provides a visually appealing layout for managing individual medications in the list.
    return ApplicationCardWidget(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Icon(medication.icon),
          ),
          // The medication details are displayed in a column, including the medication's name, dose, and schedule. The name is styled as a title, while the dose and schedule are shown as a subtitle. This layout provides clear information about the medication at a glance.
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
          // The action buttons for editing and removing the medication are placed at the end of the card, allowing users to easily manage their medications. The edit button opens the medication form with the selected medication's details pre-filled, while the remove button prompts the user for confirmation before deleting the medication from the list.
          IconButton(
            tooltip: 'Edit ${medication.name}',
            onPressed: () => openMedicationForm(medication),
            icon: const Icon(Icons.edit_outlined),
          ),
          // The remove button allows users to delete a medication from their list. When pressed, it triggers a confirmation dialog to ensure that the user intends to remove the medication, preventing accidental deletions. If confirmed, the medication is removed, and feedback is provided to the user.
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
