import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/utils/string_extensions.dart';

class JournalServiceProvider extends ChangeNotifier {
  final FirestoreService _firestoreService;
  ElderProfile? _activeElder;
  final BadgeProvider _badgeProvider;
  String? _errorMessage;

  JournalServiceProvider({
    required ElderProfile? activeElder,
    required FirestoreService firestoreService,
    required BadgeProvider badgeProvider,
  })  : _activeElder = activeElder,
        _firestoreService = firestoreService,
        _badgeProvider = badgeProvider;

  ElderProfile? get activeElder => _activeElder;
  String? get errorMessage => _errorMessage;

  // ---------------------------------------------------------------------------
  // FIX: duplicate if condition merged into one block.
  //
  // The original had two separate `if (_activeElder?.id != elder?.id)` checks
  // that were identical — the second one could never evaluate differently from
  // the first. Both bodies now live inside a single guard.
  //
  // Note: notifyListeners() is intentionally absent here. This method is called
  // from main.dart's ChangeNotifierProxyProvider update: callback, which
  // returns the mutated provider and triggers a rebuild automatically.
  // ---------------------------------------------------------------------------
  void setActiveElder(ElderProfile? elder) {
    if (_activeElder?.id != elder?.id) {
      _errorMessage = null;
      _activeElder = elder;
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // FIX: EntryType fallback replaced with an explicit throw.
  //
  // The original silently fell back to EntryType.pain for any unrecognised
  // journal type string, which would have caused mystery pain entries to appear
  // on the timeline whenever a new type was added to the app but not yet
  // reflected in the enum. Now it throws immediately so the bug surfaces at
  // the exact call site during development rather than silently corrupting data
  // in production.
  //
  // The try/catch that surrounded firstWhere was also unnecessary — firstWhere
  // with an orElse closure never throws; the catch block was dead code.
  // ---------------------------------------------------------------------------
  EntryType _entryTypeFromString(String journalType) {
    final EntryType? match = EntryType.values
        .where((e) => e.name == journalType)
        .firstOrNull;

    if (match != null) return match;

    // Surface immediately in debug so the developer fixes the mapping.
    // In release we still throw — recording a corrupted entry type is worse
    // than a caught exception that shows an error snackbar to the user.
    throw ArgumentError(
      'JournalServiceProvider: unknown journal type "$journalType". '
      'Add it to the EntryType enum before using it.',
    );
  }

  JournalEntry _prepareTimelineSummaryData({
    required String elderId,
    required String journalType,
    required Map<String, dynamic> detailedEntryData,
    required DateTime entryDateTime,
    required String loggedByUserId,
    String? loggedByDisplayName,
    String? loggedByUserAvatarUrl,
  }) {
    String summaryText = '${journalType.capitalize()} entry logged.';
    if (journalType == 'medication' &&
        detailedEntryData.containsKey('name')) {
      summaryText = 'Medication: ${detailedEntryData['name']}';
    } else if (detailedEntryData.containsKey('description')) {
      summaryText = detailedEntryData['description'] as String;
    } else if (detailedEntryData.containsKey('activityType')) {
      summaryText = detailedEntryData['activityType'] as String;
    }

    final String dateStringForPath =
        DateFormat('yyyy-MM-dd').format(entryDateTime);

    // FIX: _entryTypeFromString throws on unknown types instead of silently
    // defaulting to EntryType.pain.
    final EntryType entryTypeEnum = _entryTypeFromString(journalType);

    return JournalEntry(
      elderId: elderId,
      type: entryTypeEnum,
      loggedByUserId: loggedByUserId,
      loggedByDisplayName: loggedByDisplayName ?? 'Unknown User',
      loggedByUserAvatarUrl: loggedByUserAvatarUrl,
      entryTimestamp: Timestamp.fromDate(entryDateTime),
      dateString: dateStringForPath,
      text: summaryText,
      data: detailedEntryData,
      isPublic: true,
      visibleToUserIds: ['all'],
    );
  }

  /// Adds a new journal entry for the active elder.
  ///
  /// Signature: (String type, Map payload, String userId)
  Future<Map<String, dynamic>?> addJournalEntry(
    String type,
    Map<String, dynamic> payload,
    String userId,
  ) async {
    _errorMessage = null;

    if (_activeElder == null || _activeElder!.id.isEmpty) {
      debugPrint(
          'JournalServiceProvider: No active elder set for addJournalEntry.');
      _errorMessage = 'Cannot add entry: No active elder selected.';
      notifyListeners();
      return null;
    }

    if (userId.isEmpty) {
      debugPrint(
          'JournalServiceProvider: loggedByUserId is missing or empty.');
      _errorMessage = 'Cannot add entry: User information is missing.';
      notifyListeners();
      return null;
    }

    final String elderId = _activeElder!.id;
    final User? authUser = AuthService.currentUser;
    String displayName = 'Unknown User';
    if (authUser != null) {
      final String? dn = authUser.displayName;
      final String? em = authUser.email;
      if (dn != null && dn.trim().isNotEmpty) {
        displayName = dn.trim();
      } else if (em != null && em.trim().isNotEmpty) {
        displayName = em.trim();
      }
    }
    final String? avatarUrl = await _firestoreService.getAvatarUrl(userId);

    final DateTime actualEntryDateTime = DateTime.now();
    final String dateString =
        DateFormat('yyyy-MM-dd').format(actualEntryDateTime);

    // FIX: _prepareTimelineSummaryData now calls _entryTypeFromString, which
    // throws on unknown types. Wrap in try/catch so callers get a clean error
    // message rather than an unhandled exception.
    final JournalEntry timelineSummaryEntry;
    try {
      timelineSummaryEntry = _prepareTimelineSummaryData(
        elderId: elderId,
        journalType: type,
        detailedEntryData: payload,
        entryDateTime: actualEntryDateTime,
        loggedByUserId: userId,
        loggedByDisplayName: displayName,
        loggedByUserAvatarUrl: avatarUrl,
      );
    } catch (e) {
      debugPrint('JournalServiceProvider.addJournalEntry: $e');
      _errorMessage = 'Cannot add entry: Unrecognised entry type "$type".';
      notifyListeners();
      return null;
    }

    final Map<String, dynamic> detailedEntryDataForFirestore = {
      ...payload,
      'loggedByUserId': userId,
      'loggedByDisplayName': displayName,
      'loggedByUserAvatarUrl': avatarUrl,
    };

    debugPrint(
        'JSP.addJournalEntry: calling addDetailedJournalEntryWithTimelineLink '
        'for $type on $dateString');

    final DocumentReference? detailedDocRef =
        await _firestoreService.addDetailedJournalEntryWithTimelineLink(
      elderId: elderId,
      dateString: dateString,
      journalType: type,
      detailedEntryData: detailedEntryDataForFirestore,
      timelineSummaryEntry: timelineSummaryEntry,
    );

    if (detailedDocRef != null) {
      final docSnap = await detailedDocRef.get();
      if (docSnap.exists) {
        final Map<String, dynamic> resultData =
            docSnap.data() as Map<String, dynamic>;
        resultData['firestoreId'] = docSnap.id;

        // Fire-and-forget: stamp the user's last activity time.
        _firestoreService.updateLastActiveAt(userId);

        try {
          await _badgeProvider.checkForNewBadgesAfterEntry(
              type, userId, elderId);
        } catch (badgeError) {
          debugPrint(
              'JournalServiceProvider: error triggering badge check: '
              '$badgeError');
        }
        notifyListeners();
        return resultData;
      }
    }

    _errorMessage = 'Failed to save $type entry. Please try again.';
    notifyListeners();
    return null;
  }

  /// Updates an existing journal entry.
  ///
  /// Signature: (String type, Map payload, String docId)
  Future<Map<String, dynamic>?> updateJournalEntry(
    String entryTypeString,
    Map<String, dynamic> entryData,
    String entryId,
  ) async {
    _errorMessage = null;

    if (_activeElder == null || _activeElder!.id.isEmpty) {
      debugPrint(
          'JournalServiceProvider: No active elder set for updateJournalEntry.');
      _errorMessage = 'Cannot update entry: No active elder selected.';
      notifyListeners();
      return null;
    }

    final currentUser = AuthService.currentUser;
    if (currentUser == null) {
      debugPrint(
          'JournalServiceProvider: No current user logged in for '
          'updateJournalEntry.');
      _errorMessage = 'Cannot update entry: You are not logged in.';
      notifyListeners();
      return null;
    }

    // FIX: validate the type string early so we fail fast before touching
    // Firestore, rather than silently defaulting to EntryType.pain later.
    final EntryType entryTypeEnum;
    try {
      entryTypeEnum = _entryTypeFromString(entryTypeString);
    } catch (e) {
      debugPrint('JournalServiceProvider.updateJournalEntry: $e');
      _errorMessage =
          'Cannot update entry: Unrecognised entry type "$entryTypeString".';
      notifyListeners();
      return null;
    }

    String dateString;
    if (entryData.containsKey('dateString') &&
        entryData['dateString'] is String) {
      dateString = entryData['dateString'] as String;
    } else if (entryData.containsKey('entryTimestamp') &&
        entryData['entryTimestamp'] is Timestamp) {
      dateString = DateFormat('yyyy-MM-dd').format(
          (entryData['entryTimestamp'] as Timestamp).toDate());
    } else {
      debugPrint(
          'JournalServiceProvider: dateString not found in entryData for '
          'update. Using current date.');
      dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    Map<String, dynamic>? updatedEntryDataWithId;

    try {
      final detailedDocRef = FirebaseFirestore.instance
          .collection('elders')
          .doc(_activeElder!.id)
          .collection('days')
          .doc(dateString)
          .collection(entryTypeString)
          .doc(entryId);

      final updatePayload = {
        ...entryData,
        'updatedAt': FieldValue.serverTimestamp(),
        'loggedByUserId':
            entryData['loggedByUserId'] ?? currentUser.uid,
        'loggedByDisplayName': entryData['loggedByDisplayName'] ??
            (currentUser.displayName ??
                currentUser.email ??
                'Unknown User'),
        'loggedByUserAvatarUrl':
            entryData['loggedByUserAvatarUrl'] ??
                await _firestoreService.getAvatarUrl(currentUser.uid),
      };
      await detailedDocRef.update(updatePayload);

      final docSnapshot = await detailedDocRef.get();
      if (!docSnapshot.exists) {
        debugPrint(
            'JournalServiceProvider: failed to retrieve document '
            'immediately after updating $entryTypeString (ID: $entryId).');
        _errorMessage =
            'Failed to confirm entry update. Please check the journal.';
        notifyListeners();
        return null;
      }

      updatedEntryDataWithId =
          docSnapshot.data() as Map<String, dynamic>;
      updatedEntryDataWithId['firestoreId'] = detailedDocRef.id;

      debugPrint(
          'JournalServiceProvider: updated $entryTypeString entry '
          '(ID: $entryId) for elder ${_activeElder!.id} on $dateString.');

      try {
        final String? timelineEntryId =
            updatedEntryDataWithId['timelineEntryId'] as String?;

        if (timelineEntryId != null && timelineEntryId.isNotEmpty) {
          DateTime entryDateTimeForSummary;
          if (updatedEntryDataWithId.containsKey('entryTimestamp') &&
              updatedEntryDataWithId['entryTimestamp'] is Timestamp) {
            entryDateTimeForSummary =
                (updatedEntryDataWithId['entryTimestamp'] as Timestamp)
                    .toDate();
          } else {
            entryDateTimeForSummary = DateTime.now();
            debugPrint(
                'JournalServiceProvider: entryTimestamp not found in '
                'updated data for timeline summary — using current time.');
          }

          // entryTypeEnum is already resolved above; no second conversion
          // needed and no risk of silently falling back to EntryType.pain.
          final JournalEntry updatedTimelineSummaryEntry =
              _prepareTimelineSummaryData(
            elderId: _activeElder!.id,
            journalType: entryTypeString,
            detailedEntryData: updatedEntryDataWithId,
            entryDateTime: entryDateTimeForSummary,
            loggedByUserId:
                updatedEntryDataWithId['loggedByUserId'] as String,
            loggedByDisplayName: updatedEntryDataWithId[
                'loggedByDisplayName'] as String?,
            loggedByUserAvatarUrl: updatedEntryDataWithId[
                'loggedByUserAvatarUrl'] as String?,
          );

          final Map<String, dynamic> timelineUpdatePayload =
              updatedTimelineSummaryEntry.toFirestore();

          await _firestoreService.updateJournalEntry(
            entryId: timelineEntryId,
            elderId: _activeElder!.id,
            type: entryTypeEnum,
            data: timelineUpdatePayload['data'] as Map<String, dynamic>?,
            text: timelineUpdatePayload['text'] as String?,
            timestamp: entryDateTimeForSummary,
            isPublic: updatedTimelineSummaryEntry.isPublic,
            visibleToUserIds:
                updatedTimelineSummaryEntry.visibleToUserIds,
            creatorId: updatedTimelineSummaryEntry.loggedByUserId,
          );

          debugPrint(
              'JournalServiceProvider: updated timeline entry '
              '$timelineEntryId.');
        } else {
          debugPrint(
              'JournalServiceProvider: no timelineEntryId found in '
              'updated entry $entryId — timeline summary not updated.');
        }
      } catch (timelineError) {
        debugPrint(
            'JournalServiceProvider: failed to update timeline summary '
            'for $entryTypeString (ID: $entryId): $timelineError');
        _errorMessage =
            'Entry updated, but failed to update the main timeline summary.';
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint(
          'JournalServiceProvider: failed to update $entryTypeString '
          '(ID: $entryId) for elder ${_activeElder!.id} on $dateString: $e');
      _errorMessage =
          'Failed to update $entryTypeString entry. Please try again.';
      notifyListeners();
      return null;
    }

    notifyListeners();
    return updatedEntryDataWithId;
  }

  Future<bool> deleteJournalEntry(
      String entryType, String entryId) async {
    _errorMessage = null;

    if (_activeElder == null || _activeElder!.id.isEmpty) {
      debugPrint(
          'JournalServiceProvider: No active elder set for '
          'deleteJournalEntry.');
      _errorMessage = 'Cannot delete entry: No active elder selected.';
      notifyListeners();
      return false;
    }
    if (entryId.isEmpty) {
      debugPrint(
          'JournalServiceProvider: entryId is empty for deleteJournalEntry. '
          'Elder: ${_activeElder?.id}, Type: $entryType');
      _errorMessage = 'Cannot delete entry: Invalid entry ID.';
      notifyListeners();
      return false;
    }

    String? dateString;
    try {
      // Look up the detailed entry directly by document ID inside the
      // entryType subcollection under each day. A collectionGroup query
      // on the entryType name lets Firestore find the doc regardless of
      // which date it lives under.
      final querySnapshot = await FirebaseFirestore.instance
          .collectionGroup(entryType)
          .where(FieldPath.documentId, isEqualTo: entryId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Path: elders/{elderId}/days/{dateString}/{entryType}/{entryId}
        // Parent of the entry doc is the type collection; grandparent is
        // the day document whose ID is the dateString.
        final entryRef = querySnapshot.docs.first.reference;
        dateString = entryRef.parent.parent?.id;
        debugPrint(
            'JournalServiceProvider: found dateString $dateString for '
            'entry $entryId of type $entryType.');
      }

      if (dateString == null || dateString.isEmpty) {
        debugPrint(
            'JournalServiceProvider: could not find dateString for entry '
            '$entryId of type $entryType.');
        _errorMessage = 'Cannot delete entry: Date information missing.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint(
          'JournalServiceProvider: error deriving dateString for '
          'deletion: $e');
      _errorMessage =
          'Failed to delete entry: Internal error deriving date.';
      notifyListeners();
      return false;
    }

    debugPrint(
        'JSP.deleteJournalEntry: calling '
        'deleteDetailedJournalEntryWithTimelineLink for '
        '$entryType/$entryId on $dateString');

    final bool success =
        await _firestoreService.deleteDetailedJournalEntryWithTimelineLink(
      elderId: _activeElder!.id,
      dateString: dateString,
      journalType: entryType,
      detailedEntryId: entryId,
    );

    if (success) {
      notifyListeners();
    } else {
      _errorMessage =
          'Failed to delete $entryType entry completely. '
          'Please check the journal.';
      notifyListeners();
    }
    return success;
  }

  Stream<List<JournalEntry>> getJournalEntriesStream({
    required String elderId,
    required String currentUserId,
    DateTime? startDate,
    DateTime? endDate,
    bool onlyMyLogs = false,
    String? entryTypeFilter,
  }) {
    EntryType? typeEnumFilter;
    if (entryTypeFilter != null && entryTypeFilter.isNotEmpty) {
      // FIX: use _entryTypeFromString so unknown filter strings are caught
      // the same way as unknown entry types everywhere else — no silent
      // fallback to pain.
      try {
        typeEnumFilter = _entryTypeFromString(entryTypeFilter);
      } catch (e) {
        debugPrint(
            'JournalServiceProvider.getJournalEntriesStream: '
            'unrecognised entryTypeFilter "$entryTypeFilter" — '
            'ignoring type filter. $e');
        // Returning an empty stream for an invalid filter is safer than
        // ignoring the filter and returning all entries.
        return const Stream.empty();
      }
    }

    return _firestoreService.getJournalEntriesStream(
      elderId: elderId,
      currentUserId: currentUserId,
      startDate: startDate,
      endDate: endDate,
      onlyMyLogs: onlyMyLogs,
      type: typeEnumFilter,
    );
  }
}

