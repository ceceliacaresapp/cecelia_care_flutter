import 'dart:async'; // For StreamSubscription and Debouncer

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; // For jsonDecode
import 'package:http/http.dart' as http; // For http.get

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';

// --- I18N UPDATE ---
/// A data class to hold structured error information for localization.
class MedicationDefinitionError {
  final String type; // e.g., 'load_failed', 'add_failed'
  final String details;

  MedicationDefinitionError({required this.type, required this.details});
}

class MedicationDefinitionsProvider extends ChangeNotifier {
  List<MedicationDefinition> _medDefinitions = [];
  bool _isLoadingMedDefs = true;
  ElderProfile? _currentElder;
  StreamSubscription<QuerySnapshot>? _medDefsSubscription;

  // --- I18N UPDATE ---
  // Replaced the simple String with a structured error object.
  MedicationDefinitionError? _errorInfo;

  List<MedicationDefinition> get medDefinitions => _medDefinitions;
  bool get isLoadingMedDefs => _isLoadingMedDefs;
  MedicationDefinitionError? get errorInfo => _errorInfo;

  void clearErrorMessage() {
    _errorInfo = null;
    notifyListeners();
  }

  void updateForElder(ElderProfile? elder) {
    _medDefsSubscription?.cancel();
    _currentElder = elder;
    if (elder == null) {
      _medDefinitions = [];
      _isLoadingMedDefs = false;
      _errorInfo = null;
      notifyListeners();
      return;
    }
    _subscribeToMedDefs();
  }

  void _subscribeToMedDefs() {
    if (_currentElder == null) {
      _medDefinitions = [];
      _isLoadingMedDefs = false;
      _errorInfo = null;
      notifyListeners();
      return;
    }

    _isLoadingMedDefs = true;
    _errorInfo = null;
    notifyListeners();

    _medDefsSubscription?.cancel();

    _medDefsSubscription = FirebaseFirestore.instance
        .collection('medicationDefinitions')
        .where('elderId', isEqualTo: _currentElder!.id)
        .orderBy('name')
        .snapshots()
        .listen(
      (querySnapshot) {
        _errorInfo = null;
        _medDefinitions = querySnapshot.docs
            .map((doc) => MedicationDefinition.fromFirestore(doc))
            .toList();
        _isLoadingMedDefs = false;
        notifyListeners();
      },
      onError: (e, stackTrace) {
        debugPrint('Error fetching medication definitions: $e\n$stackTrace');
        _medDefinitions = [];
        // --- I18N UPDATE ---
        _errorInfo = MedicationDefinitionError(type: 'load_failed', details: e.toString());
        _isLoadingMedDefs = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _medDefsSubscription?.cancel();
    super.dispose();
  }

  Future<String?> addMedicationDefinition({
    required String name,
    String? dose,
    String? defaultTime,
    required String elderId,
    String? rxCui,
    Future<List<String>> Function(
            MedicationDefinition newlyAddedMed, List<MedicationDefinition> otherMedsForElder)?
        checkInteractionsFunction,
  }) async {
    _isLoadingMedDefs = true;
    _errorInfo = null;
    notifyListeners();

    String? savedDocId;

    try {
      final Map<String, dynamic> coreMedData = {
        'elderId': elderId, 'name': name, 'dose': dose, 'defaultTime': defaultTime,
        'rxCui': rxCui, 'interactionNotes': [],
        'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance.collection('medicationDefinitions').add(coreMedData);
      savedDocId = docRef.id;
      debugPrint('Core MedicationDefinition added: $name (ID: $savedDocId for elder $elderId)');

      if (checkInteractionsFunction != null) {
        try {
          final newlyAddedMedDefinition = MedicationDefinition(
            id: savedDocId, elderId: elderId, name: name, dose: dose,
            defaultTime: defaultTime, rxCui: rxCui, interactionNotes: const [],
          );

          List<MedicationDefinition> otherMedsForElder = _medDefinitions
              .where((med) => med.elderId == elderId && med.id != savedDocId)
              .toList();
          
          List<String> interactionResults = await checkInteractionsFunction(newlyAddedMedDefinition, otherMedsForElder);

          await FirebaseFirestore.instance.collection('medicationDefinitions').doc(savedDocId).update({
            'interactionNotes': interactionResults,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Interaction notes updated for $name (ID: $savedDocId)');
        } catch (interactionError) {
          debugPrint('Interaction check or update failed for $name (ID: $savedDocId): $interactionError. Medication was added without interaction update.');
        }
      }
    } catch (e) {
      debugPrint('Error adding core medication definition: $e');
      // --- I18N UPDATE ---
      _errorInfo = MedicationDefinitionError(type: 'add_failed', details: e.toString());
      return null;
    } finally {
      _isLoadingMedDefs = false;
      notifyListeners();
    }
    return savedDocId;
  }

  Future<void> removeMedicationDefinition(String id) async {
    _errorInfo = null;
    try {
      await FirebaseFirestore.instance.collection('medicationDefinitions').doc(id).delete();
      // Stream will automatically update the UI
    } catch (e) {
      debugPrint('Error removing medication definition: $e');
      // --- I18N UPDATE ---
      _errorInfo = MedicationDefinitionError(type: 'remove_failed', details: e.toString());
      notifyListeners();
    }
  }

  Future<void> addOrUpdate(MedicationDefinition definition) async {
    _isLoadingMedDefs = true;
    _errorInfo = null;
    notifyListeners();

    try {
      Query query = FirebaseFirestore.instance
          .collection('medicationDefinitions')
          .where('elderId', isEqualTo: definition.elderId);

      if (definition.rxCui != null && definition.rxCui!.isNotEmpty) {
        query = query.where('rxCui', isEqualTo: definition.rxCui);
      } else {
        query = query.where('name', isEqualTo: definition.name);
      }

      final querySnapshot = await query.limit(1).get();
      final dataToSave = definition.toJson();

      if (querySnapshot.docs.isNotEmpty) {
        final docId = querySnapshot.docs.first.id;
        await FirebaseFirestore.instance.collection('medicationDefinitions').doc(docId).update(dataToSave);
        debugPrint('MedicationDefinition updated: ${definition.name} (ID: $docId for elder ${definition.elderId})');
      } else {
        await FirebaseFirestore.instance.collection('medicationDefinitions').add(dataToSave);
        debugPrint('MedicationDefinition added: ${definition.name} for elder ${definition.elderId}');
      }
    } catch (e) {
      debugPrint('Error in addOrUpdate MedicationDefinition: $e');
      // --- I18N UPDATE ---
      _errorInfo = MedicationDefinitionError(type: 'save_failed', details: e.toString());
    } finally {
      _isLoadingMedDefs = false;
      notifyListeners();
    }
  }

  Future<void> checkAndSaveDrugInteractions(String elderId) async {
    if (_currentElder == null || _currentElder!.id != elderId) {
      debugPrint('MedicationDefinitionsProvider: checkAndSaveDrugInteractions called for an inactive elder. Aborting.');
      // --- I18N UPDATE ---
      _errorInfo = MedicationDefinitionError(type: 'inactive_elder', details: 'Cannot check interactions for an inactive elder.');
      notifyListeners();
      return;
    }

    final List<MedicationDefinition> definitionsToCheck = List.from(_medDefinitions);
    final uniqueRxCuisList = definitionsToCheck
        .map((def) => def.rxCui)
        .where((rxCui) => rxCui != null && rxCui.isNotEmpty)
        .map((rxCui) => rxCui!)
        .toSet()
        .toList();

    if (uniqueRxCuisList.length < 2) {
      debugPrint('Not enough unique RxCUIs to check for interactions for elder $elderId.');
      // Clear existing interaction notes if no check is possible
      for (final medDef in definitionsToCheck) {
        if (medDef.id != null && (medDef.interactionNotes?.isNotEmpty ?? false)) {
          try {
            await FirebaseFirestore.instance.collection('medicationDefinitions').doc(medDef.id!).update({'interactionNotes': [], 'updatedAt': FieldValue.serverTimestamp()});
          } catch (e) {
            debugPrint('Error clearing interaction notes for ${medDef.name}: $e');
          }
        }
      }
      return;
    }

    final String uniqueRxCuisString = uniqueRxCuisList.join('+');
    final uri = Uri.parse('https://rxnav.nlm.nih.gov/REST/interaction/list.json?rxcuis=$uniqueRxCuisString');
    debugPrint('Checking interactions for elder $elderId. URI: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> interactionData = jsonDecode(response.body);
        final List<dynamic> fullInteractionTypeGroup = interactionData['fullInteractionTypeGroup'] as List? ?? [];
        List<Map<String, dynamic>> parsedInteractionPairs = [];
        for (var group in fullInteractionTypeGroup) {
          final List<dynamic> fullInteractionType = group['fullInteractionType'] as List? ?? [];
          for (var type in fullInteractionType) {
            final List<dynamic> interactionPairList = type['interactionPair'] as List? ?? [];
            for (var pair in interactionPairList) {
              parsedInteractionPairs.add(pair as Map<String, dynamic>);
            }
          }
        }

        for (final medDef in definitionsToCheck) {
          if (medDef.id == null || medDef.rxCui == null || medDef.rxCui!.isEmpty) continue;
          List<String> newInteractionNotes = [];
          if (parsedInteractionPairs.isNotEmpty) {
            for (var pair in parsedInteractionPairs) {
              // --- I18N NOTE ---
              // Fallback strings are hardcoded here. For full I18N, the UI should handle
              // these fallbacks using localization keys, e.g., l10n.interactionNoDescription.
              final String description = pair['description'] as String? ?? 'No description available.';
              final String severity = pair['severity'] as String? ?? 'N/A';
              final List<dynamic> interactionConcepts = pair['interactionConcept'] as List? ?? [];

              if (interactionConcepts.length == 2) {
                final Map<String, dynamic>? concept1Data = interactionConcepts[0]['minConceptItem'] as Map<String, dynamic>?;
                final Map<String, dynamic>? concept2Data = interactionConcepts[1]['minConceptItem'] as Map<String, dynamic>?;

                if (concept1Data != null && concept2Data != null) {
                  final String rxcui1 = concept1Data['rxcui'] as String? ?? '';
                  final String name1 = concept1Data['name'] as String? ?? 'Unknown Drug';
                  final String rxcui2 = concept2Data['rxcui'] as String? ?? '';
                  final String name2 = concept2Data['name'] as String? ?? 'Unknown Drug';

                  // --- I18N NOTE ---
                  // This creates a language-specific string in the database.
                  // A better approach is to store structured data and format it in the UI, e.g.,
                  // interactionNotes: [{'with': name, 'desc': desc, 'severity': sev}]
                  String note = 'Interaction with $name2: $description (Severity: $severity)';
                  if (medDef.rxCui == rxcui2) {
                    note = 'Interaction with $name1: $description (Severity: $severity)';
                  }
                  
                  if (medDef.rxCui == rxcui1 || medDef.rxCui == rxcui2) {
                    newInteractionNotes.add(note);
                  }
                }
              }
            }
          }
          await FirebaseFirestore.instance.collection('medicationDefinitions').doc(medDef.id!).update({
            'interactionNotes': newInteractionNotes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        debugPrint('Interaction check and notes update process completed for elder $elderId.');
      } else {
        debugPrint('RxNav API returned ${response.statusCode} for elder $elderId. URL: $uri');
        // --- I18N UPDATE ---
        _errorInfo = MedicationDefinitionError(type: 'api_error', details: 'RxNav API error: ${response.statusCode}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Interaction check failed for elder $elderId: $e');
      // --- I18N UPDATE ---
      _errorInfo = MedicationDefinitionError(type: 'check_failed', details: e.toString());
      notifyListeners();
    }
  }
}