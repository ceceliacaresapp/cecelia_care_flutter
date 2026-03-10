import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart'; // NEW: Import EntryType

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

  void setActiveElder(ElderProfile? elder) {
    if (_activeElder?.id != elder?.id) {
      _errorMessage = null;
    }
    if (_activeElder?.id != elder?.id) {
      _activeElder = elder;
    }
  }

  ElderProfile? get activeElder => _activeElder;
  String? get errorMessage => _errorMessage;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  JournalEntry _prepareTimelineSummaryData({
    required String elderId,
    required String journalType, // This remains String for the collection path
    required Map<String, dynamic> detailedEntryData,
    required DateTime entryDateTime,
    required String loggedByUserId,
    String? loggedByDisplayName,
    String? loggedByUserAvatarUrl,
  }) {
    String summaryText = '${journalType.capitalize()} entry logged.';
    if (journalType == 'medication' && detailedEntryData.containsKey('name')) {
      summaryText = 'Medication: ${detailedEntryData['name']}';
    } else if (detailedEntryData.containsKey('description')) {
      summaryText = detailedEntryData['description'] as String;
    } else if (detailedEntryData.containsKey('activityType')) {
      summaryText = detailedEntryData['activityType'] as String;
    }

    final String dateStringForPath = DateFormat('yyyy-MM-dd').format(entryDateTime);

    // Convert journalType String to EntryType enum for JournalEntry constructor
    EntryType entryTypeEnum;
    try {
      entryTypeEnum = EntryType.values.firstWhere(
        (e) => e.name == journalType,
        orElse: () => EntryType.pain, // Default or handle as appropriate
      );
    } catch (e) {
      debugPrint('Warning: Invalid journalType "$journalType" for enum conversion. Defaulting to Pain. Error: $e');
      entryTypeEnum = EntryType.pain; // Fallback
    }

    final JournalEntry timelineJournalEntry = JournalEntry(
      elderId: elderId,
      type: entryTypeEnum, // NEW: Use EntryType enum
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
    return timelineJournalEntry;
  }

  /// Adds a new journal entry.
  /// **CONSISTENT SIGNATURE:** (String type, Map payload, String userId)
  Future<Map<String, dynamic>?> addJournalEntry(
      String type, // Keep as String for this method's parameter
      Map<String, dynamic> payload, // Keep as Map second
      String userId) async {
    _errorMessage = null;

    if (_activeElder == null || _activeElder!.id.isEmpty) {
      debugPrint('JournalServiceProvider: No active elder set for addJournalEntry.');
      _errorMessage = 'Cannot add entry: No active elder selected.';
      notifyListeners();
      return null;
    }

    final String elderId = _activeElder!.id;
    final User? authServiceCurrentUser = AuthService.currentUser; // Assuming AuthService.currentUser exists and is a static getter
    String authServiceDisplayName = 'Unknown User';
    if (authServiceCurrentUser != null) {
        String? dn = authServiceCurrentUser.displayName;
        String? em = authServiceCurrentUser.email;
        if (dn != null && dn.trim().isNotEmpty) {
            authServiceDisplayName = dn.trim();
        } else if (em != null && em.trim().isNotEmpty) {
            authServiceDisplayName = em.trim();
        }
    }
    final String? authServiceAvatarUrl = authServiceCurrentUser?.photoURL;

    if (userId.isEmpty) {
      debugPrint('JournalServiceProvider: loggedByUserId is missing or empty. Cannot add entry.');
      _errorMessage = 'Cannot add entry: User information is missing.';
      notifyListeners();
      return null;
    }

    final DateTime actualEntryDateTime = DateTime.now();
    final JournalEntry timelineSummaryEntry = _prepareTimelineSummaryData(
      elderId: elderId,
      journalType: type, // This `type` is String, used for collection path and _prepareTimelineSummaryData
      detailedEntryData: payload,
      entryDateTime: actualEntryDateTime,
      loggedByUserId: userId,
      loggedByDisplayName: authServiceDisplayName,
      loggedByUserAvatarUrl: authServiceAvatarUrl,
    );

    Map<String, dynamic> detailedEntryDataForFirestore = {
      ...payload,
      'loggedByUserId': userId,
      'loggedByDisplayName': authServiceDisplayName,
      'loggedByUserAvatarUrl': authServiceAvatarUrl,
    };

    final String dateString = DateFormat('yyyy-MM-dd').format(actualEntryDateTime);

    debugPrint('JSP.addJournalEntry: Calling FirestoreService.addDetailedJournalEntryWithTimelineLink for $type on $dateString');
    final DocumentReference? detailedDocRef = await _firestoreService.addDetailedJournalEntryWithTimelineLink(
      elderId: elderId,
      dateString: dateString,
      journalType: type, // This `journalType` is String, passed to FirestoreService
      detailedEntryData: detailedEntryDataForFirestore,
      timelineSummaryEntry: timelineSummaryEntry,
    );

    if (detailedDocRef != null) {
      final docSnap = await detailedDocRef.get();
      if (docSnap.exists) {
        final Map<String, dynamic> resultData = docSnap.data() as Map<String, dynamic>;
        resultData['firestoreId'] = docSnap.id;

        try {
          // Pass the string type to badge provider if it expects string, or convert if needed
          await _badgeProvider.checkForNewBadgesAfterEntry(
            type, // This is still a string here, assuming badgeProvider expects string
            userId,
            elderId,
          );
        } catch (badgeError) {
          debugPrint('JournalServiceProvider: Error triggering badge check: $badgeError');
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
  /// **CONSISTENT SIGNATURE:** (String type, Map payload, String docId)
  Future<Map<String, dynamic>?> updateJournalEntry(
      String entryTypeString, // CHANGED: Now String first for consistency (name entryTypeString to clarify)
      Map<String, dynamic> entryData, // CHANGED: Now Map second for consistency
      String entryId) async {
    _errorMessage = null;
    if (_activeElder == null || _activeElder!.id.isEmpty) {
      debugPrint('JournalServiceProvider: No active elder set for updateJournalEntry.');
      _errorMessage = 'Cannot update entry: No active elder selected.';
      notifyListeners();
      return null;
    }
    final currentUser = AuthService.currentUser; // Assuming AuthService.currentUser exists and is a static getter
    if (currentUser == null) {
      debugPrint('JournalServiceProvider: No current user logged in for updateJournalEntry.');
      _errorMessage = 'Cannot update entry: You are not logged in.';
      notifyListeners();
      return null;
    }

    String dateString;
    if (entryData.containsKey('dateString') && entryData['dateString'] is String) {
      dateString = entryData['dateString'] as String;
    } else if (entryData.containsKey('entryTimestamp') && entryData['entryTimestamp'] is Timestamp) {
      dateString = DateFormat('yyyy-MM-dd').format((entryData['entryTimestamp'] as Timestamp).toDate());
    } else {
      debugPrint('Warning: Date string not found in entryData for update. Using current date.');
      dateString = DateFormat('yyyy-MM-dd').format(DateTime.now());
    }

    Map<String, dynamic>? updatedEntryDataWithId;

    try {
      final detailedDocRef = FirebaseFirestore.instance
          .collection('elders')
          .doc(_activeElder!.id)
          .collection('days')
          .doc(dateString)
          .collection(entryTypeString) // Use entryTypeString (now the first arg)
          .doc(entryId);

      final updatePayload = {
        ...entryData,
        'updatedAt': FieldValue.serverTimestamp(),
        'loggedByUserId': entryData['loggedByUserId'] ?? currentUser.uid,
        'loggedByDisplayName': entryData['loggedByDisplayName'] ?? (currentUser.displayName ?? currentUser.email ?? 'Unknown User'),
        'loggedByUserAvatarUrl': entryData['loggedByUserAvatarUrl'] ?? currentUser.photoURL,
      };
      await detailedDocRef.update(updatePayload);

      final docSnapshot = await detailedDocRef.get();
      if (!docSnapshot.exists) {
        debugPrint('Failed to retrieve document immediately after updating for $entryTypeString. ID: $entryId, Elder ID: ${_activeElder!.id}');
        _errorMessage = 'Failed to confirm entry update. Please check the journal.';
        notifyListeners();
        return null;
      }
      updatedEntryDataWithId = docSnapshot.data() as Map<String, dynamic>;
      updatedEntryDataWithId['firestoreId'] = detailedDocRef.id;

      debugPrint('Successfully updated $entryTypeString entry (ID: $entryId) for elder ${_activeElder!.id} on $dateString.');

      try {
        final String? timelineEntryId = updatedEntryDataWithId['timelineEntryId'] as String?;

        if (timelineEntryId != null && timelineEntryId.isNotEmpty) {
          final timelineDocRef = FirebaseFirestore.instance
              .collection('elders')
              .doc(_activeElder!.id)
              .collection('timeline')
              .doc(timelineEntryId);

          DateTime entryDateTimeForSummary;
          if (updatedEntryDataWithId.containsKey('entryTimestamp') && updatedEntryDataWithId['entryTimestamp'] is Timestamp) {
            entryDateTimeForSummary = (updatedEntryDataWithId['entryTimestamp'] as Timestamp).toDate();
          } else {
            entryDateTimeForSummary = DateTime.now();
            debugPrint('Warning: entryTimestamp not found in updated data for timeline summary. Using current time.');
          }

          // Convert entryTypeString to EntryType enum for _prepareTimelineSummaryData
          EntryType entryTypeEnumForSummary;
          try {
            entryTypeEnumForSummary = EntryType.values.firstWhere(
              (e) => e.name == entryTypeString,
              orElse: () => EntryType.pain,
            );
          } catch (e) {
            debugPrint('Warning: Invalid entryTypeString "$entryTypeString" for enum conversion in update. Defaulting to Pain. Error: $e');
            entryTypeEnumForSummary = EntryType.pain;
          }

          final JournalEntry updatedTimelineSummaryEntry = _prepareTimelineSummaryData(
            elderId: _activeElder!.id,
            journalType: entryTypeString, // Keep as string for collection path
            detailedEntryData: updatedEntryDataWithId,
            entryDateTime: entryDateTimeForSummary,
            loggedByUserId: updatedEntryDataWithId['loggedByUserId'] as String,
            loggedByDisplayName: updatedEntryDataWithId['loggedByDisplayName'] as String?,
            loggedByUserAvatarUrl: updatedEntryDataWithId['loggedByUserAvatarUrl'] as String?,
          );
          final Map<String, dynamic> timelineUpdatePayload = updatedTimelineSummaryEntry.toFirestore();

          // NEW: Call FirestoreService.updateJournalEntry here for consistency
          await _firestoreService.updateJournalEntry(
            entryId: timelineEntryId,
            elderId: _activeElder!.id,
            type: entryTypeEnumForSummary, // Pass EntryType enum
            data: timelineUpdatePayload['data'] as Map<String, dynamic>?, // Assuming `data` is correct
            text: timelineUpdatePayload['text'] as String?, // Assuming `text` is correct
            timestamp: entryDateTimeForSummary, // Pass the new timestamp
            isPublic: updatedTimelineSummaryEntry.isPublic,
            visibleToUserIds: updatedTimelineSummaryEntry.visibleToUserIds,
            creatorId: updatedTimelineSummaryEntry.loggedByUserId,
          );

          debugPrint('Successfully updated corresponding timeline entry: $timelineEntryId');
        } else {
          debugPrint('Could not find timelineEntryId in updated detailed entry $entryId to update timeline summary.');
        }
      } catch (timelineError) {
        debugPrint('Failed to update timeline summary for $entryTypeString entry (ID: $entryId): $timelineError');
        _errorMessage = 'Entry updated, but failed to update the main timeline summary.';
        notifyListeners();
        return null;
      }
    } catch (e) {
      debugPrint('Failed to update $entryTypeString entry (ID: $entryId) for elder ${_activeElder!.id} on $dateString: $e');
      _errorMessage = 'Failed to update $entryTypeString entry. Please try again.';
      notifyListeners();
      return null;
    }
    notifyListeners();
    return updatedEntryDataWithId;
  }

  Future<bool> deleteJournalEntry(String entryType, String entryId) async {
    _errorMessage = null;
    if (_activeElder == null || _activeElder!.id.isEmpty) {
      debugPrint('JournalServiceProvider: No active elder set for deleteJournalEntry.');
      _errorMessage = 'Cannot delete entry: No active elder selected.';
      notifyListeners();
      return false;
    }
    if (entryId.isEmpty) {
      debugPrint('JournalServiceProvider: entryId is empty for deleteJournalEntry. Elder: ${_activeElder?.id}, Type: $entryType');
      _errorMessage = 'Cannot delete entry: Invalid entry ID.';
      notifyListeners();
      return false;
    }

    String? dateString;
    try {
      final detailedDocRef = FirebaseFirestore.instance
          .collection('elders')
          .doc(_activeElder!.id)
          .collection('days');

      final querySnapshot = await detailedDocRef
          .where('$entryType.$entryId', isNotEqualTo: null)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        dateString = querySnapshot.docs.first.id;
        debugPrint('Found dateString $dateString for entry $entryId of type $entryType');
      } else {
        debugPrint('Could not find dateString for entry $entryId of type $entryType. Cannot delete.');
        _errorMessage = 'Cannot delete entry: Date information missing.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Error deriving dateString for deletion: $e');
      _errorMessage = 'Failed to delete entry: Internal error deriving date.';
      notifyListeners();
      return false;
    }

    debugPrint('JSP.deleteJournalEntry: Calling FirestoreService.deleteDetailedJournalEntryWithTimelineLink for $entryType/$entryId on $dateString');

    final bool success = await _firestoreService.deleteDetailedJournalEntryWithTimelineLink(
      elderId: _activeElder!.id,
      dateString: dateString,
      journalType: entryType,
      detailedEntryId: entryId,
    );

    if (success) {
      notifyListeners();
    } else {
      _errorMessage = 'Failed to delete $entryType entry completely. Please check the journal.';
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
    String? entryTypeFilter, // This parameter is still a String here
  }) {
    EntryType? typeEnumFilter;
    if (entryTypeFilter != null && entryTypeFilter.isNotEmpty) {
      try {
        typeEnumFilter = EntryType.values.firstWhere((e) => e.name == entryTypeFilter);
      } catch (e) {
        debugPrint('Warning: Invalid entryTypeFilter string "$entryTypeFilter" for enum conversion. Ignoring type filter. Error: $e');
      }
    }

    return _firestoreService.getJournalEntriesStream(
      elderId: elderId,
      currentUserId: currentUserId,
      startDate: startDate,
      endDate: endDate,
      onlyMyLogs: onlyMyLogs,
      type: typeEnumFilter, // NEW: Pass the EntryType enum to FirestoreService
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}