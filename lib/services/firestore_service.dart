// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:intl/intl.dart';

// Model Imports
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/calendar_event.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/models/medication_entry.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/budget_entry.dart';
import 'package:cecelia_care_flutter/models/income_entry.dart';
import 'package:cecelia_care_flutter/models/financial_asset.dart';
import 'package:cecelia_care_flutter/models/financial_liability.dart';

// Service Imports
import 'package:cecelia_care_flutter/services/auth_service.dart';

class FirestoreService {
  FirestoreService();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Collection Names ---
  static const String _elderProfilesCollection = 'elderProfiles';
  static const String _usersCollection = 'users';
  static const String _calendarEventsCollection = 'calendarEvents';
  static const String _journalEntriesCollection = 'journalEntries';
  static const String _budgetEntriesCollection = 'budget_entries';
  static const String _incomeEntriesCollection = 'income_entries';
  static const String _assetEntriesCollection = 'financial_assets';
  static const String _liabilityEntriesCollection = 'financial_liabilities';

  // --- Subcollection Names ---
  static const String _medicationsSubcollection = 'medications';
  static const String _categoryBudgetsSubcollection = 'categoryBudgets';

  // --- Journal types stored under elders/{id}/days/{date}/{type} ---
  static const List<String> _dayJournalTypes = [
    'medication',
    'sleep',
    'meal',
    'mood',
    'pain',
    'activity',
    'vital',
    'expense',
  ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static CollectionReference<T> _collection<T>({
    required String path,
    required T Function(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
    ) fromFirestore,
    required Map<String, Object?> Function(T model, SetOptions? options)
        toFirestore,
  }) {
    return _db.collection(path).withConverter<T>(
          fromFirestore: fromFirestore,
          toFirestore: toFirestore,
        );
  }

  static CollectionReference<T> _subCollection<T>({
    required String parentDocPath,
    required String subcollectionName,
    required T Function(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
    ) fromFirestore,
    required Map<String, Object?> Function(T model, SetOptions? options)
        toFirestore,
  }) {
    return _db
        .doc(parentDocPath)
        .collection(subcollectionName)
        .withConverter<T>(
          fromFirestore: fromFirestore,
          toFirestore: toFirestore,
        );
  }

  // ---------------------------------------------------------------------------
  // Typed Collection References
  // ---------------------------------------------------------------------------

  static final CollectionReference<ElderProfile> _elderProfilesRef =
      _collection<ElderProfile>(
    path: _elderProfilesCollection,
    fromFirestore: ElderProfile.fromFirestore,
    toFirestore: (profile, _) => profile.toFirestore(),
  );

  static final CollectionReference<UserProfile> _usersRef =
      _collection<UserProfile>(
    path: _usersCollection,
    fromFirestore: UserProfile.fromFirestore,
    toFirestore: (profile, _) => profile.toFirestore(),
  );

  static final CollectionReference<CalendarEvent> _calendarEventsRef =
      _collection<CalendarEvent>(
    path: _calendarEventsCollection,
    fromFirestore: CalendarEvent.fromFirestore,
    toFirestore: (event, _) => event.toFirestore(),
  );

  static final CollectionReference<JournalEntry> _journalEntriesRef =
      _collection<JournalEntry>(
    path: _journalEntriesCollection,
    fromFirestore: JournalEntry.fromFirestore,
    toFirestore: (entry, _) => entry.toFirestore(),
  );

  static final CollectionReference<BudgetEntry> _budgetEntriesRef =
      _collection<BudgetEntry>(
    path: _budgetEntriesCollection,
    fromFirestore: BudgetEntry.fromFirestore,
    toFirestore: (entry, _) => entry.toFirestore(),
  );

  static final CollectionReference<IncomeEntry> _incomeEntriesRef =
      _collection<IncomeEntry>(
    path: _incomeEntriesCollection,
    fromFirestore: IncomeEntry.fromFirestore,
    toFirestore: (entry, _) => entry.toFirestore(),
  );

  static final CollectionReference<FinancialAsset> _financialAssetsRef =
      _collection<FinancialAsset>(
    path: _assetEntriesCollection,
    fromFirestore: FinancialAsset.fromFirestore,
    toFirestore: (asset, _) => asset.toFirestore(),
  );

  static final CollectionReference<FinancialLiability>
      _financialLiabilitiesRef = _collection<FinancialLiability>(
    path: _liabilityEntriesCollection,
    fromFirestore: FinancialLiability.fromFirestore,
    toFirestore: (liability, _) => liability.toFirestore(),
  );

  // ---------------------------------------------------------------------------
  // Elder Profiles
  // ---------------------------------------------------------------------------

  Future<ElderProfile?> getElderProfile(String elderId) async {
    if (elderId.isEmpty) return null;
    try {
      final docSnapshot = await _elderProfilesRef.doc(elderId).get();
      if (docSnapshot.exists) return docSnapshot.data();
      return null;
    } catch (e) {
      // FIX: was print() — must be debugPrint() so it is stripped in release.
      debugPrint('FirestoreService.getElderProfile error ($elderId): $e');
      return null;
    }
  }

  Stream<List<ElderProfile>> getMyEldersStream(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) {
      return const Stream<List<ElderProfile>>.empty();
    }
    return _elderProfilesRef
        .where('caregiverUserIds', arrayContains: currentUserId)
        .orderBy('profileName')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<String> createElderProfile(Map<String, dynamic> data) async {
    final String? currentUid = AuthService.currentUserId;
    if (currentUid == null) {
      throw Exception('No logged-in user to assign as primary admin.');
    }

    final docRef = _elderProfilesRef.doc();
    final newProfile = ElderProfile(
      id: docRef.id,
      profileName: data['profileName'] as String? ?? '',
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      allergies:
          (data['allergies'] as List<dynamic>?)?.cast<String>() ?? [],
      dietaryRestrictions: data['dietaryRestrictions'] as String? ?? '',
      primaryAdminUserId: currentUid,
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      emergencyContactRelationship:
          data['emergencyContactRelationship'] as String?,
      // NEW: pick up photoUrl from create form data
      photoUrl: data['photoUrl'] as String?,
      caregiverUserIds: [currentUid],
      createdAt: null,
      updatedAt: null,
    );

    await docRef.set(newProfile);
    return docRef.id;
  }

  Future<void> updateElderProfile(
    String elderId,
    Map<String, dynamic> data,
  ) async {
    final Map<String, dynamic> updatedFields = {};

    if (data.containsKey('profileName') && data['profileName'] is String) {
      updatedFields['profileName'] = data['profileName'];
    }
    if (data.containsKey('dateOfBirth') && data['dateOfBirth'] is String) {
      updatedFields['dateOfBirth'] = data['dateOfBirth'];
    }
    if (data.containsKey('allergies') && data['allergies'] is List) {
      updatedFields['allergies'] =
          (data['allergies'] as List<dynamic>).cast<String>();
    }
    if (data.containsKey('dietaryRestrictions') &&
        data['dietaryRestrictions'] is String) {
      updatedFields['dietaryRestrictions'] = data['dietaryRestrictions'];
    }
    if (data.containsKey('preferredName')) {
      updatedFields['preferredName'] = data['preferredName'];
    }
    if (data.containsKey('sexualOrientation')) {
      updatedFields['sexualOrientation'] = data['sexualOrientation'];
    }
    if (data.containsKey('genderIdentity')) {
      updatedFields['genderIdentity'] = data['genderIdentity'];
    }
    if (data.containsKey('preferredPronouns')) {
      updatedFields['preferredPronouns'] = data['preferredPronouns'];
    }
    if (data.containsKey('emergencyContactName')) {
      updatedFields['emergencyContactName'] = data['emergencyContactName'];
    }
    if (data.containsKey('emergencyContactPhone')) {
      updatedFields['emergencyContactPhone'] = data['emergencyContactPhone'];
    }
    if (data.containsKey('emergencyContactRelationship')) {
      updatedFields['emergencyContactRelationship'] =
          data['emergencyContactRelationship'];
    }
    // NEW: always write photoUrl — null clears a previously set photo.
    if (data.containsKey('photoUrl')) {
      updatedFields['photoUrl'] = data['photoUrl'];
    }

    updatedFields['updatedAt'] = FieldValue.serverTimestamp();
    await _elderProfilesRef.doc(elderId).update(updatedFields);
  }

  Future<void> inviteCaregiverToElderProfile(
    String elderId,
    String targetEmail,
  ) async {
    final String? currentUid = AuthService.currentUserId;
    if (currentUid == null) throw Exception('Current user not authenticated.');

    final String? targetUid = await _getUidFromEmail(targetEmail);
    if (targetUid == null) {
      throw Exception('No user found with email $targetEmail.');
    }
    if (targetUid == currentUid) {
      throw Exception(
          'You cannot invite yourself to a profile you administer.');
    }

    final elderDoc = await _elderProfilesRef.doc(elderId).get();
    if (!elderDoc.exists) throw Exception('Elder profile not found.');
    final elderData = elderDoc.data();
    if (elderData == null) throw Exception('Elder profile data is null.');

    final List<String> currentCaregivers =
        List<String>.from(elderData.caregiverUserIds ?? []);
    if (currentCaregivers.contains(targetUid)) {
      throw Exception('$targetEmail is already a caregiver for this profile.');
    }

    await _elderProfilesRef.doc(elderId).update({
      'caregiverUserIds': FieldValue.arrayUnion([targetUid]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCaregiverFromElderProfile(
    String elderId,
    String caregiverIdToRemove,
  ) async {
    final String? currentUid = AuthService.currentUserId;
    if (currentUid == null) {
      throw Exception(
          'Current user not authenticated. Cannot perform this action.');
    }

    final elderDocRef = _elderProfilesRef.doc(elderId);
    final elderDocSnapshot = await elderDocRef.get();
    if (!elderDocSnapshot.exists) throw Exception('Elder profile not found.');

    final elderData = elderDocSnapshot.data();
    if (elderData == null) throw Exception('Elder profile data is null.');

    final String primaryAdminUserId = elderData.primaryAdminUserId;
    if (primaryAdminUserId != currentUid) {
      throw Exception(
          'Only the primary admin can remove caregivers from this profile.');
    }
    if (caregiverIdToRemove == primaryAdminUserId) {
      throw Exception(
          'The primary admin cannot be removed from the profile using this method.');
    }

    await elderDocRef.update({
      'caregiverUserIds': FieldValue.arrayRemove([caregiverIdToRemove]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String?> _getUidFromEmail(String email) async {
    final querySnapshot = await _usersRef
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;
    return querySnapshot.docs.first.id;
  }

  Future<List<UserProfile>> getAssociatedUsersForElder(
      String elderId) async {
    if (elderId.isEmpty) return [];
    try {
      final elderProfile = await getElderProfile(elderId);
      if (elderProfile == null) return [];

      final Set<String> userIds = {};
      if (elderProfile.primaryAdminUserId.isNotEmpty) {
        userIds.add(elderProfile.primaryAdminUserId);
      }
      userIds.addAll(elderProfile.caregiverUserIds);
      if (userIds.isEmpty) return [];

      final List<UserProfile> users = [];
      for (final uid in userIds) {
        final userDoc = await _usersRef.doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          users.add(userDoc.data()!);
        }
      }
      return users;
    } catch (e) {
      // FIX: was print() — must be debugPrint().
      debugPrint(
          'FirestoreService.getAssociatedUsersForElder error ($elderId): $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // NEW: clearElderData
  //
  // Deletes all day-level journal entries and medication definitions for a
  // given elder.
  //
  // Design notes:
  //  - All document references are collected first, then deleted in chunks of
  //    500 (the Firestore WriteBatch limit). This is far safer than the
  //    previous two-batch approach, which could leave data half-deleted if the
  //    second batch failed.
  //  - For true atomicity across very large datasets, move this logic to a
  //    Cloud Function. For typical caregiver app usage this is sufficient.
  // ---------------------------------------------------------------------------

  /// Deletes all journal entries (days subcollections) and medication
  /// definitions stored under [elderId].
  ///
  /// Throws if [elderId] is empty. Any Firestore error during deletion
  /// propagates to the caller so the UI can surface it.
  Future<void> clearElderData(String elderId) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty.');

    final List<DocumentReference> refsToDelete = [];

    // 1. Collect all day-level entry refs across every journal type.
    final daysSnapshot = await _db
        .collection('elders')
        .doc(elderId)
        .collection('days')
        .get();

    for (final dayDoc in daysSnapshot.docs) {
      for (final type in _dayJournalTypes) {
        final typeSnapshot =
            await dayDoc.reference.collection(type).get();
        for (final entryDoc in typeSnapshot.docs) {
          refsToDelete.add(entryDoc.reference);
        }
      }
    }

    // 2. Collect medication definition refs.
    final medicationsSnapshot = await _db
        .collection(_elderProfilesCollection)
        .doc(elderId)
        .collection(_medicationsSubcollection)
        .get();

    for (final doc in medicationsSnapshot.docs) {
      refsToDelete.add(doc.reference);
    }

    // 3. Delete everything in Firestore-safe chunks of 500.
    await _deleteInBatches(refsToDelete);

    debugPrint(
      'FirestoreService.clearElderData: deleted ${refsToDelete.length} '
      'documents for elder $elderId.',
    );
  }

  /// Commits [refs] as a series of [WriteBatch] deletes, chunked at 500
  /// operations each (the Firestore per-batch limit).
  Future<void> _deleteInBatches(List<DocumentReference> refs) async {
    const int batchSize = 500;
    for (int i = 0; i < refs.length; i += batchSize) {
      final chunk =
          refs.sublist(i, (i + batchSize).clamp(0, refs.length));
      final WriteBatch batch = _db.batch();
      for (final ref in chunk) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // Calendar Events
  // ---------------------------------------------------------------------------

  Future<DocumentReference<CalendarEvent>> addCalendarEvent(
      CalendarEvent event) async {
    try {
      return await _calendarEventsRef.add(event);
    } catch (e) {
      // FIX: was print() — must be debugPrint().
      debugPrint('FirestoreService.addCalendarEvent error: $e');
      rethrow;
    }
  }

  Future<CalendarEvent?> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> eventDataToUpdate,
  ) async {
    try {
      final docRef = _calendarEventsRef.doc(eventId);
      final Map<String, dynamic> payload = {
        ...eventDataToUpdate,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.update(payload);
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) return docSnapshot.data();
      return null;
    } catch (e) {
      // FIX: was print() — must be debugPrint().
      debugPrint(
          'FirestoreService.updateCalendarEvent error ($eventId): $e');
      return null;
    }
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    await _calendarEventsRef.doc(eventId).delete();
  }

  Stream<List<CalendarEvent>> getCalendarEventsStream(
    String elderId,
    DateTime startDate,
    DateTime endDate,
  ) {
    if (elderId.isEmpty) return const Stream.empty();

    final Timestamp startTimestamp = Timestamp.fromDate(startDate);
    final Timestamp endTimestamp = Timestamp.fromDate(
      DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999),
    );

    return _calendarEventsRef
        .where('elderId', isEqualTo: elderId)
        .where('startDateTime', isGreaterThanOrEqualTo: startTimestamp)
        .where('startDateTime', isLessThanOrEqualTo: endTimestamp)
        .orderBy('startDateTime')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
      // FIX: was print() — must be debugPrint().
      debugPrint(
          'FirestoreService.getCalendarEventsStream error ($elderId): $error');
      return <CalendarEvent>[];
    });
  }

  // ---------------------------------------------------------------------------
  // Journal Entries
  // ---------------------------------------------------------------------------

  Future<void> addJournalEntry({
    String? elderId,
    required EntryType type,
    String? text,
    Map<String, dynamic>? data,
    List<String>? visibleToUserIds,
    bool? isPublic,
    String? creatorId,
    DateTime? timestamp,
  }) async {
    final String creatorId0 = creatorId ?? AuthService.currentUserId!;
    if (creatorId0.isEmpty) {
      throw Exception('User not logged in or creatorId not provided.');
    }

    final DateTime timestamp0 = timestamp ?? DateTime.now();
    final String dateOnly = DateFormat('yyyy-MM-dd').format(timestamp0);

    bool isPublic0 = isPublic ?? false;
    List<String> visibleToUserIds0 = visibleToUserIds ?? [];

    if (isPublic0) {
      if (!visibleToUserIds0.contains('all')) visibleToUserIds0.add('all');
    } else {
      if (!visibleToUserIds0.contains(creatorId0)) {
        visibleToUserIds0.add(creatorId0);
      }
      if (elderId != null && elderId.isNotEmpty) {
        try {
          final elderProfile = await getElderProfile(elderId);
          if (elderProfile != null &&
              elderProfile.primaryAdminUserId.isNotEmpty &&
              !visibleToUserIds0
                  .contains(elderProfile.primaryAdminUserId)) {
            visibleToUserIds0.add(elderProfile.primaryAdminUserId);
          }
        } catch (e) {
          debugPrint(
              'Warning: Could not fetch elder profile $elderId to add '
              'primary admin to visibleToUserIds: $e');
        }
      }
    }
    visibleToUserIds0 = visibleToUserIds0.toSet().toList();

    final newEntry = JournalEntry(
      id: null,
      elderId: elderId,
      type: type,
      text: text,
      data: data,
      loggedByUserId: creatorId0,
      loggedByDisplayName: AuthService.currentUser?.displayName ??
          AuthService.currentUser?.email ??
          'Anonymous',
      loggedByUserAvatarUrl: AuthService.currentUser?.photoURL,
      entryTimestamp: Timestamp.fromDate(timestamp0),
      dateString: dateOnly,
      visibleToUserIds: visibleToUserIds0,
      isPublic: isPublic0,
      createdAt: null,
      updatedAt: null,
      isCaregiverJournal:
          elderId == null && type.name == 'caregiverJournal',
    );

    await _journalEntriesRef.add(newEntry);
  }

  Stream<List<JournalEntry>> getJournalEntriesStream({
    String? elderId,
    required String currentUserId,
    DateTime? startDate,
    DateTime? endDate,
    bool onlyMyLogs = false,
    EntryType? type,
  }) {
    if (currentUserId.isEmpty) return const Stream.empty();

    Query<JournalEntry> query = _journalEntriesRef;

    if (elderId == null && type?.name == 'caregiverJournal') {
      query = query
          .where('isCaregiverJournal', isEqualTo: true)
          .where('loggedByUserId', isEqualTo: currentUserId)
          .where('type', isEqualTo: 'caregiverJournal');
    } else if (elderId != null && elderId.isNotEmpty) {
      query = query.where('elderId', isEqualTo: elderId);

      if (onlyMyLogs) {
        query =
            query.where('loggedByUserId', isEqualTo: currentUserId);
      } else {
        query = query.where('visibleToUserIds',
            arrayContainsAny: [currentUserId, 'all']);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
    } else {
      return const Stream.empty();
    }

    if (startDate != null) {
      query = query.where('entryTimestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      final adjustedEndDate = DateTime(
          endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      query = query.where('entryTimestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(adjustedEndDate));
    }

    return query
        .orderBy('entryTimestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((e, st) {
      debugPrint('FirestoreService.getJournalEntriesStream error: $e\n$st');
      return <JournalEntry>[];
    });
  }

  Future<void> updateJournalEntry({
    required String entryId,
    String? elderId,
    required EntryType type,
    String? text,
    Map<String, dynamic>? data,
    List<String>? visibleToUserIds,
    bool? isPublic,
    String? creatorId,
    DateTime? timestamp,
  }) async {
    final String creatorId0 = creatorId ?? AuthService.currentUserId!;
    if (creatorId0.isEmpty) {
      throw Exception('User not logged in or creatorId not provided.');
    }
    if (entryId.isEmpty) {
      throw Exception('Entry ID cannot be empty for update.');
    }

    final Map<String, dynamic> updatePayload = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (text != null) updatePayload['text'] = text;
    if (data != null) updatePayload['data'] = data;
    if (visibleToUserIds != null) {
      updatePayload['visibleToUserIds'] = visibleToUserIds;
    }
    if (isPublic != null) updatePayload['isPublic'] = isPublic;
    if (timestamp != null) {
      updatePayload['entryTimestamp'] = Timestamp.fromDate(timestamp);
      updatePayload['dateString'] =
          DateFormat('yyyy-MM-dd').format(timestamp);
    }

    await _journalEntriesRef.doc(entryId).update(updatePayload);
  }

  Future<void> deleteJournalEntry(String entryId) async {
    final String? currentUserId = AuthService.currentUserId;
    if (currentUserId == null) throw Exception('User not logged in.');
    if (entryId.isEmpty) {
      throw Exception('Entry ID cannot be empty for delete.');
    }
    await _journalEntriesRef.doc(entryId).delete();
  }

  // ---------------------------------------------------------------------------
  // User Profiles
  // ---------------------------------------------------------------------------

  Future<void> setUserActiveElder(String uid, String? elderId) {
    final userDocRef = _usersRef.doc(uid);
    if (elderId != null && elderId.isNotEmpty) {
      return userDocRef.update({'activeElderId': elderId});
    } else {
      return userDocRef.update({'activeElderId': FieldValue.delete()});
    }
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final docSnapshot = await _usersRef.doc(uid).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      // FIX: was print() — must be debugPrint().
      debugPrint('FirestoreService.getUserProfile error ($uid): $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Medications
  // ---------------------------------------------------------------------------

  CollectionReference<MedicationEntry> _medicationsCollectionRef(
      String elderId) {
    return _subCollection<MedicationEntry>(
      parentDocPath: '$_elderProfilesCollection/$elderId',
      subcollectionName: _medicationsSubcollection,
      fromFirestore: MedicationEntry.fromFirestore,
      toFirestore: (med, _) => med.toFirestore(),
    );
  }

  Stream<List<MedicationEntry>> medsForElder(String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return _medicationsCollectionRef(elderId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
      // FIX: was print() — must be debugPrint().
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
    await _elderProfilesRef.doc(elderId).update({
      'priorityIndex': priorityIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Detailed Journal Entries (days subcollection + timeline link)
  // ---------------------------------------------------------------------------

  Future<DocumentReference?> addDetailedJournalEntryWithTimelineLink({
    required String elderId,
    required String dateString,
    required String journalType,
    required Map<String, dynamic> detailedEntryData,
    required JournalEntry timelineSummaryEntry,
  }) async {
    if (elderId.isEmpty || dateString.isEmpty || journalType.isEmpty) {
      debugPrint(
          'FirestoreService.addDetailedJournalEntryWithTimelineLink: '
          'elderId, dateString, or journalType is empty.');
      return null;
    }

    try {
      detailedEntryData['createdAt'] = FieldValue.serverTimestamp();
      detailedEntryData['updatedAt'] = FieldValue.serverTimestamp();

      final DocumentReference detailedDocRef = await _db
          .collection('elders')
          .doc(elderId)
          .collection('days')
          .doc(dateString)
          .collection(journalType)
          .add(detailedEntryData);

      final DocumentReference timelineDocRef =
          await _journalEntriesRef.add(timelineSummaryEntry);

      await detailedDocRef.update({'timelineEntryId': timelineDocRef.id});

      debugPrint(
        'FirestoreService: added detailed $journalType entry '
        '${detailedDocRef.id}, linked to timeline ${timelineDocRef.id} '
        'for elder $elderId.',
      );
      return detailedDocRef;
    } catch (e) {
      debugPrint(
          'FirestoreService.addDetailedJournalEntryWithTimelineLink '
          'error: $e');
      return null;
    }
  }

  Future<bool> deleteDetailedJournalEntryWithTimelineLink({
    required String elderId,
    required String dateString,
    required String journalType,
    required String detailedEntryId,
  }) async {
    if (elderId.isEmpty ||
        dateString.isEmpty ||
        journalType.isEmpty ||
        detailedEntryId.isEmpty) {
      debugPrint(
          'FirestoreService.deleteDetailedJournalEntryWithTimelineLink: '
          'one or more required IDs are empty.');
      return false;
    }

    final String detailedEntryPath =
        'elders/$elderId/days/$dateString/$journalType/$detailedEntryId';
    final DocumentReference detailedDocRef = _db.doc(detailedEntryPath);

    try {
      final DocumentSnapshot detailedDocSnapshot =
          await detailedDocRef.get();

      if (!detailedDocSnapshot.exists) {
        debugPrint(
            'FirestoreService: detailed entry $detailedEntryPath not '
            'found — may have already been deleted.');
        return true;
      }

      final Map<String, dynamic>? data =
          detailedDocSnapshot.data() as Map<String, dynamic>?;
      final String? timelineEntryId =
          data?['timelineEntryId'] as String?;

      if (timelineEntryId != null && timelineEntryId.isNotEmpty) {
        await _journalEntriesRef.doc(timelineEntryId).delete();
        debugPrint(
            'FirestoreService: deleted timeline entry $timelineEntryId '
            'linked from $detailedEntryPath.');
      } else {
        debugPrint(
            'FirestoreService: no timelineEntryId found in '
            '$detailedEntryPath — timeline entry not deleted.');
      }

      await detailedDocRef.delete();
      debugPrint(
          'FirestoreService: deleted detailed entry $detailedEntryPath.');
      return true;
    } catch (e) {
      debugPrint(
          'FirestoreService.deleteDetailedJournalEntryWithTimelineLink '
          'error ($detailedEntryPath): $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Financial — Budget Entries
  // ---------------------------------------------------------------------------

  Future<void> addBudgetEntry(BudgetEntry entry) async {
    await _budgetEntriesRef.add(entry);
  }

  Future<void> updateBudgetEntry(String entryId, BudgetEntry entry) async {
    await _budgetEntriesRef.doc(entryId).update(entry.toFirestore());
  }

  Future<void> deleteBudgetEntry(String entryId) async {
    await _budgetEntriesRef.doc(entryId).delete();
  }

  Stream<List<BudgetEntry>> getBudgetStreamForMonth({
    required String userId,
    String? careRecipientId,
    required DateTime month,
  }) {
    final DateTime startDate = DateTime(month.year, month.month, 1);
    final DateTime endDate =
        DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    Query<BudgetEntry> query = _budgetEntriesRef
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('userId', isEqualTo: userId);

    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query =
          query.where('careRecipientId', isEqualTo: careRecipientId);
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
      debugPrint(
          'FirestoreService.getBudgetStreamForMonth error: $error');
      return <BudgetEntry>[];
    });
  }

  // ---------------------------------------------------------------------------
  // Financial — Income Entries
  // ---------------------------------------------------------------------------

  Future<void> addIncomeEntry(IncomeEntry entry) async {
    await _incomeEntriesRef.add(entry);
  }

  Future<void> updateIncomeEntry(String entryId, IncomeEntry entry) async {
    await _incomeEntriesRef.doc(entryId).update(entry.toFirestore());
  }

  Future<void> deleteIncomeEntry(String entryId) async {
    await _incomeEntriesRef.doc(entryId).delete();
  }

  Stream<List<IncomeEntry>> getIncomeStreamForMonth({
    required String userId,
    String? careRecipientId,
    required DateTime month,
  }) {
    final DateTime startDate = DateTime(month.year, month.month, 1);
    final DateTime endDate =
        DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    Query<IncomeEntry> query = _incomeEntriesRef
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .where('userId', isEqualTo: userId);

    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query =
          query.where('careRecipientId', isEqualTo: careRecipientId);
    }

    return query
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((error) {
      debugPrint(
          'FirestoreService.getIncomeStreamForMonth error: $error');
      return <IncomeEntry>[];
    });
  }

  // ---------------------------------------------------------------------------
  // Financial — Assets
  // ---------------------------------------------------------------------------

  Future<void> addAsset(FinancialAsset asset) async {
    await _financialAssetsRef.add(asset);
  }

  Future<void> updateAsset(String assetId, FinancialAsset asset) async {
    await _financialAssetsRef.doc(assetId).update(asset.toFirestore());
  }

  Future<void> deleteAsset(String assetId) async {
    await _financialAssetsRef.doc(assetId).delete();
  }

  Stream<List<FinancialAsset>> getAssetsStream({
    required String userId,
    String? careRecipientId,
  }) {
    Query<FinancialAsset> query =
        _financialAssetsRef.where('userId', isEqualTo: userId);
    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query =
          query.where('careRecipientId', isEqualTo: careRecipientId);
    }
    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((e) {
      debugPrint('FirestoreService.getAssetsStream error: $e');
      return <FinancialAsset>[];
    });
  }

  // ---------------------------------------------------------------------------
  // Financial — Liabilities
  // ---------------------------------------------------------------------------

  Future<void> addLiability(FinancialLiability liability) async {
    await _financialLiabilitiesRef.add(liability);
  }

  Future<void> updateLiability(
      String liabilityId, FinancialLiability liability) async {
    await _financialLiabilitiesRef
        .doc(liabilityId)
        .update(liability.toFirestore());
  }

  Future<void> deleteLiability(String liabilityId) async {
    await _financialLiabilitiesRef.doc(liabilityId).delete();
  }

  Stream<List<FinancialLiability>> getLiabilitiesStream({
    required String userId,
    String? careRecipientId,
  }) {
    Query<FinancialLiability> query =
        _financialLiabilitiesRef.where('userId', isEqualTo: userId);
    if (careRecipientId != null && careRecipientId.isNotEmpty) {
      query =
          query.where('careRecipientId', isEqualTo: careRecipientId);
    }
    return query
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((e) {
      debugPrint('FirestoreService.getLiabilitiesStream error: $e');
      return <FinancialLiability>[];
    });
  }

  // ---------------------------------------------------------------------------
  // Financial — Category Budgets (Monthly)
  // ---------------------------------------------------------------------------

  Future<void> setCategoryBudgets({
    required String elderId,
    required Map<String, double> budgets,
    required DateTime month,
  }) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    final String yearMonth = DateFormat('yyyy-MM').format(month);
    await _db
        .collection(_elderProfilesCollection)
        .doc(elderId)
        .collection(_categoryBudgetsSubcollection)
        .doc(yearMonth)
        .set({'budgets': budgets}, SetOptions(merge: true));
  }

  Future<Map<String, double>> getCategoryBudgets({
    required String elderId,
    required DateTime month,
  }) async {
    if (elderId.isEmpty) return {};
    final String yearMonth = DateFormat('yyyy-MM').format(month);
    try {
      final docSnapshot = await _db
          .collection(_elderProfilesCollection)
          .doc(elderId)
          .collection(_categoryBudgetsSubcollection)
          .doc(yearMonth)
          .get();

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('budgets') && data['budgets'] is Map) {
          final rawMap = data['budgets'] as Map;
          return rawMap.map((key, value) =>
              MapEntry(key.toString(), (value as num).toDouble()));
        }
      }
      return {};
    } catch (error) {
      debugPrint(
          'FirestoreService.getCategoryBudgets error ($yearMonth): $error');
      return {};
    }
  }

  Stream<Map<String, double>> getCategoryBudgetsStream({
    required String elderId,
    required DateTime month,
  }) {
    if (elderId.isEmpty) return Stream.value(<String, double>{});
    final String yearMonth = DateFormat('yyyy-MM').format(month);
    return _db
        .collection(_elderProfilesCollection)
        .doc(elderId)
        .collection(_categoryBudgetsSubcollection)
        .doc(yearMonth)
        .snapshots()
        .map((docSnapshot) {
      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        if (data.containsKey('budgets') && data['budgets'] is Map) {
          final rawMap = data['budgets'] as Map;
          return rawMap.map((key, value) =>
              MapEntry(key.toString(), (value as num).toDouble()));
        }
      }
      return <String, double>{};
    }).handleError((error) {
      debugPrint(
          'FirestoreService.getCategoryBudgetsStream error ($yearMonth): '
          '$error');
      return <String, double>{};
    });
  }
}
