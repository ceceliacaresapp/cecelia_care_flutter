import 'dart:async';
import 'package:flutter/material.dart' hide Badge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cecelia_care_flutter/models/badge.dart';
// Potentially: import 'package:cecelia_care_flutter/providers/day_entries_provider.dart';
// Potentially: import 'package:cecelia_care_flutter/l10n/app_localizations.dart'; // For localized badge details

class BadgeProvider with ChangeNotifier {
  static late BadgeProvider instance;

  // Private constructor for singleton pattern
  BadgeProvider._privateConstructor() {
    instance = this;
    _init();
  }

  // Public factory
  factory BadgeProvider() {
    // ignore: prefer_conditional_assignment
    if (_isInitialized == false) { // Ensure instance is created only once
      _instance = BadgeProvider._privateConstructor();
      _isInitialized = true;
    }
    return _instance!;
  }

  static BadgeProvider? _instance;
  static bool _isInitialized = false;


  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _badgeSubscription;

  // Define your badges here
  // Note: For localized labels and descriptions, you'd typically fetch them from AppLocalizations
  // For simplicity here, they are hardcoded.
  final Map<String, Badge> _definedBadges = {
    'first_mood_log': const Badge(
      id: 'first_mood_log',
      label: 'Mood Monitor', // TODO: Localize with l10n.badgeLabelFirstMoodLog
      imagePath: 'assets/images/badges/first_mood_log.png',
      description: 'Congratulations on logging your first mood entry!',
    ),
    'first_medication_log': const Badge(
      id: 'first_medication_log',
      label: 'Medication Tracker', // TODO: Localize
      imagePath: 'assets/images/badges/medication_tracker.png', // Placeholder path
      description: 'You\'ve successfully logged your first medication entry.',
    ),
    'first_activity_log': const Badge(
      id: 'first_activity_log',
      label: 'Activity Starter', // TODO: Localize
      imagePath: 'assets/images/badges/activity_starter.png', // Placeholder path
      description: 'Great job logging your first activity!',
    ),
    'medication_maestro_10': const Badge(
      id: 'medication_maestro_10',
      label: 'Medication Maestro', // TODO: Localize with l10n.badgeLabelMedMaestro10 (adjust if count is part of label)
      imagePath: 'assets/images/badges/medication_maestro.png',
      description: 'Logged 10 medication entries. You\'re a pro!',
    ),
    'daily_activity_champion_10': const Badge( // ID updated to reflect 10 days if that's the intent
      id: 'daily_activity_champion_10',
      label: 'Daily Activity Champion', // TODO: Localize with l10n.badgeLabelActivityChampion (adjust for 10 days)
      imagePath: 'assets/images/badges/daily_activity_champion.png',
      description: 'Logged an activity every day for 10 days straight!', // Description updated
    ),
    // Add more diverse badges here
  };

  final Map<String, Badge> _userBadges = {};
  Map<String, Badge> get badges {
    // Return a merged map: defined badges with their unlocked status from _userBadges
    return _definedBadges.map((id, definedBadge) {
      final userBadge = _userBadges[id];
      return MapEntry(id, definedBadge.copyWith(unlocked: userBadge?.unlocked ?? false));
    });
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _badgeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = 'User not authenticated. Cannot load badges.';
      notifyListeners();
      return;
    }
    final uid = user.uid;

    _badgeSubscription = _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .doc('badges')
        .snapshots()
        .listen(
      (docSnapshot) {
        _errorMessage = null;
        _userBadges.clear(); // Clear previous user-specific badge data
        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          data.forEach((badgeId, isUnlocked) {
            if (_definedBadges.containsKey(badgeId) && isUnlocked is bool) {
              // Store only the unlocked status for the user
              _userBadges[badgeId] = _definedBadges[badgeId]!.copyWith(unlocked: isUnlocked);
            }
          });
        }
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load badge achievements: ${error.toString()}';
        notifyListeners();
      },
    );
  }

  Future<void> unlockBadge(String badgeId, String userId) async {
    if (userId.isEmpty) return;
    if (!_definedBadges.containsKey(badgeId)) {
      debugPrint('BadgeProvider: Attempted to unlock non-existent badge ID: $badgeId');
      return;
    }
    // Check if already unlocked to prevent unnecessary writes
    if (_userBadges[badgeId]?.unlocked == true) return;

    // Optimistic update
    _userBadges[badgeId] = _definedBadges[badgeId]!.copyWith(unlocked: true);
    notifyListeners();

    try {
      await _db.collection('users').doc(userId).collection('achievements').doc('badges').set({badgeId: true}, SetOptions(merge: true));
    } catch (e) {
      _userBadges[badgeId] = _definedBadges[badgeId]!.copyWith(unlocked: false); // Revert
      _errorMessage = 'Failed to save badge progress for $badgeId.';
      notifyListeners();
    }
  }

  // This method would be called from JournalServiceProvider or similar
  Future<void> checkForNewBadgesAfterEntry(String entryType, String userId, String elderId) async {
    // Example: First Mood Log
    if (entryType == 'mood') { // Assuming 'mood' is the type string from JournalEntry
      // More sophisticated logic would check if it's *actually* the first for this user/elder.
      // For now, if the badge 'first_mood_log' isn't unlocked, try to unlock it.
      if (!(_userBadges['first_mood_log']?.unlocked ?? false)) {
        await unlockBadge('first_mood_log', userId);
      }
    }
    // Add more checks for other "first log" types (activity, medication, etc.)

    // Example: Count-based badge (Medication Maestro - 10 logs)
    if (entryType == 'medication') {
      // This requires querying DayEntriesProvider or Firestore for the count of medication entries
      // by this user for this elder. This is a simplified placeholder.
      // final dayEntriesProvider = Provider.of<DayEntriesProvider>(context, listen: false); // Needs context or passed instance
      // final medCount = await dayEntriesProvider.getEntryCountForType(elderId, userId, 'medication');
      // if (medCount >= 10 && !(_userBadges['medication_maestro_10']?.unlocked ?? false)) {
      //   await unlockBadge('medication_maestro_10', userId);
      // }
    }
    // Implement similar logic for other count-based or streak-based badges.
  }
}
