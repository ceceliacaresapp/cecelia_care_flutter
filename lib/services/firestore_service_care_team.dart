// lib/services/firestore_service_care_team.dart
//
// Care-team-domain methods on FirestoreService: user profiles, medications,
// elder priority, shift definitions, custom entry types, care tasks,
// respite providers, vault documents, succession plans.

part of 'firestore_service.dart';

extension CareTeamFirestoreOps on FirestoreService {
  // ---------------------------------------------------------------------------
  // User Profiles
  // ---------------------------------------------------------------------------

  Future<void> setUserActiveElder(String uid, String? elderId) {
    final userDocRef = FirestoreService._usersRef.doc(uid);
    if (elderId != null && elderId.isNotEmpty) {
      return userDocRef.update({'activeElderId': elderId});
    } else {
      return userDocRef.update({'activeElderId': FieldValue.delete()});
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final docSnapshot = await FirestoreService._usersRef.doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('FirestoreService.getUserProfile error ($uid): $e');
      return null;
    }
  }

  Future<void> updateLastActiveAt(String uid) async {
    if (uid.isEmpty) return;
    try {
      await FirestoreService._usersRef.doc(uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('FirestoreService.updateLastActiveAt error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Medications
  // ---------------------------------------------------------------------------

  CollectionReference<MedicationEntry> _medicationsCollectionRef(
      String elderId) {
    return FirestoreService._subCollection<MedicationEntry>(
      parentDocPath:
          '${FirestoreService._elderProfilesCollection}/$elderId',
      subcollectionName: FirestoreService._medicationsSubcollection,
      fromFirestore: MedicationEntry.fromFirestore,
      toFirestore: (med, _) => med.toFirestore(),
    );
  }

  Stream<List<MedicationEntry>> medsForElder(String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return _medicationsCollectionRef(elderId)
        .orderBy('name')
        .limit(500)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
      debugPrint(
          'FirestoreService.medsForElder stream error ($elderId): $error');
      return <MedicationEntry>[];
    });
  }

  Future<DocumentReference<MedicationEntry>> addMed(
      String elderId, MedicationEntry e) async {
    if (elderId.isEmpty) {
      throw ArgumentError('elderId cannot be empty for addMed');
    }
    return _medicationsCollectionRef(elderId).add(e);
  }

  Future<void> updateMed(String elderId, MedicationEntry e) async {
    if (elderId.isEmpty || e.id.isEmpty) {
      throw ArgumentError(
          'elderId and medicationEntry.id cannot be empty for updateMed');
    }
    return _medicationsCollectionRef(elderId)
        .doc(e.id)
        .update(e.toFirestore());
  }

  Future<void> deleteMed(String elderId, String medId) async {
    if (elderId.isEmpty || medId.isEmpty) {
      throw ArgumentError(
          'elderId and medId cannot be empty for deleteMed');
    }
    return _medicationsCollectionRef(elderId).doc(medId).delete();
  }

  // ---------------------------------------------------------------------------
  // Elder Priority
  // ---------------------------------------------------------------------------

  Future<void> updateElderPriority({
    required String elderId,
    required int priorityIndex,
  }) async {
    if (elderId.isEmpty) {
      throw ArgumentError('elderId cannot be empty for updateElderPriority');
    }
    await FirestoreService._elderProfilesRef.doc(elderId).update({
      'priorityIndex': priorityIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Shift Definitions
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getShiftDefinitionsStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('shiftDefinitions')
        .orderBy('startTime')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getShiftDefinitionsStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addShiftDefinition(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('shiftDefinitions')
        .add(data);
    return ref.id;
  }

  Future<void> updateShiftDefinition(
      String elderId, String shiftId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || shiftId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('shiftDefinitions')
        .doc(shiftId)
        .update(data);
  }

  Future<void> deleteShiftDefinition(
      String elderId, String shiftId) async {
    if (elderId.isEmpty || shiftId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('shiftDefinitions')
        .doc(shiftId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Custom Entry Types
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getCustomEntryTypesStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('customEntryTypes')
        .orderBy('name')
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getCustomEntryTypesStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addCustomEntryType(
      String elderId, dynamic type) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('customEntryTypes')
        .add(type.toFirestore());
    return ref.id;
  }

  Future<void> updateCustomEntryType(
      String elderId, String typeId, dynamic type) async {
    if (elderId.isEmpty || typeId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('customEntryTypes')
        .doc(typeId)
        .update(type.toFirestore());
  }

  Future<void> deleteCustomEntryType(
      String elderId, String typeId) async {
    if (elderId.isEmpty || typeId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('customEntryTypes')
        .doc(typeId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Respite Providers
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getRespiteProvidersByZipPrefix(
      String zipPrefix) async {
    if (zipPrefix.isEmpty) return [];
    try {
      final snapshot = await FirestoreService._db
          .collection('respiteProviders')
          .where('zipPrefix', isEqualTo: zipPrefix)
          .limit(25)
          .get();
      return snapshot.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList();
    } catch (e) {
      debugPrint('FirestoreService.getRespiteProvidersByZipPrefix error: $e');
      return [];
    }
  }

  Future<String> addRespiteProvider(Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection('respiteProviders')
        .add(data);
    return ref.id;
  }

  Future<void> deleteRespiteProvider(String docId) async {
    if (docId.isEmpty) return;
    await FirestoreService._db.collection('respiteProviders').doc(docId).delete();
  }

  // ---------------------------------------------------------------------------
  // Vault Documents
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getVaultDocumentsStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('vaultDocuments')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getVaultDocumentsStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addVaultDocument(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('vaultDocuments')
        .add(data);
    return ref.id;
  }

  Future<void> updateVaultDocument(
      String elderId, String docId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || docId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('vaultDocuments')
        .doc(docId)
        .update(data);
  }

  Future<void> deleteVaultDocument(
      String elderId, String docId) async {
    if (elderId.isEmpty || docId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('vaultDocuments')
        .doc(docId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Care Tasks
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getActiveTasksStream(String elderId) {
    if (elderId.isEmpty) return Stream.value(const []);
    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('careTasks')
        .where('status', whereIn: ['open', 'accepted'])
        .limit(100)
        .snapshots()
        .listen(
      (snap) {
        final list = snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList();
        list.sort((a, b) {
          final ad = a['dueDate'] as Timestamp?;
          final bd = b['dueDate'] as Timestamp?;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
        controller.add(list);
      },
      onError: (e) {
        debugPrint('FirestoreService.getActiveTasksStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> getCompletedTasksStream(String elderId) {
    if (elderId.isEmpty) return Stream.value(const []);
    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('careTasks')
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .limit(20)
        .snapshots()
        .listen(
      (snap) {
        controller.add(snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
      },
      onError: (e) {
        debugPrint('FirestoreService.getCompletedTasksStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Stream<List<Map<String, dynamic>>> getMyTasksStream(
      String elderId, String userId) {
    if (elderId.isEmpty || userId.isEmpty) return Stream.value(const []);
    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('careTasks')
        .where('assignedTo', isEqualTo: userId)
        .where('status', whereIn: ['open', 'accepted'])
        .limit(50)
        .snapshots()
        .listen(
      (snap) {
        final list = snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList();
        list.sort((a, b) {
          final ad = a['dueDate'] as Timestamp?;
          final bd = b['dueDate'] as Timestamp?;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return ad.compareTo(bd);
        });
        controller.add(list);
      },
      onError: (e) {
        debugPrint('FirestoreService.getMyTasksStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Future<String> addCareTask(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('careTasks')
        .add(data);
    return ref.id;
  }

  Future<void> updateCareTask(
      String elderId, String taskId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || taskId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('careTasks')
        .doc(taskId)
        .update(data);
  }

  Future<void> deleteCareTask(String elderId, String taskId) async {
    if (elderId.isEmpty || taskId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('careTasks')
        .doc(taskId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Succession Plan ("If I Can't Be Here")
  //
  // One plan per elder, stored at:
  //   elderProfiles/{elderId}/successionPlan/primary
  //
  // Fixed doc id (kSuccessionPlanDocId) — no list/find step required.
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _successionPlanRef(String elderId) {
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('successionPlan')
        .doc(kSuccessionPlanDocId);
  }

  /// Live stream of the current succession plan. Emits an empty plan when
  /// the document does not yet exist so the UI can render blank sections
  /// without special-casing "not found".
  Stream<SuccessionPlan> successionPlanStream(String elderId) {
    if (elderId.isEmpty) return Stream.value(SuccessionPlan.empty(''));
    return _successionPlanRef(elderId).snapshots().map((snap) {
      if (!snap.exists) return SuccessionPlan.empty(elderId);
      return SuccessionPlan.fromFirestore(snap, null);
    }).handleError((e) {
      debugPrint('FirestoreService.successionPlanStream error: $e');
      return SuccessionPlan.empty(elderId);
    });
  }

  /// One-shot read. Returns an empty plan if no document exists.
  Future<SuccessionPlan> getSuccessionPlan(String elderId) async {
    if (elderId.isEmpty) return SuccessionPlan.empty('');
    try {
      final snap = await _successionPlanRef(elderId).get();
      if (!snap.exists) return SuccessionPlan.empty(elderId);
      return SuccessionPlan.fromFirestore(snap, null);
    } catch (e) {
      debugPrint('FirestoreService.getSuccessionPlan error ($elderId): $e');
      return SuccessionPlan.empty(elderId);
    }
  }

  /// Full-document upsert. Uses merge:true so partial updates from older
  /// clients never blow away newer fields.
  Future<void> saveSuccessionPlan(SuccessionPlan plan) async {
    if (plan.elderId.isEmpty) {
      throw ArgumentError('elderId cannot be empty for saveSuccessionPlan');
    }
    await _successionPlanRef(plan.elderId)
        .set(plan.toFirestore(), SetOptions(merge: true));
  }

  /// Deletes the succession plan document. Use with caution — irreversible.
  Future<void> deleteSuccessionPlan(String elderId) async {
    if (elderId.isEmpty) return;
    await _successionPlanRef(elderId).delete();
  }

  // ---------------------------------------------------------------------------
  // Taper Schedules
  //
  // One taper per doc under:
  //   elderProfiles/{elderId}/taperSchedules/{taperId}
  //
  // Multiple active/historical tapers per elder are allowed (e.g., a
  // prednisone burst followed six months later by an SSRI wean).
  // ---------------------------------------------------------------------------

  CollectionReference<Map<String, dynamic>> _taperSchedulesRef(String elderId) {
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('taperSchedules');
  }

  /// Live list of all taper schedules for an elder, ordered so active
  /// tapers surface first, then by start date descending.
  Stream<List<TaperSchedule>> taperSchedulesStream(String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return _taperSchedulesRef(elderId)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TaperSchedule.fromFirestore(d, null)).toList())
        .handleError((e) {
      debugPrint('FirestoreService.taperSchedulesStream error: $e');
      return <TaperSchedule>[];
    });
  }

  /// Watches a single taper by id. Emits an empty schedule if it
  /// vanishes (so screens don't crash on delete-then-back).
  Stream<TaperSchedule> taperScheduleStream({
    required String elderId,
    required String taperId,
  }) {
    if (elderId.isEmpty || taperId.isEmpty) {
      return Stream.value(TaperSchedule.empty(elderId));
    }
    return _taperSchedulesRef(elderId).doc(taperId).snapshots().map((snap) {
      if (!snap.exists) return TaperSchedule.empty(elderId);
      return TaperSchedule.fromFirestore(snap, null);
    });
  }

  Future<TaperSchedule?> getTaperSchedule({
    required String elderId,
    required String taperId,
  }) async {
    if (elderId.isEmpty || taperId.isEmpty) return null;
    try {
      final snap = await _taperSchedulesRef(elderId).doc(taperId).get();
      if (!snap.exists) return null;
      return TaperSchedule.fromFirestore(snap, null);
    } catch (e) {
      debugPrint('FirestoreService.getTaperSchedule error: $e');
      return null;
    }
  }

  /// Creates a new taper. Generates an id if the plan's id is empty.
  /// Returns the id used.
  Future<String> createTaperSchedule(TaperSchedule plan) async {
    if (plan.elderId.isEmpty) {
      throw ArgumentError('elderId cannot be empty for createTaperSchedule');
    }
    final ref = plan.id.isEmpty
        ? _taperSchedulesRef(plan.elderId).doc()
        : _taperSchedulesRef(plan.elderId).doc(plan.id);
    await ref.set(plan.toFirestore());
    return ref.id;
  }

  /// Updates an existing taper. Uses merge:true so partial saves don't
  /// clobber fields written by other clients.
  Future<void> updateTaperSchedule(TaperSchedule plan) async {
    if (plan.elderId.isEmpty || plan.id.isEmpty) {
      throw ArgumentError('elderId and id required for updateTaperSchedule');
    }
    await _taperSchedulesRef(plan.elderId)
        .doc(plan.id)
        .set(plan.toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteTaperSchedule({
    required String elderId,
    required String taperId,
  }) async {
    if (elderId.isEmpty || taperId.isEmpty) return;
    await _taperSchedulesRef(elderId).doc(taperId).delete();
  }
}
