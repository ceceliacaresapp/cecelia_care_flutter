import 'dart:async'; // For StreamSubscription and Debouncer

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:firebase_auth/firebase_auth.dart'; // For current user
import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp
import '../../l10n/app_localizations.dart';
import '../../locator.dart'; // Import the service locator
// For active elder check
import '../../providers/active_elder_provider.dart'; // For active elder check
import '../../providers/medication_definitions_provider.dart'; // Import MedicationDefinitionsProvider
import '../../providers/medication_provider.dart';
import '../../services/rxnav_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_styles.dart';
import '../../models/medication_entry.dart'; // Import the correct model
import '../../models/medication_definition.dart'; // Assuming this model exists
import 'package:cecelia_care_flutter/widgets/cecelia_bot_sheet.dart'; // Use package import

class MedicationManagerScreen extends StatefulWidget {
  static const String route = '/medications';
  const MedicationManagerScreen({super.key});

  @override
  State<MedicationManagerScreen> createState() =>
      _MedicationManagerScreenState();
}

class _MedicationManagerScreenState extends State<MedicationManagerScreen> {
  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final activeElder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;

    if (activeElder == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.manageMedications)),
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
      appBar: AppBar(title: Text(_l10n.manageMedications)),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addMedicationFab',
            backgroundColor: AppTheme.accentColor,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const _AddMedicationDialog(),
              );
            },
            tooltip: _l10n.medicationsAddDialogTitle,
            child: const Icon(Icons.add, color: AppTheme.textOnPrimary),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'chatWithCeceliaFab',
            backgroundColor: AppTheme.primaryColor,
            onPressed: () async {
              final medList =
                  await context.read<MedicationProvider>().medsStream().first;
              final medsJsonList = medList
                  .map((med) => {
                        'name': med.name,
                        'rxCui': med.rxCui,
                        'dose': med.dose,
                        'schedule': med.schedule,
                      })
                  .toList();
              final contextForAI = {
                'elderId': activeElder.id,
                'currentMedications': medsJsonList,
              };
              if (!context.mounted) return;
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => CeceliaBotSheet(contextForAI: contextForAI),
              );
            },
            // --- I18N UPDATE ---
            tooltip: _l10n.medicationsTooltipAskCecelia,
            child: const Icon(Icons.chat_bubble_outline,
                color: AppTheme.textOnPrimary),
          ),
        ],
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
            return Center(child: Text(_l10n.formErrorGenericSaveUpdate));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(_l10n.medicationsListEmpty,
                    style: AppStyles.emptyStateText));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final m = list[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(m.name,
                      style: AppStyles.listTileTitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  subtitle: Text(
                    '${m.dose.isNotEmpty ? m.dose : _l10n.medicationsDoseNotSet} – ${m.schedule.isNotEmpty ? m.schedule : _l10n.medicationsScheduleNotSet}',
                    style: _theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppTheme.dangerColor),
                    tooltip: _l10n.medicationsTooltipDelete,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(_l10n.medicationsConfirmDeleteTitle(m.name)),
                          content: Text(_l10n.medicationsConfirmDeleteContent),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: Text(_l10n.cancelButton)),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.dangerColor),
                              child: Text(_l10n.deleteButton),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        try {
                          await context
                              .read<MedicationProvider>()
                              .removeMedication(m.firestoreId);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(_l10n.medicationsDeletedSuccess(m.name))));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_l10n.formErrorGenericSaveUpdate)),
                          );
                        }
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AddMedicationDialog extends StatefulWidget {
  const _AddMedicationDialog();
  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  late AppLocalizations _l10n;
  late final RxNavService _rxNavService;

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _scheduleController = TextEditingController();

  List<DrugSuggestion> _suggestions = [];
  DrugSuggestion? _chosenSuggestion;
  bool _isLoadingSuggestions = false;
  String? _searchError;
  Timer? _debounce;

  bool _isLoadingInteractions = false;

  @override
  void initState() {
    super.initState();
    _rxNavService = locator<RxNavService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _scheduleController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchDrug(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _searchError = null;
        _isLoadingSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _searchError = null;
    });

    try {
      final res = await _rxNavService.searchByName(query);
      if (!mounted) return;
      setState(() {
        _suggestions = res.take(10).toList();
        _isLoadingSuggestions = false;
      });
    } on RxNavApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.message;
        _isLoadingSuggestions = false;
        _suggestions = [];
      });
      debugPrint('RxNav API Error: $e');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = _l10n.rxNavGenericSearchError;
        _isLoadingSuggestions = false;
        _suggestions = [];
      });
      debugPrint('Generic Search Error: $e');
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchDrug(query);
    });
  }

  Future<List<String>> _performInteractionCheckAndGetConfirmation(
    MedicationDefinition newlyAddedMedDefinition,
    List<MedicationDefinition> otherMedsForElder,
  ) async {
    final medicationProvider = context.read<MedicationProvider>();
    List<DrugInteraction> currentInteractions;

    if (newlyAddedMedDefinition.rxCui == null ||
        newlyAddedMedDefinition.rxCui!.isEmpty) {
      debugPrint(
          'RxCUI is missing for interaction check in _performInteractionCheckAndGetConfirmation.');
      return [];
    }

    try {
      currentInteractions = await medicationProvider
          .warnIfInteractions(newlyAddedMedDefinition.rxCui!);
    } catch (e) {
      debugPrint('Interaction check failed: $e');
      return [];
    }

    if (!mounted) return [];

    if (currentInteractions.isNotEmpty) {
      final continueWithSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(_l10n.medicationsInteractionsFoundTitle),
          content: _buildInteractionsDialogContent(currentInteractions),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(_l10n.cancelButton)),
            ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(_l10n.medicationsInteractionsSaveAnyway)),
          ],
        ),
      );
      if (continueWithSave != true) {
        return [];
      } else {
        return currentInteractions.map((interaction) {
          String otherDrugName = 'Unknown Drug';
          if (interaction.drug1Name?.toLowerCase() ==
              newlyAddedMedDefinition.name.toLowerCase()) {
            otherDrugName = interaction.drug2Name ?? 'Unknown Drug';
          } else if (interaction.drug2Name?.toLowerCase() ==
              newlyAddedMedDefinition.name.toLowerCase()) {
            otherDrugName = interaction.drug1Name ?? 'Unknown Drug';
          }
          // --- I18N UPDATE ---
          return _l10n.medicationsInteractionDetails(
              interaction.severity, otherDrugName, interaction.description);
        }).toList();
      }
    }
    return [];
  }

  Future<void> _handleAddMedication() async {
    if (_chosenSuggestion == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.medicationsValidationNameRequired)),
      );
      return;
    }
    if (_doseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.medicationsValidationDoseRequired)),
      );
      return;
    }

    setState(() => _isLoadingInteractions = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final activeElder =
          Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
      final medicationDefinitionsProvider =
          context.read<MedicationDefinitionsProvider>();
      final medicationProvider = context.read<MedicationProvider>();

      if (currentUser == null || activeElder == null) {
        // --- I18N UPDATE ---
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_l10n.formErrorUserOrElderNotFound)));
        return;
      }

      final now = Timestamp.now();
      await medicationProvider.addMedication(
        MedicationEntry(
          firestoreId: '',
          name: _chosenSuggestion!.name,
          rxCui: _chosenSuggestion!.rxCui,
          dose: _doseController.text.trim(),
          schedule: _scheduleController.text.trim(),
          time: null,
          taken: false,
          loggedByUserId: currentUser.uid,
          // --- I18N UPDATE ---
          loggedByDisplayName: currentUser.displayName ?? currentUser.email ?? _l10n.formUnknownUser,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final String? savedDefinitionId =
          await medicationDefinitionsProvider.addMedicationDefinition(
        name: _chosenSuggestion!.name,
        elderId: activeElder.id,
        rxCui: _chosenSuggestion!.rxCui,
        dose: _doseController.text.trim().isNotEmpty ? _doseController.text.trim() : null,
        defaultTime: _scheduleController.text.trim().isNotEmpty ? _scheduleController.text.trim() : null,
        checkInteractionsFunction: _performInteractionCheckAndGetConfirmation,
      );

      if (savedDefinitionId == null) {
        if (mounted) {
          // --- I18N UPDATE ---
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.medicationDefinitionSaveFailed)));
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.medicationsAddedSuccess(_chosenSuggestion!.name))));
        Navigator.of(context).pop();
      }
    } on RxNavApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_l10n.formErrorGenericSaveUpdate)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingInteractions = false);
      }
    }
  }

  Widget _buildInteractionsDialogContent(List<DrugInteraction> interactions) {
    if (interactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_l10n.medicationsNoInteractionsFound,
              textAlign: TextAlign.center),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        minWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: ListView(
        shrinkWrap: true,
        children: interactions
            .map((i) => ListTile(
                  title: Text(
                    i.severity,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: i.severity.toLowerCase() == 'high'
                            ? AppTheme.dangerColor
                            : (i.severity.toLowerCase() == 'n/a'
                                ? AppTheme.textLight
                                : AppTheme.accentColor)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  subtitle: Text(i.description,
                      overflow: TextOverflow.ellipsis, maxLines: 3),
                  isThreeLine: i.description.length > 50,
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_l10n.medicationsAddDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _l10n.medicationsSearchHint,
                hintText: _l10n.medicationsSearchHint,
                suffixIcon: _isLoadingSuggestions
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
            ),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_searchError!,
                    style: const TextStyle(color: AppTheme.dangerColor)),
              ),
            if (_suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _suggestions.map((s) {
                      return ListTile(
                        title: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        onTap: () => setState(() {
                          _chosenSuggestion = s;
                          _nameController.text = s.name;
                          _suggestions.clear();
                          _searchError = null;
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doseController,
              decoration:
                  InputDecoration(labelText: _l10n.medicationsDoseHint),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _scheduleController,
              decoration:
                  InputDecoration(labelText: _l10n.medicationsScheduleHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(_l10n.cancelButton)),
        ElevatedButton(
          onPressed: (_chosenSuggestion == null || _isLoadingInteractions)
              ? null
              : _handleAddMedication,
          child: _isLoadingInteractions
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.textOnPrimary))
              : Text(_l10n.saveButton),
        ),
      ],
    );
  }
}