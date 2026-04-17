// lib/providers/gamification_provider.dart
//
// Central gamification engine. Manages:
//   • Points ledger (award, query total, level)
//   • Streak tracking (daily check-in streak, freeze, break)
//   • Weekly challenges (pick, track progress, award bonus)
//   • Level-up detection (emits events for the UI to celebrate)
//
// Storage:
//   caregiverPoints/{userId}      — one doc per user
//   challengeProgress/{userId}_{weekStart} — one doc per user per week
//
// This provider does NOT directly modify badges — it exposes counts that
// BadgeProvider reads to upgrade tiers.

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/caregiver_points.dart';
import 'package:cecelia_care_flutter/models/weekly_challenge.dart';

class GamificationProvider with ChangeNotifier {
  GamificationProvider() {
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _pointsCollection = 'caregiverPoints';
  static const String _challengeCollection = 'challengeProgress';

  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot>? _pointsSub;
  StreamSubscription<QuerySnapshot>? _challengeSub;

  String? _userId;
  bool _isLoading = false;

  CaregiverPoints? _points;
  ChallengeProgress? _currentChallenge;

  /// Set to true when a level-up just happened. The UI reads this once
  /// to show a celebration modal, then calls [clearLevelUp].
  bool _levelUpPending = false;
  int _previousLevel = 0;

  // ---------------------------------------------------------------------------
  // Counters — lifetime action counts used by BadgeProvider for tier checks.
  // Stored as fields in the caregiverPoints doc for simplicity.
  // ---------------------------------------------------------------------------
  int _lifetimeCheckins = 0;
  int _lifetimeJournals = 0;
  int _lifetimeBreathingSessions = 0;
  int _lifetimeCareLogs = 0;
  int _lifetimeChallengesCompleted = 0;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  CaregiverPoints? get points => _points;
  ChallengeProgress? get currentChallenge => _currentChallenge;
  bool get levelUpPending => _levelUpPending;

  int get totalPoints => _points?.totalPoints ?? 0;
  int get currentStreak => _points?.currentStreak ?? 0;
  int get longestStreak => _points?.longestStreak ?? 0;
  int get level => _points?.level ?? 1;
  String get levelTitle => _points?.levelTitle ?? 'New Caregiver';
  double get levelProgress => _points?.levelProgress ?? 0.0;
  int get pointsForNextLevel => _points?.pointsForNextLevel ?? 20;

  // Counters for badge tier checks
  int get lifetimeCheckins => _lifetimeCheckins;
  int get lifetimeJournals => _lifetimeJournals;
  int get lifetimeBreathingSessions => _lifetimeBreathingSessions;
  int get lifetimeCareLogs => _lifetimeCareLogs;
  int get lifetimeChallengesCompleted => _lifetimeChallengesCompleted;

  void clearLevelUp() {
    _levelUpPending = false;
    // No notifyListeners — the UI already consumed the flag.
  }

  // ---------------------------------------------------------------------------
  // Award points — called by other providers/screens after user actions.
  // ---------------------------------------------------------------------------

  /// Generic point award. Returns the new total.
  Future<int> awardPoints(int amount, {String? reason}) async {
    if (_userId == null || amount <= 0) return totalPoints;

    await _ensurePointsDoc();
    try {
      await _db.collection(_pointsCollection).doc(_userId).update({
        'totalPoints': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('GamificationProvider.awardPoints error: $e');
    }

    // Level-up detection happens in the stream listener (_onPointsChanged).
    return totalPoints + amount; // optimistic
  }

  /// Award points for a daily wellness check-in + update streak.
  Future<void> onCheckinCompleted() async {
    if (_userId == null) return;

    await _ensurePointsDoc();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastDate = _points?.lastStreakDate;

    int newStreak = 1;
    bool freezeUsed = _points?.streakFreezeUsed ?? false;

    if (lastDate != null && lastDate != today) {
      final lastDt = DateTime.tryParse(lastDate);
      final todayDt = DateTime.now();
      if (lastDt != null) {
        final diff = todayDt.difference(lastDt).inDays;
        if (diff == 1) {
          // Consecutive day
          newStreak = (_points?.currentStreak ?? 0) + 1;
        } else if (diff == 2 && !freezeUsed) {
          // Missed one day — use streak freeze
          newStreak = (_points?.currentStreak ?? 0) + 1;
          freezeUsed = true;
        }
        // diff > 2 or freeze already used → streak resets to 1
      }
    } else if (lastDate == today) {
      // Already checked in today — don't double-count streak.
      // Still award points below.
      newStreak = _points?.currentStreak ?? 1;
    }

    final newLongest = max(newStreak, _points?.longestStreak ?? 0);

    // Streak bonus points
    int bonusPoints = 0;
    if (newStreak == 7) bonusPoints = CaregiverPoints.kStreakBonus7;
    if (newStreak == 30) bonusPoints = CaregiverPoints.kStreakBonus30;

    try {
      await _db.collection(_pointsCollection).doc(_userId).update({
        'totalPoints': FieldValue.increment(
            CaregiverPoints.kCheckinPoints + bonusPoints),
        'currentStreak': newStreak,
        'longestStreak': newLongest,
        'lastStreakDate': today,
        'streakFreezeUsed': freezeUsed,
        'lifetimeCheckins': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('GamificationProvider.onCheckinCompleted error: $e');
    }

    // Increment challenge progress if applicable.
    _incrementChallengeIfMatches(ChallengeCategory.checkin);
  }

  /// Award points for a journal entry.
  Future<void> onJournalWritten() async {
    await _ensurePointsDoc();
    try {
      await _db.collection(_pointsCollection).doc(_userId).update({
        'totalPoints': FieldValue.increment(CaregiverPoints.kJournalPoints),
        'lifetimeJournals': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('GamificationProvider.onJournalWritten error: $e');
    }
    _incrementChallengeIfMatches(ChallengeCategory.journal);
  }

  /// Award points for completing a breathing exercise.
  Future<void> onBreathingCompleted() async {
    await _ensurePointsDoc();
    try {
      await _db.collection(_pointsCollection).doc(_userId).update({
        'totalPoints':
            FieldValue.increment(CaregiverPoints.kBreathingPoints),
        'lifetimeBreathingSessions': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('GamificationProvider.onBreathingCompleted error: $e');
    }
    _incrementChallengeIfMatches(ChallengeCategory.breathing);
  }

  /// Award points for a care log entry (mood, med, sleep, etc.).
  Future<void> onCareLogEntry() async {
    await _ensurePointsDoc();
    try {
      await _db.collection(_pointsCollection).doc(_userId).update({
        'totalPoints': FieldValue.increment(CaregiverPoints.kCareLogPoints),
        'lifetimeCareLogs': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('GamificationProvider.onCareLogEntry error: $e');
    }
    _incrementChallengeIfMatches(ChallengeCategory.careLog);
  }

  // ---------------------------------------------------------------------------
  // Weekly challenges
  // ---------------------------------------------------------------------------

  /// Ensures a challenge exists for the current week. Picks a new one if
  /// none exists. Called during auth listener initialization.
  Future<void> ensureWeeklyChallenge() async {
    if (_userId == null) return;

    final weekStart = _currentWeekStart();
    final docId = '${_userId}_$weekStart';

    try {
      // Use a query (not doc get) so Firestore security rules can evaluate
      // resource.data.userId == request.auth.uid.
      final snap = await _db
          .collection(_challengeCollection)
          .where('userId', isEqualTo: _userId)
          .where('weekStart', isEqualTo: weekStart)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        // Pick a random challenge, avoiding last week's.
        final lastWeek = _weekStartOffset(-1);
        final lastSnap = await _db
            .collection(_challengeCollection)
            .where('userId', isEqualTo: _userId)
            .where('weekStart', isEqualTo: lastWeek)
            .limit(1)
            .get();
        final lastChallengeId = lastSnap.docs.isNotEmpty
            ? (lastSnap.docs.first.data()['challengeId'] as String?)
            : null;

        final candidates = ChallengeDef.pool
            .where((c) => c.id != lastChallengeId)
            .toList();
        final chosen = candidates[Random().nextInt(candidates.length)];

        final progress = ChallengeProgress(
          userId: _userId!,
          challengeId: chosen.id,
          weekStart: weekStart,
          target: chosen.target,
          bonusPoints: chosen.bonusPoints,
        );

        await _db
            .collection(_challengeCollection)
            .doc(docId)
            .set(progress.toFirestore());
      }
    } catch (e) {
      debugPrint('GamificationProvider.ensureWeeklyChallenge error: $e');
    }
  }

  /// Increments the current challenge's progress if the action category
  /// matches (or the challenge is `mixed`).
  Future<void> _incrementChallengeIfMatches(
      ChallengeCategory actionCategory) async {
    if (_userId == null || _currentChallenge == null) return;
    if (_currentChallenge!.completed) return;

    final challengeCategory = _currentChallenge!.category;
    if (challengeCategory != actionCategory &&
        challengeCategory != ChallengeCategory.mixed) {
      return;
    }

    final weekStart = _currentWeekStart();
    final docId = '${_userId}_$weekStart';

    try {
      await _db.collection(_challengeCollection).doc(docId).update({
        'current': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Check completion (the stream will update _currentChallenge,
      // but we check eagerly so the bonus is awarded promptly).
      final newCurrent = (_currentChallenge!.current) + 1;
      if (newCurrent >= _currentChallenge!.target &&
          !_currentChallenge!.completed) {
        await _db.collection(_challengeCollection).doc(docId).update({
          'completed': true,
        });
        // Award challenge bonus
        await awardPoints(_currentChallenge!.bonusPoints,
            reason: 'Weekly challenge completed');
        // Increment lifetime counter
        await _db.collection(_pointsCollection).doc(_userId).update({
          'lifetimeChallengesCompleted': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint(
          'GamificationProvider._incrementChallengeIfMatches error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Streak freeze reset — should be called on app start or when the
  // provider initializes. Resets the freeze flag every Monday.
  // ---------------------------------------------------------------------------
  Future<void> _resetStreakFreezeIfNewWeek() async {
    if (_userId == null || _points == null) return;

    final currentMonday = _currentWeekStart();
    if (_points!.streakFreezeResetWeek != currentMonday) {
      try {
        await _db.collection(_pointsCollection).doc(_userId).update({
          'streakFreezeUsed': false,
          'streakFreezeResetWeek': currentMonday,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        debugPrint(
            'GamificationProvider._resetStreakFreezeIfNewWeek error: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Ensures a caregiverPoints doc exists for the current user.
  Future<void> _ensurePointsDoc() async {
    if (_userId == null) return;
    final ref = _db.collection(_pointsCollection).doc(_userId);
    final doc = await ref.get();
    if (!doc.exists) {
      final initial = CaregiverPoints(userId: _userId!);
      await ref.set(initial.toFirestore());
    }
  }

  /// Returns the Monday of the current week as 'yyyy-MM-dd'.
  String _currentWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  /// Returns the Monday of a week offset from current.
  String _weekStartOffset(int offset) {
    final now = DateTime.now();
    final monday = now
        .subtract(Duration(days: now.weekday - 1))
        .add(Duration(days: offset * 7));
    return DateFormat('yyyy-MM-dd').format(monday);
  }

  // ---------------------------------------------------------------------------
  // Auth + Firestore listeners
  // ---------------------------------------------------------------------------

  void _onAuthChanged(User? user) {
    _pointsSub?.cancel();
    _challengeSub?.cancel();
    _pointsSub = null;
    _challengeSub = null;
    _points = null;
    _currentChallenge = null;
    _userId = user?.uid;
    _levelUpPending = false;
    _previousLevel = 0;

    if (user == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscribeToPoints(user.uid);
    _subscribeToCurrentChallenge(user.uid);

    // Deferred initialization
    Future.microtask(() async {
      await _ensurePointsDoc();
      await ensureWeeklyChallenge();
      await _resetStreakFreezeIfNewWeek();
    });
  }

  void _subscribeToPoints(String uid) {
    _pointsSub = _db
        .collection(_pointsCollection)
        .doc(uid)
        .snapshots()
        .listen(
      (doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          data['id'] = doc.id;

          _previousLevel = _points?.level ?? 1;
          _points = CaregiverPoints.fromFirestore(
            doc,
          );

          // Read lifetime counters (stored as extra fields on the doc).
          _lifetimeCheckins =
              (data['lifetimeCheckins'] as num?)?.toInt() ?? 0;
          _lifetimeJournals =
              (data['lifetimeJournals'] as num?)?.toInt() ?? 0;
          _lifetimeBreathingSessions =
              (data['lifetimeBreathingSessions'] as num?)?.toInt() ?? 0;
          _lifetimeCareLogs =
              (data['lifetimeCareLogs'] as num?)?.toInt() ?? 0;
          _lifetimeChallengesCompleted =
              (data['lifetimeChallengesCompleted'] as num?)?.toInt() ?? 0;

          // Level-up detection
          if (_previousLevel > 0 && _points!.level > _previousLevel) {
            _levelUpPending = true;
          }
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('GamificationProvider._subscribeToPoints error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void _subscribeToCurrentChallenge(String uid) {
    final weekStart = _currentWeekStart();

    // Query by userId field (not doc ID) so Firestore security rules can
    // evaluate resource.data.userId == request.auth.uid.
    _challengeSub = _db
        .collection(_challengeCollection)
        .where('userId', isEqualTo: uid)
        .where('weekStart', isEqualTo: weekStart)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          _currentChallenge = ChallengeProgress.fromFirestore(
            snapshot.docs.first
                as DocumentSnapshot<Map<String, dynamic>>,
          );
        } else {
          _currentChallenge = null;
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint(
            'GamificationProvider._subscribeToCurrentChallenge error: $e');
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _authSub?.cancel();
    _pointsSub?.cancel();
    _challengeSub?.cancel();
    super.dispose();
  }
}
