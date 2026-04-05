// lib/providers/wellness_provider.dart
//
// Manages daily wellness check-ins and burnout detection.
//
// Data: one doc per user per day in `wellnessCheckins/{userId}_{date}`.
// Burnout risk is computed client-side from the last 7 days.
//
// Burnout risk levels:
//   Green  (0–30)  → "You're doing well"
//   Yellow (31–60) → Proactive nudge (mood dipped, suggest relief tool)
//   Red    (61–100)→ SOS mode surfaces automatically

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:cecelia_care_flutter/models/wellness_checkin.dart';

// ---------------------------------------------------------------------------
// Risk level enum — drives UI treatment and nudge logic.
// ---------------------------------------------------------------------------
enum BurnoutRiskLevel { green, yellow, red }

class BurnoutStatus {
  final double score;
  final BurnoutRiskLevel level;
  final String message;
  final String? nudge;

  /// Placeholder for future AI-generated insight. null = rule-based only.
  final String? aiInsight;

  const BurnoutStatus({
    required this.score,
    required this.level,
    required this.message,
    this.nudge,
    this.aiInsight,
  });

  static BurnoutStatus fromScore(double burnoutRisk) {
    if (burnoutRisk <= 30) {
      return BurnoutStatus(
        score: burnoutRisk,
        level: BurnoutRiskLevel.green,
        message: "You're taking good care of yourself. Keep it up!",
      );
    }
    if (burnoutRisk <= 60) {
      return BurnoutStatus(
        score: burnoutRisk,
        level: BurnoutRiskLevel.yellow,
        message:
            "Your wellbeing has dipped recently. A short break could help.",
        nudge: "Try a breathing exercise or write in your journal.",
      );
    }
    return BurnoutStatus(
      score: burnoutRisk,
      level: BurnoutRiskLevel.red,
      message:
          "You're showing signs of burnout. Please take care of yourself.",
      nudge: "Consider taking 5 minutes for yourself right now.",
    );
  }
}

// ---------------------------------------------------------------------------
// Mood trend — detects multi-day negative streaks.
// ---------------------------------------------------------------------------
class MoodTrend {
  /// Number of consecutive recent days with mood ≤ 2.
  final int negativeDays;

  /// True if 3+ consecutive low-mood days detected.
  final bool alert;

  final String? message;

  const MoodTrend({
    required this.negativeDays,
    required this.alert,
    this.message,
  });
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------
class WellnessProvider with ChangeNotifier {
  WellnessProvider() {
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'wellnessCheckins';

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot>? _checkinSub;

  String? _userId;
  bool _isLoading = false;
  String? _error;

  /// Last 7 days of check-ins, newest first.
  List<WellnessCheckin> _recentCheckins = [];

  /// Today's check-in (null if not yet completed today).
  WellnessCheckin? _todayCheckin;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<WellnessCheckin> get recentCheckins => _recentCheckins;
  WellnessCheckin? get todayCheckin => _todayCheckin;
  bool get hasCheckedInToday => _todayCheckin != null;

  /// 7-day average burnout risk (0–100). Returns 0 if no data.
  double get burnoutRisk {
    if (_recentCheckins.isEmpty) return 0;
    final total =
        _recentCheckins.fold<double>(0, (sum, c) => sum + c.burnoutRisk);
    return total / _recentCheckins.length;
  }

  /// Structured burnout status with level, message, and nudge.
  BurnoutStatus get burnoutStatus => BurnoutStatus.fromScore(burnoutRisk);

  /// 7-day average wellbeing score (0–100).
  double get wellbeingScore => 100 - burnoutRisk;

  /// Detects consecutive low-mood days (mood ≤ 2).
  MoodTrend get moodTrend {
    if (_recentCheckins.isEmpty) {
      return const MoodTrend(negativeDays: 0, alert: false);
    }
    // Check-ins are newest-first. Count consecutive low-mood days from today.
    int count = 0;
    for (final c in _recentCheckins) {
      if (c.mood <= 2) {
        count++;
      } else {
        break;
      }
    }
    return MoodTrend(
      negativeDays: count,
      alert: count >= 3,
      message: count >= 3
          ? "Your mood has been low for $count days in a row. "
              "Please consider reaching out to someone you trust."
          : null,
    );
  }

  /// Per-dimension 7-day averages for the trend card.
  Map<String, double> get dimensionAverages {
    if (_recentCheckins.isEmpty) return {};
    final n = _recentCheckins.length;
    return {
      'Mood': _recentCheckins.fold<double>(0, (s, c) => s + c.mood) / n,
      'Sleep': _recentCheckins.fold<double>(
              0, (s, c) => s + c.sleepQuality) /
          n,
      'Exercise':
          _recentCheckins.fold<double>(0, (s, c) => s + c.exercise) / n,
      'Social': _recentCheckins.fold<double>(
              0, (s, c) => s + c.socialConnection) /
          n,
      'Me-time':
          _recentCheckins.fold<double>(0, (s, c) => s + c.meTime) / n,
    };
  }

  /// True when average wellbeingScore across the most recent 3+ days is <= 40.
  bool get burnoutThresholdTriggered {
    if (_recentCheckins.length < 3) return false;
    final recent3 = _recentCheckins.take(3).toList();
    return recent3.every((c) => c.wellbeingScore <= 40);
  }

  /// The dimension with the lowest average this week, or null.
  String? get weakestDimension {
    final avgs = dimensionAverages;
    if (avgs.isEmpty) return null;
    final sorted = avgs.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.first.key;
  }

  bool _burnoutNudgeFired = false;

  // ---------------------------------------------------------------------------
  // Save / update today's check-in
  // ---------------------------------------------------------------------------

  Future<void> saveCheckin({
    required int mood,
    required int sleepQuality,
    required int exercise,
    required int socialConnection,
    required int meTime,
    String? note,
  }) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docId = '${uid}_$today';

    final checkin = WellnessCheckin(
      userId: uid,
      dateString: today,
      mood: mood.clamp(1, 5),
      sleepQuality: sleepQuality.clamp(1, 5),
      exercise: exercise.clamp(1, 5),
      socialConnection: socialConnection.clamp(1, 5),
      meTime: meTime.clamp(1, 5),
      note: note,
    );

    try {
      await _db
          .collection(_collection)
          .doc(docId)
          .set(checkin.toFirestore(), SetOptions(merge: true));
      // The stream listener will pick up the change and update state.

      // Fire burnout nudge on threshold transition (not every save).
      if (burnoutThresholdTriggered && !_burnoutNudgeFired) {
        _burnoutNudgeFired = true;
        NotificationService.instance.fireBurnoutNudge();
      }
      if (!burnoutThresholdTriggered) {
        _burnoutNudgeFired = false;
      }
    } catch (e) {
      _error = 'Could not save check-in: $e';
      debugPrint('WellnessProvider.saveCheckin error: $e');
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // AI insight placeholder
  //
  // Framework is in place. When ready, call Gemini with the 7-day check-in
  // data and burnout score to generate a personalized insight. For now
  // this returns null and the UI falls back to rule-based messages.
  // ---------------------------------------------------------------------------
  Future<String?> getAiInsight() async {
    // TODO: Integrate with GeminiService when AI feedback is enabled.
    // Example payload:
    //   { "burnoutRisk": burnoutRisk,
    //     "moodTrend": moodTrend.negativeDays,
    //     "recentCheckins": _recentCheckins.map((c) => c.toFirestore()),
    //   }
    // For now, return null — the UI shows BurnoutStatus.message instead.
    return null;
  }

  // ---------------------------------------------------------------------------
  // Auth + Firestore listeners
  // ---------------------------------------------------------------------------

  void _onAuthChanged(User? user) {
    _checkinSub?.cancel();
    _checkinSub = null;
    _recentCheckins = [];
    _todayCheckin = null;
    _error = null;
    _userId = user?.uid;

    if (user == null) {
      notifyListeners();
      return;
    }

    _subscribeToRecentCheckins(user.uid);
  }

  void _subscribeToRecentCheckins(String uid) {
    _isLoading = true;
    notifyListeners();

    // Query last 7 days of check-ins for this user.
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final cutoff = DateFormat('yyyy-MM-dd').format(sevenDaysAgo);

    _checkinSub = _db
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .where('dateString', isGreaterThanOrEqualTo: cutoff)
        .orderBy('dateString', descending: true)
        .limit(7)
        .snapshots()
        .listen(
      (snapshot) {
        _error = null;
        _recentCheckins = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return WellnessCheckin(
            id: doc.id,
            userId: data['userId'] as String,
            dateString: data['dateString'] as String,
            mood: (data['mood'] as num).toInt(),
            sleepQuality: (data['sleepQuality'] as num).toInt(),
            exercise: (data['exercise'] as num).toInt(),
            socialConnection: (data['socialConnection'] as num).toInt(),
            meTime: (data['meTime'] as num).toInt(),
            note: data['note'] as String?,
            createdAt: data['createdAt'] as Timestamp?,
            updatedAt: data['updatedAt'] as Timestamp?,
          );
        }).toList();

        // Identify today's check-in.
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        _todayCheckin = _recentCheckins
            .cast<WellnessCheckin?>()
            .firstWhere((c) => c?.dateString == today, orElse: () => null);

        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Could not load check-ins.';
        _isLoading = false;
        debugPrint('WellnessProvider._subscribeToRecentCheckins error: $e');
        notifyListeners();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _authSub?.cancel();
    _checkinSub?.cancel();
    super.dispose();
  }
}
