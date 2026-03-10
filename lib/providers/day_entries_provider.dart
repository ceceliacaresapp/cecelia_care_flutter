import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/day_entries.dart';
import 'package:cecelia_care_flutter/models/medication_entry.dart';
import 'package:cecelia_care_flutter/models/sleep_entry.dart';
import 'package:cecelia_care_flutter/models/meal_entry.dart';
import 'package:cecelia_care_flutter/models/mood_entry.dart';
import 'package:cecelia_care_flutter/models/pain_entry.dart';
import 'package:cecelia_care_flutter/models/activity_entry.dart';
import 'package:cecelia_care_flutter/models/vital_entry.dart';
import 'package:cecelia_care_flutter/models/expense_entry.dart';

import 'journal_service_provider.dart';

/// --- I18N UPDATE ---
/// A data class to hold structured error information.
class DayEntriesLoadError {
  /// The type of entry that failed to load (e.g., 'medication', 'sleep').
  final String entryType;

  /// The underlying error details from the exception.
  final String details;

  DayEntriesLoadError({required this.entryType, required this.details});
}

class DayEntriesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  JournalServiceProvider _journalSvc;

  DayEntries _dayEntries = DayEntries.empty();
  bool _isLoading = false;
  int _pendingStreams = 0;

  // --- I18N UPDATE ---
  // Changed from a simple String to a structured error object.
  DayEntriesLoadError? _errorInfo;

  String? _loadedElderId;
  String? _loadedDateString;
  String? _loadedCurrentUserId;

  final List<StreamSubscription<QuerySnapshot>> _entryTypeSubscriptions = [];

  bool _disposed = false;

  DayEntriesProvider({required JournalServiceProvider journalSvc})
      : _journalSvc = journalSvc;

  void updateJournalService(JournalServiceProvider newSvc) {
    if (_journalSvc != newSvc) {
      _journalSvc = newSvc;
      debugPrint('DayEntriesProvider: JournalService instance updated.');
    }
  }

  DayEntries get dayEntries => _dayEntries;
  bool get isLoading => _isLoading;
  // --- I18N UPDATE ---
  // The getter now returns the structured error object.
  DayEntriesLoadError? get errorInfo => _errorInfo;

  void clearErrorMessage() {
    _errorInfo = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (var sub in _entryTypeSubscriptions) {
      sub.cancel();
    }
    _entryTypeSubscriptions.clear();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_disposed) notifyListeners();
  }

  /// Load entries for a given elder & date.
  Future<void> loadEntriesFor(
    String elderId,
    DateTime date,
    String currentUserId, {
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('DayEntriesProvider: no user, clearing.');
      clearEntries();
      return;
    }
    if (elderId.isEmpty) {
      debugPrint('DayEntriesProvider: empty elderId, clearing.');
      clearEntries();
      return;
    }

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    if (!forceRefresh &&
        _loadedElderId == elderId &&
        _loadedDateString == dateString &&
        _loadedCurrentUserId == currentUserId) {
      debugPrint(
        'DayEntriesProvider: skip load for $elderId, user $currentUserId on $dateString',
      );
      return;
    }

    _subscribeToDayEntries(elderId, dateString, currentUserId);
  }

  /// Convenience: load for the currently active elder from [journalSvc]
  Future<void> fetchEntriesForDate(
    DateTime date, {
    required String currentUserId,
    bool forceRefresh = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('DayEntriesProvider: no user, clearing.');
      clearEntries();
      return;
    }
    final elder = _journalSvc.activeElder;
    if (elder == null || elder.id.isEmpty) {
      debugPrint('DayEntriesProvider: no active elder, clearing.');
      clearEntries();
      return;
    }
    if (currentUserId.isEmpty) {
      debugPrint(
        'DayEntriesProvider: fetchEntriesForDate called with empty currentUserId, clearing.',
      );
      clearEntries();
      return;
    }

    final dateString = DateFormat('yyyy-MM-dd').format(date);

    if (!forceRefresh &&
        _loadedElderId == elder.id &&
        _loadedDateString == dateString &&
        _loadedCurrentUserId == currentUserId) {
      debugPrint(
        'DayEntriesProvider: skip fetch for ${elder.id}, user $currentUserId on $dateString',
      );
      return;
    }
    _subscribeToDayEntries(elder.id, dateString, currentUserId);
  }

  void _subscribeToDayEntries(
    String elderId,
    String dateString,
    String currentUserId,
  ) async {
    for (var sub in _entryTypeSubscriptions) {
      await sub.cancel();
    }
    _entryTypeSubscriptions.clear();

    _loadedElderId = elderId;
    _loadedDateString = dateString;
    _loadedCurrentUserId = currentUserId;
    _errorInfo = null;

    _dayEntries = DayEntries.empty();
    _isLoading = true;
    _safeNotifyListeners();

    final List<String> journalTypes = [
      'medication',
      'sleep',
      'meal',
      'mood',
      'pain',
      'activity',
      'vital',
      'expense'
    ];

    _pendingStreams = journalTypes.length;

    for (String type in journalTypes) {
      Query query = _db
          .collection('elders')
          .doc(elderId)
          .collection('days')
          .doc(dateString)
          .collection(type)
          .where('loggedByUserId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true);

      final subscription = query.snapshots().listen(
        (querySnapshot) {
          if (_disposed) return;
          _errorInfo = null;
          try {
            switch (type) {
              case 'medication':
                _dayEntries = _dayEntries.copyWith(
                    meds: querySnapshot.docs
                        .map((doc) => MedicationEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              case 'sleep':
                _dayEntries = _dayEntries.copyWith(
                    sleep: querySnapshot.docs
                        .map((doc) => SleepEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              case 'meal':
                _dayEntries = _dayEntries.copyWith(
                    meals: querySnapshot.docs
                        .map((doc) => MealEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              case 'mood':
                _dayEntries = _dayEntries.copyWith(
                    moods: querySnapshot.docs
                        .map((doc) => MoodEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              case 'pain':
                _dayEntries = _dayEntries.copyWith(
                    pain: querySnapshot.docs
                        .map((doc) => PainEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              case 'activity':
                _dayEntries = _dayEntries.copyWith(
                    activities: querySnapshot.docs
                        .map((doc) => ActivityEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              case 'vital':
                _dayEntries = _dayEntries.copyWith(
                    vitals: querySnapshot.docs
                        .map((doc) => VitalEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              case 'expense':
                _dayEntries = _dayEntries.copyWith(
                    expenses: querySnapshot.docs
                        .map((doc) => ExpenseEntry.fromFirestore(
                            doc as DocumentSnapshot<Map<String, dynamic>>))
                        .toList());
                break;
              default:
                debugPrint(
                    "DayEntriesProvider: Unknown entry type '$type' during stream update.");
            }
            debugPrint(
              'DayEntriesProvider: stream update for $type on $elderId, user $currentUserId on $dateString. Count: ${querySnapshot.docs.length}',
            );
          } catch (e, st) {
            debugPrint(
              "DayEntriesProvider: Error parsing specific entry type '$type' from stream: $e\n$st",
            );
          } finally {
            if (_pendingStreams > 0) {
              _pendingStreams--;
            }
            if (_pendingStreams == 0) {
              _isLoading = false;
            }
            _safeNotifyListeners();
          }
        },
        onError: (e, st) {
          if (_disposed) return;
          debugPrint(
            'DayEntriesProvider: FAILED stream for $type on $elderId, user $currentUserId on $dateString: $e\n$st',
          );
          // --- I18N UPDATE ---
          _errorInfo = DayEntriesLoadError(entryType: type, details: e.toString());

          if (_pendingStreams > 0) {
            _pendingStreams--;
          }
          if (_pendingStreams == 0) {
            _isLoading = false;
          }
          _safeNotifyListeners();
        },
      );
      _entryTypeSubscriptions.add(subscription);
      debugPrint(
          'DayEntriesProvider: Subscribed to $type entries for $elderId, user $currentUserId on $dateString');
    }
  }

  /// Clear out state entirely.
  void clearEntries() {
    for (var sub in _entryTypeSubscriptions) {
      sub.cancel();
    }
    _entryTypeSubscriptions.clear();
    _dayEntries = DayEntries.empty();
    _loadedElderId = null;
    _loadedDateString = null;
    _loadedCurrentUserId = null;
    _errorInfo = null;
    _isLoading = false;
    _pendingStreams = 0;
    _safeNotifyListeners();
  }

  /// Returns the RxCUI codes from today's medication entries for interaction checking.
  /// Assumes `MedicationEntry` has an `rxCui` property.
  Future<List<String>> getRxcuisForInteractionCheck({
    String? rxcuiToAdd,
    String? editingItemId,
  }) async {
    final List<String> rxcuis = [];
    try {
      for (final med in _dayEntries.meds) {
        if (med.firestoreId == editingItemId) {
          continue;
        }
        final rx = med.rxCui;
        if (rx.isNotEmpty) {
          rxcuis.add(rx);
        }
      }
      if (rxcuiToAdd != null && rxcuiToAdd.isNotEmpty) {
        rxcuis.add(rxcuiToAdd);
      }
    } catch (e) {
      debugPrint('DayEntriesProvider: error extracting RxCUIs: $e');
    }
    return rxcuis;
  }
}