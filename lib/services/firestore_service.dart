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
import 'package:cecelia_care_flutter/models/succession_plan.dart';
import 'package:cecelia_care_flutter/models/taper_schedule.dart';
import 'package:cecelia_care_flutter/models/insurance_policy.dart';
import 'package:cecelia_care_flutter/models/insurance_claim.dart';

// Service Imports
import 'package:cecelia_care_flutter/services/auth_service.dart';

// Domain-specific extensions live in part files so the implementation can
// be split across multiple files while still sharing this library's
// private state. New domains follow the same pattern.
part 'firestore_service_financial.dart';
part 'firestore_service_journal.dart';
part 'firestore_service_assessment.dart';
part 'firestore_service_care_team.dart';

class FirestoreService {
  FirestoreService();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // Display name cache
  //
  // addJournalEntry() is called on every log action. Rather than re-fetching
  // the Firestore user profile on every write, we cache the resolved name
  // keyed by UID and clear it when a new UID is seen (i.e. after sign-in).
  // This is safe for single-user sessions and cheap for multi-user scenarios.
  // ---------------------------------------------------------------------------
  static String? _cachedDisplayName;
  static String? _cachedDisplayNameUid;
  static String? _cachedAvatarUrl;
  static String? _cachedAvatarUrlUid;

  /// Clears the display-name and avatar caches so the next journal write
  /// re-fetches from Firestore. Call after a user updates their profile or
  /// after sign-out / sign-in.
  static void clearProfileCache() {
    _cachedDisplayName = null;
    _cachedDisplayNameUid = null;
    _cachedAvatarUrl = null;
    _cachedAvatarUrlUid = null;
  }

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
        .limit(50) // safety cap — caregivers rarely manage > 20 elders
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
    if (data.containsKey('sensoryPreferences')) {
      updatedFields['sensoryPreferences'] = data['sensoryPreferences'];
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
        List<String>.from(elderData.caregiverUserIds);
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

    // Fetch all journal-type subcollections in parallel per day, and all
    // days in parallel, to avoid N×M sequential round-trips.
    final futures = <Future<List<DocumentReference>>>[];
    for (final dayDoc in daysSnapshot.docs) {
      for (final type in _dayJournalTypes) {
        futures.add(
          dayDoc.reference.collection(type).get().then(
                (snap) => snap.docs.map((d) => d.reference).toList(),
              ),
        );
      }
    }
    final results = await Future.wait(futures);
    for (final refs in results) {
      refsToDelete.addAll(refs);
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
  // Recurrence Expansion Helper
  // ---------------------------------------------------------------------------

  /// Generates recurring [CalendarEvent] instances from a parent event and
  /// writes them into [batch]. Returns the number of instances written and
  /// the (possibly new) batch + opCount after any intermediate commits.
  static Future<({WriteBatch batch, int opCount, int created})>
      _expandRecurrence({
    required CalendarEvent event,
    required String parentId,
    required WriteBatch batch,
    required int opCount,
    int maxOps = 499,
  }) async {
    int created = 0;
    var currentBatch = batch;
    var currentOpCount = opCount;

    if (event.recurrenceRule == null || event.recurrenceEndDate == null) {
      return (batch: currentBatch, opCount: currentOpCount, created: created);
    }

    final rule = event.recurrenceRule!;
    final endDate = event.recurrenceEndDate!.toDate();
    final startDate = event.startDateTime.toDate();
    final duration = event.endDateTime != null
        ? event.endDateTime!.toDate().difference(startDate)
        : Duration.zero;

    var current = startDate;
    while (true) {
      DateTime next;
      if (rule == 'daily') {
        next = current.add(const Duration(days: 1));
      } else if (rule == 'weekly') {
        next = current.add(const Duration(days: 7));
      } else if (rule == 'monthly') {
        next = DateTime(current.year, current.month + 1, current.day,
            current.hour, current.minute);
      } else {
        break;
      }
      if (next.isAfter(endDate)) break;
      current = next;

      final instance = CalendarEvent(
        elderId: event.elderId,
        createdBy: event.createdBy,
        createdByDisplayName: event.createdByDisplayName,
        title: event.title,
        eventType: event.eventType,
        allDay: event.allDay,
        notes: event.notes,
        startDateTime: Timestamp.fromDate(current),
        endDateTime: duration != Duration.zero
            ? Timestamp.fromDate(current.add(duration))
            : null,
        recurrenceRule: null,
        recurrenceParentId: parentId,
        recurrenceEndDate: event.recurrenceEndDate,
      );

      final docRef = _db.collection(_calendarEventsCollection).doc();
      currentBatch.set(docRef, instance.toFirestore());
      currentOpCount++;
      created++;

      if (currentOpCount >= maxOps) {
        await currentBatch.commit();
        currentBatch = _db.batch();
        currentOpCount = 0;
      }
    }

    return (batch: currentBatch, opCount: currentOpCount, created: created);
  }

  // ---------------------------------------------------------------------------
  // Calendar Events
  // ---------------------------------------------------------------------------

  Future<DocumentReference<CalendarEvent>> addCalendarEvent(
      CalendarEvent event) async {
    try {
      final parentRef = await _calendarEventsRef.add(event);

      if (event.recurrenceRule != null && event.recurrenceEndDate != null) {
        final result = await _expandRecurrence(
          event: event,
          parentId: parentRef.id,
          batch: _db.batch(),
          opCount: 0,
        );
        if (result.opCount > 0) await result.batch.commit();
      }

      return parentRef;
    } catch (e) {
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

  Future<void> deleteRecurringEvents(String parentId) async {
    // Delete all instances that reference this parent
    final instances = await _db
        .collection(_calendarEventsCollection)
        .where('recurrenceParentId', isEqualTo: parentId)
        .get();

    WriteBatch batch = _db.batch();
    int opCount = 0;
    const int maxOps = 499;

    for (final doc in instances.docs) {
      batch.delete(doc.reference);
      opCount++;
      if (opCount >= maxOps) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    // Also delete the parent event itself
    batch.delete(_db.collection(_calendarEventsCollection).doc(parentId));
    await batch.commit();
  }

  // ---------------------------------------------------------------------------
  // applyCarePlanTemplate — batch-creates calendar events from a template.
  //
  // Each event in [events] is treated as a "parent" event. If the event has
  // a recurrenceRule + recurrenceEndDate, recurring instances are generated
  // (same logic as addCalendarEvent). All writes are consolidated into
  // minimal WriteBatch commits for efficiency.
  //
  // Returns the total number of documents created.
  // ---------------------------------------------------------------------------
  Future<int> applyCarePlanTemplate(List<CalendarEvent> events) async {
    if (events.isEmpty) return 0;

    int totalCreated = 0;
    WriteBatch batch = _db.batch();
    int opCount = 0;
    const int maxOps = 499;

    try {
      for (final event in events) {
        // Create the parent event
        final parentRef =
            _db.collection(_calendarEventsCollection).doc();
        batch.set(parentRef, event.toFirestore());
        opCount++;
        totalCreated++;

        if (opCount >= maxOps) {
          await batch.commit();
          batch = _db.batch();
          opCount = 0;
        }

        // Generate recurring instances if applicable
        final result = await _expandRecurrence(
          event: event,
          parentId: parentRef.id,
          batch: batch,
          opCount: opCount,
          maxOps: maxOps,
        );
        batch = result.batch;
        opCount = result.opCount;
        totalCreated += result.created;
      }

      // Final commit for remaining operations
      if (opCount > 0) await batch.commit();

      debugPrint(
        'FirestoreService.applyCarePlanTemplate: created '
        '$totalCreated calendar events from ${events.length} template items.',
      );
      return totalCreated;
    } catch (e) {
      debugPrint('FirestoreService.applyCarePlanTemplate error: $e');
      rethrow;
    }
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
        .limit(200)
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

  // Journal, assessment, care-team, and financial methods live in part files.
  // See `part` directives at the top of this file.
}
