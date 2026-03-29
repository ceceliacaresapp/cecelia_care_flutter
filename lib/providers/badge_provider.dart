// lib/providers/badge_provider.dart
//
// Manages badge/achievement state for the current user.
//
// BACKWARD COMPATIBLE: Reads the existing users/{uid}/achievements/badges
// document (Map<String, bool>) for legacy unlocked status. Adds tier
// progression data in users/{uid}/achievements/badgeTiers (Map<String, Map>).
//
// Tier upgrades are checked whenever GamificationProvider counters change.
// The UI calls [checkTierProgress] after awarding points or on provider init.

import 'dart:async';
import 'package:flutter/material.dart' hide Badge;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cecelia_care_flutter/models/badge.dart';

class BadgeProvider with ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------

  BadgeProvider() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
  }

  // ---------------------------------------------------------------------------
  // Private state
  // ---------------------------------------------------------------------------

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _badgeSubscription;
  StreamSubscription<DocumentSnapshot>? _tierSubscription;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Legacy badge definitions (kept for backward compat with existing entries).
  final Map<String, Badge> _legacyBadges = {
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

  // Tiered badge state from BadgeCatalog.
  final Map<String, Badge> _tieredBadges = {};

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns all badges — legacy (unlocked booleans) merged with
  /// tiered catalog badges. Tiered badges come first.
  Map<String, Badge> get badges {
    final Map<String, Badge> merged = {};

    // Tiered badges from BadgeCatalog
    for (final entry in _tieredBadges.entries) {
      merged[entry.key] = entry.value;
    }

    // Legacy badges — only add if not already covered by a tiered badge.
    for (final entry in _legacyBadges.entries) {
      if (!merged.containsKey(entry.key)) {
        final userVersion = _userBadges[entry.key];
        merged[entry.key] = userVersion ?? entry.value;
      }
    }

    return Map.unmodifiable(merged);
  }

  /// Just the tiered badges for display on the Self Care tab.
  Map<String, Badge> get tieredBadges => Map.unmodifiable(_tieredBadges);

  /// Unlocks a legacy badge by ID.
  Future<void> unlockBadge(String badgeId, String userId) async {
    if (userId.isEmpty || !_legacyBadges.containsKey(badgeId)) return;
    if (_userBadges[badgeId]?.unlocked == true) return;

    // Optimistic update
    _userBadges[badgeId] = _legacyBadges[badgeId]!.copyWith(unlocked: true);
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc('badges')
          .set({badgeId: true}, SetOptions(merge: true));
    } catch (e) {
      _userBadges[badgeId] =
          _legacyBadges[badgeId]!.copyWith(unlocked: false);
      _errorMessage = 'Failed to save badge progress for "$badgeId".';
      debugPrint('BadgeProvider.unlockBadge error: $e');
      notifyListeners();
    }
  }

  /// Called after a journal/care entry is saved. Checks legacy first-log badges.
  Future<void> checkForNewBadgesAfterEntry(
    String entryType,
    String userId,
    String elderId,
  ) async {
    if (userId.isEmpty) return;

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
  }

  // ---------------------------------------------------------------------------
  // Tier progression — call this with current counts from GamificationProvider.
  //
  // Usage in a screen or another provider:
  //   final gam = context.read<GamificationProvider>();
  //   context.read<BadgeProvider>().checkTierProgress(
  //     streakDays: gam.longestStreak,
  //     journalCount: gam.lifetimeJournals,
  //     breathingCount: gam.lifetimeBreathingSessions,
  //     careLogCount: gam.lifetimeCareLogs,
  //     challengeCount: gam.lifetimeChallengesCompleted,
  //     totalPoints: gam.totalPoints,
  //     moodDays: gam.lifetimeCheckins,
  //   );
  // ---------------------------------------------------------------------------

  Future<void> checkTierProgress({
    int streakDays = 0,
    int journalCount = 0,
    int breathingCount = 0,
    int careLogCount = 0,
    int challengeCount = 0,
    int totalPoints = 0,
    int moodDays = 0,
    int selfCareActions = 0,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final counts = {
      'streak': streakDays,
      'journal': journalCount,
      'breathing': breathingCount,
      'care_log': careLogCount,
      'challenges': challengeCount,
      'points': totalPoints,
      'mood_tracker': moodDays,
      'self_care': selfCareActions,
    };

    bool changed = false;
    final Map<String, dynamic> tierUpdates = {};

    for (final template in BadgeCatalog.all) {
      if (template.thresholds == null) continue;

      final count = counts[template.id] ?? 0;
      final newTier = template.thresholds!.tierForCount(count);
      final current = _tieredBadges[template.id];
      final currentTier = current?.tier ?? BadgeTier.none;

      if (newTier.index > currentTier.index) {
        // Tier upgraded!
        _tieredBadges[template.id] = template.copyWith(
          tier: newTier,
          unlocked: true,
          progressCount: count,
        );
        tierUpdates[template.id] = {
          'tier': newTier.name,
          'progressCount': count,
          'unlockedAt': FieldValue.serverTimestamp(),
        };
        changed = true;
      } else if (count != (current?.progressCount ?? 0)) {
        // Progress updated but no tier change.
        _tieredBadges[template.id] = (current ?? template).copyWith(
          progressCount: count,
        );
        tierUpdates[template.id] = {
          'tier': (current?.tier ?? newTier).name,
          'progressCount': count,
        };
        changed = true;
      }
    }

    if (tierUpdates.isNotEmpty) {
      try {
        await _db
            .collection('users')
            .doc(uid)
            .collection('achievements')
            .doc('badgeTiers')
            .set(tierUpdates, SetOptions(merge: true));
      } catch (e) {
        debugPrint('BadgeProvider.checkTierProgress save error: $e');
      }
    }

    if (changed) notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _authSubscription?.cancel();
    _badgeSubscription?.cancel();
    _tierSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _onAuthStateChanged(User? user) {
    _badgeSubscription?.cancel();
    _tierSubscription?.cancel();
    _badgeSubscription = null;
    _tierSubscription = null;
    _userBadges.clear();
    _tieredBadges.clear();
    _errorMessage = null;

    if (user == null) {
      notifyListeners();
      return;
    }

    _listenToBadges(user.uid);
    _listenToTiers(user.uid);
  }

  /// Listens to the legacy badges document (Map<String, bool>).
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
            if (_legacyBadges.containsKey(badgeId) && isUnlocked is bool) {
              _userBadges[badgeId] =
                  _legacyBadges[badgeId]!.copyWith(unlocked: isUnlocked);
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

  /// Listens to the tiered badge document.
  void _listenToTiers(String uid) {
    _tierSubscription = _db
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .doc('badgeTiers')
        .snapshots()
        .listen(
      (docSnapshot) {
        // Initialize all catalog badges with defaults.
        for (final template in BadgeCatalog.all) {
          _tieredBadges.putIfAbsent(template.id, () => template);
        }

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          for (final template in BadgeCatalog.all) {
            final saved = data[template.id];
            if (saved is Map<String, dynamic>) {
              final tierName = saved['tier'] as String? ?? 'none';
              final count = (saved['progressCount'] as num?)?.toInt() ?? 0;
              BadgeTier tier;
              try {
                tier = BadgeTier.values.firstWhere(
                  (t) => t.name == tierName,
                  orElse: () => BadgeTier.none,
                );
              } catch (_) {
                tier = BadgeTier.none;
              }
              _tieredBadges[template.id] = template.copyWith(
                tier: tier,
                unlocked: tier != BadgeTier.none,
                progressCount: count,
              );
            }
          }
        }

        notifyListeners();
      },
      onError: (Object error) {
        debugPrint('BadgeProvider._listenToTiers error: $error');
      },
    );
  }
}
