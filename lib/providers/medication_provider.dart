import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/entry_types.dart';
import '../models/medication_entry.dart';
import '../providers/medication_definitions_provider.dart';
import '../services/firestore_service.dart';
import '../services/rxnav_service.dart';

class MedicationProvider with ChangeNotifier {
  final String _elderId;
  final FirestoreService _firestoreService;
  final RxNavService _rx;

  // Optional — if supplied, markTaken() will decrement pill count after a
  // dose is confirmed.
  final MedicationDefinitionsProvider? _medDefsProvider;

  // Care recipient's display name, used in the refill notification body.
  final String _elderName;

  MedicationProvider({
    required String elderId,
    required FirestoreService firestoreService,
    required RxNavService rxNavService,
    MedicationDefinitionsProvider? medDefsProvider,
    String elderName = '',
  })  : _elderId = elderId,
        _firestoreService = firestoreService,
        _rx = rxNavService,
        _medDefsProvider = medDefsProvider,
        _elderName = elderName;

  Stream<List<MedicationEntry>> medsStream() {
    if (_elderId.isEmpty) return const Stream.empty();
    return _firestoreService.medsForElder(_elderId);
  }

  Future<DocumentReference<MedicationEntry>> addMedication(
      MedicationEntry m) async {
    if (_elderId.isEmpty) {
      throw Exception('Elder ID is not set. Cannot add medication.');
    }
    return await _firestoreService.addMed(_elderId, m);
  }

  Future<void> updateMedication(MedicationEntry m) async {
    if (_elderId.isEmpty || m.id.isEmpty) {
      throw Exception(
          'Elder ID or Medication ID is missing. Cannot update medication.');
    }
    await _firestoreService.updateMed(_elderId, m);
  }

  // ---------------------------------------------------------------------------
  // markTaken — confirms a dose as taken or skipped.
  //
  // Step 1: Update the MedicationEntry (taken bool + takenAt timestamp).
  // Step 2: Write a JournalEntry to the journalEntries collection so the
  //         dose appears on the Timeline and the Dashboard today-care-log.
  //         This mirrors what MedForm does when a med is logged normally.
  // Step 3: If taken == true and medDefsProvider is available, decrement
  //         the pill count and fire a refill notification if threshold hit.
  //         Skipped doses do NOT decrement pill count.
  // ---------------------------------------------------------------------------
  Future<void> markTaken({
    required MedicationEntry entry,
    required bool taken,
  }) async {
    if (_elderId.isEmpty || entry.id.isEmpty) {
      throw Exception(
          'Elder ID or Medication ID is missing. Cannot mark medication.');
    }

    final now = DateTime.now();
    final takenAt = Timestamp.now();

    // Step 1: Update MedicationEntry
    final updated = entry.copyWith(
      taken: taken,
      takenAt: takenAt,
    );
    await _firestoreService.updateMed(_elderId, updated);

    // Step 2: Write a JournalEntry so timeline + dashboard pick it up.
    // Only write when marking taken (not skipped) to avoid cluttering the
    // timeline with every skip. Adjust if you want skips visible too.
    if (taken) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        final String loggedByUserId = currentUser?.uid ?? '';
        final String loggedByDisplayName =
            currentUser?.displayName ??
            currentUser?.email ??
            'Caregiver';

        await _firestoreService.addJournalEntry(
          elderId: _elderId,
          type: EntryType.medication,
          text: '${entry.name} — ${entry.dose}',
          data: {
            'name': entry.name,
            'rxCui': entry.rxCui,
            'dose': entry.dose,
            'schedule': entry.schedule,
            'taken': true,
            'takenAt': takenAt,
          },
          visibleToUserIds: null, // will be filled by addJournalEntry default
          isPublic: true,
          creatorId: loggedByUserId,
          timestamp: now,
        );
      } catch (e, stack) {
        // Journal write failure is non-fatal — the medication entry is
        // already updated. Log but don't rethrow.
        debugPrint(
            'MedicationProvider.markTaken: JournalEntry write failed: $e\n$stack');
      }
    }

    // Step 3: Decrement pill count (taken only).
    if (taken && _medDefsProvider != null) {
      final matchingDef = _medDefsProvider!.medDefinitions
          .where((d) =>
              d.elderId == _elderId &&
              d.name.toLowerCase() == entry.name.toLowerCase())
          .firstOrNull;

      if (matchingDef?.id != null) {
        await _medDefsProvider!.decrementPillCount(
          medDefId: matchingDef!.id!,
          medName: entry.name,
          elderName: _elderName,
        );
      } else {
        debugPrint(
            'MedicationProvider.markTaken: no matching definition found '
            'for "${entry.name}" — pill count not decremented.');
      }
    }
  }

  Future<void> removeMedication(String medId) async {
    if (_elderId.isEmpty || medId.isEmpty) {
      throw Exception(
          'Elder ID or Medication ID is missing. Cannot remove medication.');
    }
    await _firestoreService.deleteMed(_elderId, medId);
  }

  Future<List<DrugInteraction>> warnIfInteractions(
    String newRxCui, {
    List<MedicationEntry>? existingMeds,
  }) async {
    if (_elderId.isEmpty || newRxCui.isEmpty) return [];

    final List<MedicationEntry> currentMeds =
        existingMeds ?? await medsStream().first;

    final allRxCuis = <String>{newRxCui};
    for (final med in currentMeds) {
      if (med.rxCui.isNotEmpty) allRxCuis.add(med.rxCui);
    }

    if (allRxCuis.length < 2) return [];
    return _rx.checkInteractions(allRxCuis.toList());
  }
}
