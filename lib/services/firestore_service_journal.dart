// lib/services/firestore_service_journal.dart
//
// Journal-domain methods on FirestoreService: entries, reactions,
// display-name resolution, detailed entries, PRN follow-up, image folders.

part of 'firestore_service.dart';

extension JournalFirestoreOps on FirestoreService {
  // ---------------------------------------------------------------------------
  // _getDisplayName — resolves the current user's human-readable name.
  // ---------------------------------------------------------------------------
  Future<String> resolveDisplayName(String uid) async {
    if (uid.isNotEmpty &&
        FirestoreService._cachedDisplayNameUid == uid &&
        FirestoreService._cachedDisplayName != null &&
        FirestoreService._cachedDisplayName!.isNotEmpty) {
      return FirestoreService._cachedDisplayName!;
    }

    final authName = AuthService.currentUser?.displayName ?? '';
    if (authName.isNotEmpty) {
      FirestoreService._cachedDisplayNameUid = uid;
      FirestoreService._cachedDisplayName = authName;
      return authName;
    }

    try {
      final doc = await FirestoreService._usersRef.doc(uid).get();
      final firestoreName = doc.data()?.displayName ?? '';
      if (firestoreName.isNotEmpty) {
        FirestoreService._cachedDisplayNameUid = uid;
        FirestoreService._cachedDisplayName = firestoreName;
        return firestoreName;
      }
    } catch (e) {
      debugPrint('FirestoreService._getDisplayName Firestore lookup error: $e');
    }

    final email = AuthService.currentUser?.email ?? '';
    if (email.contains('@')) {
      final prefix = email.split('@').first;
      return prefix.isNotEmpty ? prefix : email;
    }
    return email.isNotEmpty ? email : 'Anonymous';
  }

  // ---------------------------------------------------------------------------
  // _getAvatarUrl
  // ---------------------------------------------------------------------------
  Future<String?> getAvatarUrl(String uid) async {
    if (uid.isNotEmpty &&
        FirestoreService._cachedAvatarUrlUid == uid &&
        FirestoreService._cachedAvatarUrl != null) {
      return FirestoreService._cachedAvatarUrl;
    }

    final authPhoto = AuthService.currentUser?.photoURL;
    if (authPhoto != null && authPhoto.isNotEmpty) {
      FirestoreService._cachedAvatarUrlUid = uid;
      FirestoreService._cachedAvatarUrl = authPhoto;
      return authPhoto;
    }

    try {
      final doc = await FirestoreService._usersRef.doc(uid).get();
      final firestoreAvatar = doc.data()?.avatarUrl;
      if (firestoreAvatar != null && firestoreAvatar.isNotEmpty) {
        FirestoreService._cachedAvatarUrlUid = uid;
        FirestoreService._cachedAvatarUrl = firestoreAvatar;
        return firestoreAvatar;
      }
    } catch (e) {
      debugPrint('FirestoreService._getAvatarUrl Firestore lookup error: $e');
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // backfillDisplayNames
  // ---------------------------------------------------------------------------
  Future<int> backfillDisplayNames(String elderId) async {
    if (elderId.isEmpty) return 0;

    final snapshot = await FirestoreService._journalEntriesRef
        .where('elderId', isEqualTo: elderId)
        .get();

    final needsFix = snapshot.docs.where((doc) {
      final name = doc.data().loggedByDisplayName ?? '';
      return name.contains('@');
    }).toList();

    if (needsFix.isEmpty) return 0;

    final Map<String, String> resolvedNames = {};
    for (final doc in needsFix) {
      final uid = doc.data().loggedByUserId;
      if (!resolvedNames.containsKey(uid)) {
        resolvedNames[uid] = await resolveDisplayName(uid);
      }
    }

    final List<DocumentReference> refs = [];
    final List<String> names = [];
    for (final doc in needsFix) {
      final uid = doc.data().loggedByUserId;
      final resolved = resolvedNames[uid] ?? '';
      if (resolved.isNotEmpty && !resolved.contains('@')) {
        refs.add(doc.reference);
        names.add(resolved);
      }
    }

    const int batchSize = 500;
    int updated = 0;
    for (int i = 0; i < refs.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, refs.length);
      final WriteBatch batch = FirestoreService._db.batch();
      for (int j = i; j < end; j++) {
        batch.update(refs[j], {'loggedByDisplayName': names[j]});
      }
      await batch.commit();
      updated += end - i;
    }

    debugPrint(
      'FirestoreService.backfillDisplayNames: updated $updated of '
      '${needsFix.length} email-name entries for elder $elderId.',
    );
    return updated;
  }

  // ---------------------------------------------------------------------------
  // Journal Entry CRUD
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
    final String? resolvedCreatorId = creatorId ?? AuthService.currentUserId;
    if (resolvedCreatorId == null || resolvedCreatorId.isEmpty) {
      throw Exception('User not logged in or creatorId not provided.');
    }
    final String creatorId0 = resolvedCreatorId;

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

    final String loggedByDisplayName =
        await resolveDisplayName(creatorId0);
    final String? loggedByAvatarUrl =
        await getAvatarUrl(creatorId0);

    final newEntry = JournalEntry(
      id: null,
      elderId: elderId,
      type: type,
      text: text,
      data: data,
      loggedByUserId: creatorId0,
      loggedByDisplayName: loggedByDisplayName,
      loggedByUserAvatarUrl: loggedByAvatarUrl,
      entryTimestamp: Timestamp.fromDate(timestamp0),
      dateString: dateOnly,
      visibleToUserIds: visibleToUserIds0,
      isPublic: isPublic0,
      createdAt: null,
      updatedAt: null,
      isCaregiverJournal:
          elderId == null && type.name == 'caregiverJournal',
    );

    await FirestoreService._journalEntriesRef.add(newEntry);
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

    Query<JournalEntry> query = FirestoreService._journalEntriesRef;

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
        .limit(200)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList())
        .handleError((e, st) {
      debugPrint('FirestoreService.getJournalEntriesStream error: $e\n$st');
      return <JournalEntry>[];
    });
  }

  Stream<List<JournalEntry>> getJournalEntriesStreamForElders({
    required List<String> elderIds,
    required String currentUserId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (elderIds.isEmpty) return const Stream.empty();

    Query<JournalEntry> query = FirestoreService._journalEntriesRef
        .where('elderId', whereIn: elderIds);

    if (startDate != null) {
      query = query.where('entryTimestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      final adjusted = DateTime(
          endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
      query = query.where('entryTimestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(adjusted));
    }

    return query
        .orderBy('entryTimestamp', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => d.data())
          .where((entry) {
            final visible = entry.visibleToUserIds ?? [];
            return visible.contains(currentUserId) ||
                visible.contains('all') ||
                (entry.isPublic ?? false);
          })
          .toList();
    }).handleError((e, st) {
      debugPrint(
          'FirestoreService.getJournalEntriesStreamForElders error: $e\n$st');
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
    final String? resolvedId = creatorId ?? AuthService.currentUserId;
    if (resolvedId == null || resolvedId.isEmpty) {
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

    await FirestoreService._journalEntriesRef.doc(entryId).update(updatePayload);
  }

  Future<void> deleteJournalEntry(String entryId) async {
    final String? currentUserId = AuthService.currentUserId;
    if (currentUserId == null) throw Exception('User not logged in.');
    if (entryId.isEmpty) {
      throw Exception('Entry ID cannot be empty for delete.');
    }
    await FirestoreService._journalEntriesRef.doc(entryId).delete();
  }

  // ---------------------------------------------------------------------------
  // Journal Entry Reactions
  // ---------------------------------------------------------------------------

  Future<void> addReaction(String entryId, String userId) async {
    if (entryId.isEmpty || userId.isEmpty) return;
    await FirestoreService._db.collection(FirestoreService._journalEntriesCollection).doc(entryId).update({
      'reactions.$userId': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeReaction(String entryId, String userId) async {
    if (entryId.isEmpty || userId.isEmpty) return;
    await FirestoreService._db.collection(FirestoreService._journalEntriesCollection).doc(entryId).update({
      'reactions.$userId': FieldValue.delete(),
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

      final DocumentReference detailedDocRef = await FirestoreService._db
          .collection('elders')
          .doc(elderId)
          .collection('days')
          .doc(dateString)
          .collection(journalType)
          .add(detailedEntryData);

      final DocumentReference timelineDocRef =
          await FirestoreService._journalEntriesRef.add(timelineSummaryEntry);

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
    final DocumentReference detailedDocRef = FirestoreService._db.doc(detailedEntryPath);

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
        await FirestoreService._journalEntriesRef.doc(timelineEntryId).delete();
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
  // PRN Follow-Up Response
  // ---------------------------------------------------------------------------

  Future<void> updatePrnFollowUp(String entryId, String response) async {
    if (entryId.isEmpty) return;
    await FirestoreService._journalEntriesRef.doc(entryId).update({
      'prnFollowUpResponse': response,
      'prnFollowUpRespondedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---------------------------------------------------------------------------
  // Image Folders (subcollection under elderProfiles)
  // ---------------------------------------------------------------------------

  Stream<List<Map<String, dynamic>>> getImageFoldersStream(String elderId) {
    if (elderId.isEmpty) return const Stream.empty();
    return FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('imageFolders')
        .orderBy('name')
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList())
        .handleError((e) {
      debugPrint('FirestoreService.getImageFoldersStream error: $e');
      return <Map<String, dynamic>>[];
    });
  }

  Future<String> createImageFolder(String elderId, String name) async {
    if (elderId.isEmpty) throw ArgumentError('elderId cannot be empty');
    final String? uid = AuthService.currentUserId;
    if (uid == null) throw Exception('User not logged in.');
    final ref = await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('imageFolders')
        .add({
      'name': name.trim(),
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> deleteImageFolder(String elderId, String folderId) async {
    if (elderId.isEmpty || folderId.isEmpty) return;
    await FirestoreService._db
        .collection(FirestoreService._elderProfilesCollection)
        .doc(elderId)
        .collection('imageFolders')
        .doc(folderId)
        .delete();
  }
}
