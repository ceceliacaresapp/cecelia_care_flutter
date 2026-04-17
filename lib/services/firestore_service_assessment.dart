// lib/services/firestore_service_assessment.dart
//
// Assessment-domain methods on FirestoreService: fall risk, cognitive,
// skin integrity, turning logs, wandering, discharge checklists,
// behavioral entries, wound entries.

part of 'firestore_service.dart';

extension AssessmentFirestoreOps on FirestoreService {
  // ---------------------------------------------------------------------------
  // Behavioral Entries
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getBehavioralEntriesStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('behavioralEntries')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getBehavioralEntriesStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addBehavioralEntry(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('behavioralEntries')
        .add(data);
    return ref.id;
  }

  Future<void> updateBehavioralEntry(
      String elderId, String entryId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || entryId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('behavioralEntries')
        .doc(entryId)
        .update(data);
  }

  Future<void> deleteBehavioralEntry(
      String elderId, String entryId) async {
    if (elderId.isEmpty || entryId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('behavioralEntries')
        .doc(entryId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Music Reactions
  //
  // Per-elder log of songs played and how the care recipient responded.
  // Stored at elderProfiles/{elderId}/musicReactions. Insight rollups
  // (top calming / top agitating / decade heatmap) are computed
  // client-side from the stream — see MusicInsights.compute().
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getMusicReactionsStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('musicReactions')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList())
        .handleError((e) {
      debugPrint('FirestoreService.getMusicReactionsStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addMusicReaction(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('musicReactions')
        .add(data);
    return ref.id;
  }

  Future<void> updateMusicReaction(
      String elderId, String entryId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || entryId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('musicReactions')
        .doc(entryId)
        .update(data);
  }

  Future<void> deleteMusicReaction(
      String elderId, String entryId) async {
    if (elderId.isEmpty || entryId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('musicReactions')
        .doc(entryId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Incident Reports
  //
  // Regulatory-grade incident documentation stored at
  // elderProfiles/{elderId}/incidentReports. Timestamped, auditable,
  // and exportable as a compliance PDF.
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getIncidentReportsStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('incidentReports')
        .orderBy('occurredAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList())
        .handleError((e) {
      debugPrint('FirestoreService.getIncidentReportsStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addIncidentReport(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('incidentReports')
        .add(data);
    return ref.id;
  }

  Future<void> updateIncidentReport(
      String elderId, String reportId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || reportId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('incidentReports')
        .doc(reportId)
        .update(data);
  }

  Future<void> deleteIncidentReport(
      String elderId, String reportId) async {
    if (elderId.isEmpty || reportId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('incidentReports')
        .doc(reportId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // Wandering Assessments
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getWanderingAssessmentsStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('wanderingAssessments')
        .orderBy('createdAt', descending: true)
        .limit(6)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList())
        .handleError((e) {
      debugPrint(
          'FirestoreService.getWanderingAssessmentsStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addWanderingAssessment(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('wanderingAssessments')
        .add(data);
    return ref.id;
  }

  Future<void> updateWanderingAssessment(
      String elderId, String assessmentId,
      Map<String, dynamic> data) async {
    if (elderId.isEmpty || assessmentId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('wanderingAssessments')
        .doc(assessmentId)
        .update(data);
  }

  // ---------------------------------------------------------------------------
  // Cognitive Assessments
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getCognitiveAssessmentsStream(
      String elderId) {
    if (elderId.isEmpty) return Stream.value(const []);
    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('cognitiveAssessments')
        .orderBy('createdAt', descending: true)
        .limit(12)
        .snapshots()
        .listen(
      (snap) {
        controller.add(snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
      },
      onError: (e) {
        debugPrint(
            'FirestoreService.getCognitiveAssessmentsStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Future<String> addCognitiveAssessment(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('cognitiveAssessments')
        .add(data);
    return ref.id;
  }

  Future<void> updateCognitiveAssessment(
      String elderId, String id, Map<String, dynamic> data) async {
    if (elderId.isEmpty || id.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('cognitiveAssessments')
        .doc(id)
        .update(data);
  }

  // ---------------------------------------------------------------------------
  // Discharge Checklists
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getDischargeChecklistsStream(
      String elderId) {
    if (elderId.isEmpty) return Stream.value(const []);
    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('dischargeChecklists')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .listen(
      (snap) {
        controller.add(snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
      },
      onError: (e) {
        debugPrint(
            'FirestoreService.getDischargeChecklistsStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Future<String> addDischargeChecklist(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('dischargeChecklists')
        .add(data);
    return ref.id;
  }

  Future<void> updateDischargeChecklist(
      String elderId, String checklistId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || checklistId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('dischargeChecklists')
        .doc(checklistId)
        .update(data);
  }

  // ---------------------------------------------------------------------------
  // Fall Risk Assessments
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getFallRiskAssessmentsStream(
      String elderId) {
    if (elderId.isEmpty) return Stream.value(const []);
    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('fallRiskAssessments')
        .orderBy('createdAt', descending: true)
        .limit(6)
        .snapshots()
        .listen(
      (snap) {
        controller.add(snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
      },
      onError: (e) {
        debugPrint(
            'FirestoreService.getFallRiskAssessmentsStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Future<String> addFallRiskAssessment(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('fallRiskAssessments')
        .add(data);
    return ref.id;
  }

  Future<void> updateFallRiskAssessment(
      String elderId, String assessmentId,
      Map<String, dynamic> data) async {
    if (elderId.isEmpty || assessmentId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('fallRiskAssessments')
        .doc(assessmentId)
        .update(data);
  }

  // ---------------------------------------------------------------------------
  // Skin Assessments
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getSkinAssessmentsStream(
      String elderId) {
    if (elderId.isEmpty) return Stream.value(const []);
    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('skinAssessments')
        .orderBy('createdAt', descending: true)
        .limit(6)
        .snapshots()
        .listen(
      (snap) {
        controller.add(snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
      },
      onError: (e) {
        debugPrint('FirestoreService.getSkinAssessmentsStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Future<String> addSkinAssessment(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('skinAssessments')
        .add(data);
    return ref.id;
  }

  Future<void> updateSkinAssessment(
      String elderId, String assessmentId,
      Map<String, dynamic> data) async {
    if (elderId.isEmpty || assessmentId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('skinAssessments')
        .doc(assessmentId)
        .update(data);
  }

  // ---------------------------------------------------------------------------
  // Turning Logs
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getTurningLogsStream(
      String elderId, {DateTime? startDate}) {
    if (elderId.isEmpty) return Stream.value(const []);
    Query query = FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('turningLogs');

    if (startDate != null) {
      query = query.where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    final controller = StreamController<List<Map<String, dynamic>>>();
    final sub = query
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen(
      (snap) {
        controller.add(snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
      },
      onError: (e) {
        debugPrint('FirestoreService.getTurningLogsStream error: $e');
        controller.add(const []);
      },
    );
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  Future<String> addTurningLog(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('turningLogs')
        .add(data);
    return ref.id;
  }

  // ---------------------------------------------------------------------------
  // Wound Entries
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getWoundEntriesStream(
      String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('woundEntries')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getWoundEntriesStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> addWoundEntry(
      String elderId, Map<String, dynamic> data) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('woundEntries')
        .add(data);
    return ref.id;
  }

  Future<void> updateWoundEntry(
      String elderId, String entryId, Map<String, dynamic> data) async {
    if (elderId.isEmpty || entryId.isEmpty) return;
    data['updatedAt'] = FieldValue.serverTimestamp();
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('woundEntries')
        .doc(entryId)
        .update(data);
  }

  Future<void> deleteWoundEntry(
      String elderId, String entryId) async {
    if (elderId.isEmpty || entryId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('woundEntries')
        .doc(entryId)
        .delete();
  }
}
