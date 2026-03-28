import 'dart:async';
import 'package:flutter/material.dart' hide Badge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cecelia_care_flutter/models/badge.dart';

/// Manages badge/achievement state for the current user.
///
/// This is a standard [ChangeNotifier] — its lifecycle is managed entirely
/// by the Provider package registered in main.dart. There is no manual
/// singleton here; use [context.read<BadgeProvider>()] or
/// [context.watch<BadgeProvider>()] to access it.
class BadgeProvider with ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------

  BadgeProvider() {
    // Listen to auth state so badges reload automatically when the user signs
    // in or out without requiring a full app restart.
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  // ---------------------------------------------------------------------------
  // Private state
  // ---------------------------------------------------------------------------

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _badgeSubscription;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // All badges the app knows about, with their metadata.
  final Map<String, Badge> _definedBadges = {
    'first_mood_log': const Badge(
      id: 'first_mood_log',
      label: 'Mood Monitor',
      imagePath: 'assets/images/badges/first_mood_log.png',
      description: 'Congratulations on logging your first mood entry!',
    ),
    'first_medication_log': const Badge(
      id: 'first_medication_log',
      label: 'Medication Tracker',
      imagePath: 'assets/images/badges/medication_tracker.png',
      description: 'You\'ve successfully logged your first medication entry.',
    ),
    'first_activity_log': const Badge(
      id: 'first_activity_log',
      label: 'Activity Starter',
      imagePath: 'assets/images/badges/activity_starter.png',
      description: 'Great job logging your first activity!',
    ),
    'medication_maestro_10': const Badge(
      id: 'medication_maestro_10',
      label: 'Medication Maestro',
      imagePath: 'assets/images/badges/medication_maestro.png',
      description: 'Logged 10 medication entries. You\'re a pro!',
    ),
    'daily_activity_champion_10': const Badge(
      id: 'daily_activity_champion_10',
      label: 'Daily Activity Champion',
      imagePath: 'assets/images/badges/daily_activity_champion.png',
      description: 'Logged an activity every day for 10 days straight!',
    ),
  };

  // Unlocked status per badge for the currently signed-in user.
  final Map<String, Badge> _userBadges = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns every defined badge merged with the current user's unlock status.
  Map<String, Badge> get badges {
    return _definedBadges.map((id, definedBadge) {
      final userBadge = _userBadges[id];
      return MapEntry(
        id,
        definedBadge.copyWith(unlocked: userBadge?.unlocked ?? false),
      );
    });
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Unlocks a badge for [userId] both optimistically in memory and
  /// persistently in Firestore. No-ops if the badge is already unlocked
  /// or does not exist.
  Future<void> unlockBadge(String badgeId, String userId) async {
    if (userId.isEmpty) return;
    if (!_definedBadges.containsKey(badgeId)) {
      debugPrint(
        'BadgeProvider: Attempted to unlock unknown badge "$badgeId". '
        'Add it to _definedBadges first.',
      );
      return;
    }
    if (_userBadges[badgeId]?.unlocked == true) return; // Already unlocked.

    // Optimistic update so the UI responds instantly.
    _userBadges[badgeId] = _definedBadges[badgeId]!.copyWith(unlocked: true);
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('badges')
          .set({badgeId: true}, SetOptions(merge: true));
    } catch (e) {
      // Revert the optimistic update on failure.
      _userBadges[badgeId] =
          _definedBadges[badgeId]!.copyWith(unlocked: false);
      _errorMessage = 'Failed to save badge progress for "$badgeId".';
      debugPrint('BadgeProvider.unlockBadge error: $e');
      notifyListeners();
    }
  }

  /// Called by [JournalServiceProvider] (or similar) after an entry is saved.
  /// Checks whether the entry qualifies the user for any new badges.
  Future<void> checkForNewBadgesAfterEntry(
    String entryType,
    String userId,
    String elderId,
  ) async {
    if (userId.isEmpty) return;

    // --- First-log badges ---
    if (entryType == 'mood' &&
        !(_userBadges['first_mood_log']?.unlocked ?? false)) {
      await unlockBadge('first_mood_log', userId);
    }

    if (entryType == 'medication' &&
        !(_userBadges['first_medication_log']?.unlocked ?? false)) {
      await unlockBadge('first_medication_log', userId);
    }

    if (entryType == 'activity' &&
        !(_userBadges['first_activity_log']?.unlocked ?? false)) {
      await unlockBadge('first_activity_log', userId);
    }

    // --- Count-based badges ---
    // TODO: Query the actual entry count from Firestore or DayEntriesProvider
    // and unlock 'medication_maestro_10' / 'daily_activity_champion_10' when
    // the thresholds are reached.
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _authSubscription?.cancel();
    _badgeSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Reacts to sign-in / sign-out events.
  void _onAuthStateChanged(User? user) {
    // Cancel any existing Firestore listener before switching users.
    _badgeSubscription?.cancel();
    _badgeSubscription = null;
    _userBadges.clear();
    _errorMessage = null;

    if (user == null) {
      // User signed out — nothing more to do.
      notifyListeners();
      return;
    }

    _listenToBadges(user.uid);
  }

  /// Opens a real-time Firestore listener for the given user's badges document.
  void _listenToBadges(String uid) {
    _badgeSubscription = _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .doc('badges')
        .snapshots()
        .listen(
      (docSnapshot) {
        _errorMessage = null;
        _userBadges.clear();

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          data.forEach((badgeId, isUnlocked) {
            if (_definedBadges.containsKey(badgeId) && isUnlocked is bool) {
              _userBadges[badgeId] =
                  _definedBadges[badgeId]!.copyWith(unlocked: isUnlocked);
            }
          });
        }

        notifyListeners();
      },
      onError: (Object error) {
        _errorMessage = 'Failed to load badge achievements.';
        debugPrint('BadgeProvider._listenToBadges error: $error');
        notifyListeners();
      },
    );
  }
}
