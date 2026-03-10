import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/medication_entry.dart';
import '../services/firestore_service.dart';
import '../services/rxnav_service.dart';

/// Manages medication data for a *single, specific elder*.
///
/// This provider is designed to be "scoped" to an elder. It requires an `elderId`
/// upon creation and uses it for all Firestore operations.
///
/// It should be provided in the widget tree using a `ChangeNotifierProxyProvider`
/// that listens to `ActiveElderProvider`. This ensures that when the active
/// elder changes, this provider is rebuilt with the correct new `elderId`.
class MedicationProvider with ChangeNotifier {
  final String _elderId;
  final FirestoreService _firestoreService;
  final RxNavService _rx;

  /// Creates an instance of [MedicationProvider].
  ///
  /// All dependencies are required and should be supplied by a service
  /// locator or a proxy provider.
  MedicationProvider({
    required String elderId,
    required FirestoreService firestoreService,
    required RxNavService rxNavService,
  })  : _elderId = elderId,
        _firestoreService = firestoreService,
        _rx = rxNavService;

  /// Provides a stream of medication entries for the current elder.
  ///
  /// The UI should listen to this stream to display a real-time list of medications.
  Stream<List<MedicationEntry>> medsStream() {
    if (_elderId.isEmpty) {
      // Return an empty stream if no elder is selected.
      return const Stream.empty();
    }
    return _firestoreService.medsForElder(_elderId);
  }

  /// Adds a new medication entry to Firestore.
  Future<DocumentReference<MedicationEntry>> addMedication(MedicationEntry m) async {
    if (_elderId.isEmpty) {
      throw Exception('Elder ID is not set. Cannot add medication.');
    }
    return await _firestoreService.addMed(_elderId, m);
    // No notifyListeners() needed as the UI should rely on the stream for updates.
  }

  /// Updates an existing medication entry in Firestore.
  Future<void> updateMedication(MedicationEntry m) async {
    if (_elderId.isEmpty || m.id.isEmpty) {
      throw Exception('Elder ID or Medication ID is missing. Cannot update medication.');
    }
    await _firestoreService.updateMed(_elderId, m);
  }

  /// Removes a medication entry from Firestore.
  Future<void> removeMedication(String medId) async {
    if (_elderId.isEmpty || medId.isEmpty) {
      throw Exception('Elder ID or Medication ID is missing. Cannot remove medication.');
    }
    await _firestoreService.deleteMed(_elderId, medId);
  }

  /// Checks a new drug's RxCUI against the elder's existing medications for interactions.
  Future<List<DrugInteraction>> warnIfInteractions(String newRxCui) async {
    if (_elderId.isEmpty || newRxCui.isEmpty) return [];

    // Fetch the current list of medications once for the check.
    final List<MedicationEntry> currentMeds = await medsStream().first;

    // Use a Set to collect unique RxCUIs.
    final allRxCuis = <String>{newRxCui};
    for (final med in currentMeds) {
      if (med.rxCui.isNotEmpty) {
        allRxCuis.add(med.rxCui);
      }
    }

    // The RxNav API requires at least two drugs to check for interactions.
    if (allRxCuis.length < 2) return [];

    return _rx.checkInteractions(allRxCuis.toList());
  }
}