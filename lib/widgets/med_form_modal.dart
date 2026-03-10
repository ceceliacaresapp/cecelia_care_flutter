import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/app_localizations.dart';
import '../locator.dart'; // Import the service locator
import '../models/medication_entry.dart';
import '../providers/medication_provider.dart';
import '../services/rxnav_service.dart';
import '../services/drug_interaction_service.dart';
import '../utils/app_theme.dart';

class MedFormModal extends StatefulWidget {
  final String elderId;

  const MedFormModal({super.key, required this.elderId});

  @override
  State<MedFormModal> createState() => _MedFormModalState();
}

class _MedFormModalState extends State<MedFormModal> {
  final _formKey = GlobalKey<FormState>();
  late final RxNavService _rxNavService;
  // No need to hold an instance of DrugInteractionService, we can get it from the locator when needed.

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _scheduleController = TextEditingController();

  List<DrugSuggestion> _suggestions = [];
  DrugSuggestion? _chosenSuggestion;
  bool _isLoadingSuggestions = false;
  String? _searchError;
  Timer? _debounce;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Get the service instance from the locator.
    _rxNavService = locator<RxNavService>();
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
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    if (mounted) setState(() => _isLoadingSuggestions = true);
    try {
      final res = await _rxNavService.searchByName(query);
      if (mounted) {
        setState(() {
          _suggestions = res.take(5).toList(); // Limit suggestions
          _searchError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchError = AppLocalizations.of(context)!.rxNavGenericSearchError;
          _suggestions = [];
        });
      }
      debugPrint('RxNav search error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSuggestions = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchDrug(query);
    });
  }

  Future<void> _saveMedication() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_chosenSuggestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.medicationsValidationNameRequired)),
      );
      return;
    }

    setState(() => _isSaving = true);

    final medicationProvider = context.read<MedicationProvider>();
    final now = Timestamp.now();
    final currentUser = FirebaseAuth.instance.currentUser;

    final newMedication = MedicationEntry(
      firestoreId: '', // Firestore generates this ID.
      name: _chosenSuggestion!.name,
      rxCui: _chosenSuggestion!.rxCui,
      dose: _doseController.text.trim(),
      schedule: _scheduleController.text.trim(),
      taken: false,
      loggedByUserId: currentUser?.uid ?? '',
      loggedByDisplayName: currentUser?.displayName ??
          currentUser?.email ??
          l10n.formUnknownUser,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await medicationProvider.addMedication(newMedication);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n.medicationsAddedSuccess(_chosenSuggestion!.name))),
      );
      Navigator.of(context).pop(); // Close modal first

      // Interaction check AFTER saving
      final List<MedicationEntry> currentMeds =
          await medicationProvider.medsStream().first;
      final List<String> allRxCuis =
          currentMeds.map((m) => m.rxCui).where((r) => r.isNotEmpty).toList();

      if (allRxCuis.length >= 2) {
        // Get the service from the locator and call the instance method
        final interactionWarning =
            await locator<DrugInteractionService>().checkInteractions(allRxCuis);

        if (interactionWarning != null && mounted) {
          showDialog(
            context: context, // Use the original screen's context
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.medicationsInteractionsFoundTitle),
              content: Text(interactionWarning),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(l10n.okButton),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.formErrorGenericSaveUpdate)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.medicationsAddDialogTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                    labelText: l10n.medicationsSearchHint,
                    suffixIcon: _isLoadingSuggestions
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : null),
                onChanged: _onSearchChanged,
                validator: (value) => (value == null ||
                        value.isEmpty ||
                        _chosenSuggestion == null)
                    ? l10n.medicationsValidationNameRequired
                    : null,
              ),
              if (_searchError != null)
                Text(_searchError!,
                    style: TextStyle(color: Colors.red.shade700)),
              if (_suggestions.isNotEmpty)
                SizedBox(
                  height: 150, // Adjust as needed
                  child: ListView.builder(
                    itemCount: _suggestions.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(_suggestions[i].name),
                      onTap: () => setState(() {
                        _chosenSuggestion = _suggestions[i];
                        _nameController.text = _chosenSuggestion!.name;
                        _suggestions = [];
                      }),
                    ),
                  ),
                ),
              TextFormField(
                  controller: _doseController,
                  decoration:
                      InputDecoration(labelText: l10n.medicationsDoseHint),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.medicationsValidationDoseRequired
                      : null),
              TextFormField(
                  controller: _scheduleController,
                  decoration:
                      InputDecoration(labelText: l10n.medicationsScheduleHint)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveMedication,
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l10n.saveButton,
                        style: const TextStyle(color: Colors.white)),
              ),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancelButton)),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}