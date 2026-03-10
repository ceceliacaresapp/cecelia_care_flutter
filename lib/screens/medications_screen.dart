import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/medication_entry.dart';
import '../providers/active_elder_provider.dart';
import '../providers/medication_provider.dart';
import '../utils/app_styles.dart';
import '../utils/app_theme.dart';
import '../widgets/med_form_modal.dart';

class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key});

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  // --- PERFORMANCE FIX: Step 1 ---
  // Declare late variables to hold the theme and localization data.
  late AppLocalizations _l10n;
  late ThemeData _theme;

  // --- PERFORMANCE FIX: Step 2 ---
  // Fetch the data only when dependencies change, not on every build.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    // Note: We no longer call Theme.of(context) or AppLocalizations.of(context) here.
    // We get the active elder from the provider.
    final activeElder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;

    if (activeElder == null) {
      return Scaffold(
        // --- PERFORMANCE FIX: Step 3 ---
        // Use the stored _l10n variable.
        appBar: AppBar(title: Text(_l10n.medicationsScreenTitleGeneric)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _l10n.settingsSelectElderToViewMedDefs,
              style: AppStyles.emptyStateText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Use the stored _l10n variable.
        title: Text(_l10n.medicationsScreenTitleForElder(activeElder.profileName)),
      ),
      floatingActionButton: FloatingActionButton(
        // Using AppTheme constants is already efficient. No change needed.
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: AppTheme.textOnPrimary),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) =>
                ChangeNotifierProvider.value(
                  value: context.read<MedicationProvider>(),
                  child: MedFormModal(elderId: activeElder.id),
                ),
          );
        },
      ),
      body: StreamBuilder<List<MedicationEntry>>(
        stream: context.watch<MedicationProvider>().medsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            debugPrint('Error loading medications: ${snapshot.error}');
            // Use the stored _l10n variable.
            return Center(child: Text(_l10n.formErrorGenericSaveUpdate));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(_l10n.medicationsListEmpty,
                    style: AppStyles.emptyStateText));
          }

          final medications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: medications.length,
            itemBuilder: (_, index) {
              final med = medications[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(med.name, style: AppStyles.listTileTitle),
                  subtitle: Text(
                      '${med.dose.isNotEmpty ? med.dose : _l10n.medicationsDoseNotSet}  –  ${med.schedule.isNotEmpty ? med.schedule : _l10n.medicationsScheduleNotSet}',
                      // Use the stored _theme variable.
                      style: _theme.textTheme.bodyMedium),
                ),
              );
            },
          );
        },
      ),
    );
  }
}