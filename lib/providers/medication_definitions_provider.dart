import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';

class MedicationDefinitionError {
  final String type;
  final String details;
  MedicationDefinitionError({required this.type, required this.details});
}

class MedicationDefinitionsProvider extends ChangeNotifier {
  List<MedicationDefinition> _medDefinitions = [];
  bool _isLoadingMedDefs = true;
  ElderProfile? _currentElder;
  StreamSubscription<QuerySnapshot>? _medDefsSubscription;
  MedicationDefinitionError? _errorInfo;

  List<MedicationDefinition> get medDefinitions => _medDefinitions;
  bool get isLoadingMedDefs => _isLoadingMedDefs;
  MedicationDefinitionError? get errorInfo => _errorInfo;

  /// Medications the user has pinned for quick one-tap logging on the dashboard.
  List<MedicationDefinition> get pinnedMeds =>
      _medDefinitions.where((d) => d.pinned).toList();

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
        _errorInfo =
            MedicationDefinitionError(type: 'load_failed', details: e.toString());
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

  // ---------------------------------------------------------------------------
  // updateReminderEnabled
  // ---------------------------------------------------------------------------
  Future<void> updateReminderEnabled({
    required String medDefId,
    required bool enabled,
  }) async {
    _errorInfo = null;
    try {
      await FirebaseFirestore.instance
          .collection('medicationDefinitions')
          .doc(medDefId)
          .update({
        'reminderEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final idx = _medDefinitions.indexWhere((d) => d.id == medDefId);
      if (idx != -1) {
        _medDefinitions[idx] =
            _medDefinitions[idx].copyWith(reminderEnabled: enabled);
        notifyListeners();
      }

      debugPrint(
          'MedicationDefinitionsProvider: reminder '
          '${enabled ? "enabled" : "disabled"} for med def $medDefId');
    } catch (e) {
      debugPrint('Error updating reminderEnabled for $medDefId: $e');
      _errorInfo = MedicationDefinitionError(
          type: 'reminder_update_failed', details: e.toString());
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // togglePinned — pin/unpin a medication for dashboard quick-log
  // ---------------------------------------------------------------------------
  Future<void> togglePinned({
    required String medDefId,
    required bool pinned,
  }) async {
    _errorInfo = null;
    try {
      await FirebaseFirestore.instance
          .collection('medicationDefinitions')
          .doc(medDefId)
          .update({
        'pinned': pinned,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final idx = _medDefinitions.indexWhere((d) => d.id == medDefId);
      if (idx != -1) {
        _medDefinitions[idx] =
            _medDefinitions[idx].copyWith(pinned: pinned);
        notifyListeners();
      }

      debugPrint(
          'MedicationDefinitionsProvider: ${pinned ? "pinned" : "unpinned"} '
          'med def $medDefId');
    } catch (e) {
      debugPrint('Error toggling pinned for $medDefId: $e');
      _errorInfo = MedicationDefinitionError(
          type: 'pin_update_failed', details: e.toString());
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // NEW: decrementPillCount
  //
  // Called by MedicationProvider.markTaken() after a dose is confirmed taken.
  // Decrements pillCount by 1 in Firestore and optimistically in the local
  // list. If the new count is at or below refillThreshold, fires a one-time
  // low-stock push notification via NotificationService.
  //
  // No-ops silently if:
  //   - the definition is not found in the local list
  //   - pillCount is null (pill tracking not set up for this med)
  //   - pillCount is already 0 (can't go negative)
  // ---------------------------------------------------------------------------
  Future<void> decrementPillCount({
    required String medDefId,
    required String medName,
    required String elderName,
  }) async {
    final idx = _medDefinitions.indexWhere((d) => d.id == medDefId);
    if (idx == -1) {
      debugPrint(
          'MedicationDefinitionsProvider.decrementPillCount: '
          'definition $medDefId not found in local list.');
      return;
    }

    final def = _medDefinitions[idx];

    // Pill tracking not configured — nothing to decrement.
    if (def.pillCount == null) return;

    // Already at zero — don't go negative.
    if (def.pillCount! <= 0) return;

    final int newCount = def.pillCount! - 1;

    // Optimistic local update.
    _medDefinitions[idx] = def.copyWith(pillCount: newCount);
    notifyListeners();

    try {
      await FirebaseFirestore.instance
          .collection('medicationDefinitions')
          .doc(medDefId)
          .update({
        'pillCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'MedicationDefinitionsProvider: pillCount for $medName '
          'decremented to $newCount.');

      // Fire refill reminder if at or below threshold.
      if (def.refillThreshold != null && newCount <= def.refillThreshold!) {
        _fireRefillNotification(
          medDefId: medDefId,
          medName: medName,
          elderName: elderName,
          pillCount: newCount,
        );
      }
    } catch (e) {
      // Revert optimistic update on failure.
      debugPrint(
          'MedicationDefinitionsProvider.decrementPillCount error: $e');
      _medDefinitions[idx] = def;
      _errorInfo = MedicationDefinitionError(
          type: 'decrement_failed', details: e.toString());
      notifyListeners();
    }
  }

  // Fires a one-time low-stock notification. Errors are logged but don't
  // affect the caller's flow.
  // Fires an immediate low-stock notification using showInstant()
  // (no future DateTime needed — alert the caregiver right now).
  void _fireRefillNotification({
    required String medDefId,
    required String medName,
    required String elderName,
    required int pillCount,
  }) {
    NotificationService.instance
        .showInstant(
      'health_reminders',
      'Refill reminder: $medName',
      'Only $pillCount pill${pillCount == 1 ? "" : "s"} left '
          'for $elderName. Time to refill.',
      'refill|$medDefId',
    )
        .catchError((e) {
      debugPrint(
          'MedicationDefinitionsProvider._fireRefillNotification error: $e');
    });
  }

  // ---------------------------------------------------------------------------
  // updatePhotoUrl — targeted single-field update for medication photos.
  // ---------------------------------------------------------------------------
  Future<void> updatePhotoUrl({
    required String medDefId,
    required String? photoUrl,
  }) async {
    _errorInfo = null;
    try {
      await FirebaseFirestore.instance
          .collection('medicationDefinitions')
          .doc(medDefId)
          .update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final idx = _medDefinitions.indexWhere((d) => d.id == medDefId);
      if (idx != -1) {
        _medDefinitions[idx] =
            _medDefinitions[idx].copyWith(photoUrl: photoUrl);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('MedicationDefinitionsProvider.updatePhotoUrl error: $e');
      _errorInfo = MedicationDefinitionError(
          type: 'photo_update_failed', details: e.toString());
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // addMedicationDefinition
  // ---------------------------------------------------------------------------
  Future<String?> addMedicationDefinition({
    required String name,
    String? dose,
    String? defaultTime,
    required String elderId,
    String? rxCui,
    String? photoUrl,
    Future<List<String>> Function(MedicationDefinition newlyAddedMed,
            List<MedicationDefinition> otherMedsForElder)?
        checkInteractionsFunction,
  }) async {
    _isLoadingMedDefs = true;
    _errorInfo = null;
    notifyListeners();

    String? savedDocId;

    try {
      final Map<String, dynamic> coreMedData = {
        'elderId': elderId,
        'name': name,
        'dose': dose,
        'defaultTime': defaultTime,
        'rxCui': rxCui,
        'interactionNotes': [],
        'reminderEnabled': false,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await FirebaseFirestore.instance
          .collection('medicationDefinitions')
          .add(coreMedData);
      savedDocId = docRef.id;
      debugPrint(
          'Core MedicationDefinition added: $name '
          '(ID: $savedDocId for elder $elderId)');

      if (checkInteractionsFunction != null) {
        try {
          final newlyAddedMedDefinition = MedicationDefinition(
            id: savedDocId,
            elderId: elderId,
            name: name,
            dose: dose,
            defaultTime: defaultTime,
            rxCui: rxCui,
            interactionNotes: const [],
          );

          final List<MedicationDefinition> otherMedsForElder =
              _medDefinitions
                  .where((med) =>
                      med.elderId == elderId && med.id != savedDocId)
                  .toList();

          final List<String> interactionResults =
              await checkInteractionsFunction(
                  newlyAddedMedDefinition, otherMedsForElder);

          await FirebaseFirestore.instance
              .collection('medicationDefinitions')
              .doc(savedDocId)
              .update({
            'interactionNotes': interactionResults,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint(
              'Interaction notes updated for $name (ID: $savedDocId)');
        } catch (interactionError) {
          debugPrint(
              'Interaction check or update failed for $name '
              '(ID: $savedDocId): $interactionError. '
              'Medication was added without interaction update.');
        }
      }
    } catch (e) {
      debugPrint('Error adding core medication definition: $e');
      _errorInfo =
          MedicationDefinitionError(type: 'add_failed', details: e.toString());
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
      await FirebaseFirestore.instance
          .collection('medicationDefinitions')
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint('Error removing medication definition: $e');
      _errorInfo = MedicationDefinitionError(
          type: 'remove_failed', details: e.toString());
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
        await FirebaseFirestore.instance
            .collection('medicationDefinitions')
            .doc(docId)
            .update(dataToSave);
        debugPrint(
            'MedicationDefinition updated: ${definition.name} '
            '(ID: $docId for elder ${definition.elderId})');
      } else {
        await FirebaseFirestore.instance
            .collection('medicationDefinitions')
            .add(dataToSave);
        debugPrint(
            'MedicationDefinition added: ${definition.name} '
            'for elder ${definition.elderId}');
      }
    } catch (e) {
      debugPrint('Error in addOrUpdate MedicationDefinition: $e');
      _errorInfo =
          MedicationDefinitionError(type: 'save_failed', details: e.toString());
    } finally {
      _isLoadingMedDefs = false;
      notifyListeners();
    }
  }

  Future<void> checkAndSaveDrugInteractions(String elderId) async {
    if (_currentElder == null || _currentElder!.id != elderId) {
      debugPrint(
          'MedicationDefinitionsProvider: checkAndSaveDrugInteractions '
          'called for an inactive elder. Aborting.');
      _errorInfo = MedicationDefinitionError(
          type: 'inactive_elder',
          details: 'Cannot check interactions for an inactive elder.');
      notifyListeners();
      return;
    }

    final List<MedicationDefinition> definitionsToCheck =
        List.from(_medDefinitions);
    final uniqueRxCuisList = definitionsToCheck
        .map((def) => def.rxCui)
        .where((rxCui) => rxCui != null && rxCui.isNotEmpty)
        .map((rxCui) => rxCui!)
        .toSet()
        .toList();

    if (uniqueRxCuisList.length < 2) {
      debugPrint(
          'Not enough unique RxCUIs to check for interactions for elder $elderId.');
      for (final medDef in definitionsToCheck) {
        if (medDef.id != null &&
            (medDef.interactionNotes?.isNotEmpty ?? false)) {
          try {
            await FirebaseFirestore.instance
                .collection('medicationDefinitions')
                .doc(medDef.id!)
                .update({
              'interactionNotes': [],
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            debugPrint(
                'Error clearing interaction notes for ${medDef.name}: $e');
          }
        }
      }
      return;
    }

    final String uniqueRxCuisString = uniqueRxCuisList.join('+');
    final uri = Uri.parse(
        'https://rxnav.nlm.nih.gov/REST/interaction/list.json?rxcuis=$uniqueRxCuisString');
    debugPrint('Checking interactions for elder $elderId. URI: $uri');

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> interactionData =
            jsonDecode(response.body);
        final List<dynamic> fullInteractionTypeGroup =
            interactionData['fullInteractionTypeGroup'] as List? ?? [];
        List<Map<String, dynamic>> parsedInteractionPairs = [];
        for (var group in fullInteractionTypeGroup) {
          final List<dynamic> fullInteractionType =
              group['fullInteractionType'] as List? ?? [];
          for (var type in fullInteractionType) {
            final List<dynamic> interactionPairList =
                type['interactionPair'] as List? ?? [];
            for (var pair in interactionPairList) {
              parsedInteractionPairs.add(pair as Map<String, dynamic>);
            }
          }
        }

        for (final medDef in definitionsToCheck) {
          if (medDef.id == null ||
              medDef.rxCui == null ||
              medDef.rxCui!.isEmpty) continue;
          List<String> newInteractionNotes = [];
          if (parsedInteractionPairs.isNotEmpty) {
            for (var pair in parsedInteractionPairs) {
              final String description =
                  pair['description'] as String? ?? 'No description available.';
              final String severity = pair['severity'] as String? ?? 'N/A';
              final List<dynamic> interactionConcepts =
                  pair['interactionConcept'] as List? ?? [];

              if (interactionConcepts.length == 2) {
                final Map<String, dynamic>? concept1Data =
                    interactionConcepts[0]['minConceptItem']
                        as Map<String, dynamic>?;
                final Map<String, dynamic>? concept2Data =
                    interactionConcepts[1]['minConceptItem']
                        as Map<String, dynamic>?;

                if (concept1Data != null && concept2Data != null) {
                  final String rxcui1 = concept1Data['rxcui'] as String? ?? '';
                  final String name1 =
                      concept1Data['name'] as String? ?? 'Unknown Drug';
                  final String rxcui2 = concept2Data['rxcui'] as String? ?? '';
                  final String name2 =
                      concept2Data['name'] as String? ?? 'Unknown Drug';

                  String note =
                      'Interaction with $name2: $description (Severity: $severity)';
                  if (medDef.rxCui == rxcui2) {
                    note =
                        'Interaction with $name1: $description (Severity: $severity)';
                  }

                  if (medDef.rxCui == rxcui1 || medDef.rxCui == rxcui2) {
                    newInteractionNotes.add(note);
                  }
                }
              }
            }
          }
          await FirebaseFirestore.instance
              .collection('medicationDefinitions')
              .doc(medDef.id!)
              .update({
            'interactionNotes': newInteractionNotes,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        debugPrint(
            'Interaction check and notes update process completed '
            'for elder $elderId.');
      } else {
        debugPrint(
            'RxNav API returned ${response.statusCode} for elder $elderId. URL: $uri');
        _errorInfo = MedicationDefinitionError(
            type: 'api_error',
            details: 'RxNav API error: ${response.statusCode}');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Interaction check failed for elder $elderId: $e');
      _errorInfo =
          MedicationDefinitionError(type: 'check_failed', details: e.toString());
      notifyListeners();
    }
  }
}
