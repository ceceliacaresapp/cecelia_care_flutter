// lib/models/caregiver_points.dart
//
// Gamification ledger for a single caregiver.
//
// Stored as one document per user in the `caregiverPoints` collection.
// Points are awarded by GamificationProvider; this model is the shape.
//
// Point values (defined here as constants so they're easy to tune):
//   Daily check-in:       10 pts
//   Journal entry:        15 pts
//   Breathing exercise:   10 pts
//   Care log entry:        5 pts
//   Weekly challenge:      50 pts (bonus)

import 'package:cloud_firestore/cloud_firestore.dart';

class CaregiverPoints {
  final String? id;
  final String userId;

  /// Lifetime points earned.
  final int totalPoints;

  /// Current consecutive-day streak (days with a wellness check-in).
  final int currentStreak;

  /// Longest streak ever achieved.
  final int longestStreak;

  /// ISO date string of the last check-in that counted toward the streak.
  final String? lastStreakDate;

  /// Whether the user has already used their free weekly streak freeze.
  /// Resets every Monday via GamificationProvider.
  final bool streakFreezeUsed;

  /// The Monday (ISO date) when streakFreezeUsed was last reset.
  final String? streakFreezeResetWeek;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  CaregiverPoints({
    this.id,
    required this.userId,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakDate,
    this.streakFreezeUsed = false,
    this.streakFreezeResetWeek,
    this.createdAt,
    this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // Point constants — single source of truth for the point economy.
  // ---------------------------------------------------------------------------
  static const int kCheckinPoints = 10;
  static const int kJournalPoints = 15;
  static const int kBreathingPoints = 10;
  static const int kCareLogPoints = 5;
  static const int kChallengeBonus = 50;
  static const int kStreakBonus7 = 25;
  static const int kStreakBonus30 = 100;

  // ---------------------------------------------------------------------------
  // Level calculation — logarithmic curve so early levels are quick,
  // later levels take longer. Level 1 at 0 pts, level 50 around 25k pts.
  //
  //   level = 1 + floor( sqrt(totalPoints / 20) )
  //   points for next level = 20 * (level)^2
  // ---------------------------------------------------------------------------
  int get level => 1 + _sqrt(totalPoints ~/ 20);

  int get pointsForNextLevel => 20 * level * level;

  int get pointsIntoCurrentLevel => totalPoints - (20 * (level - 1) * (level - 1));

  double get levelProgress {
    final needed = pointsForNextLevel - (20 * (level - 1) * (level - 1));
    if (needed <= 0) return 1.0;
    return (pointsIntoCurrentLevel / needed).clamp(0.0, 1.0);
  }

  /// Integer square root (no dart:math import needed).
  static int _sqrt(int n) {
    if (n <= 0) return 0;
    int x = n;
    int y = (x + 1) ~/ 2;
    while (y < x) {
      x = y;
      y = (x + n ~/ x) ~/ 2;
    }
    return x;
  }

  // ---------------------------------------------------------------------------
  // Level title — fun names for milestone levels.
  // ---------------------------------------------------------------------------
  String get levelTitle {
    if (level >= 50) return 'Guardian Angel';
    if (level >= 40) return 'Beacon of Hope';
    if (level >= 30) return 'Compassion Master';
    if (level >= 20) return 'Dedicated Caregiver';
    if (level >= 15) return 'Caring Heart';
    if (level >= 10) return 'Wellness Warrior';
    if (level >= 5) return 'Rising Star';
    return 'New Caregiver';
  }

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory CaregiverPoints.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final map = snapshot.data();
    if (map == null) {
      throw StateError('Missing data for CaregiverPoints ${snapshot.id}');
    }
    return CaregiverPoints(
      id: snapshot.id,
      userId: map['userId'] as String,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      currentStreak: (map['currentStreak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
      lastStreakDate: map['lastStreakDate'] as String?,
      streakFreezeUsed: map['streakFreezeUsed'] as bool? ?? false,
      streakFreezeResetWeek: map['streakFreezeResetWeek'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'userId': userId,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastStreakDate != null) 'lastStreakDate': lastStreakDate,
      'streakFreezeUsed': streakFreezeUsed,
      if (streakFreezeResetWeek != null)
        'streakFreezeResetWeek': streakFreezeResetWeek,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CaregiverPoints copyWith({
    String? id,
    String? userId,
    int? totalPoints,
    int? currentStreak,
    int? longestStreak,
    String? lastStreakDate,
    bool? streakFreezeUsed,
    String? streakFreezeResetWeek,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return CaregiverPoints(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakDate: lastStreakDate ?? this.lastStreakDate,
      streakFreezeUsed: streakFreezeUsed ?? this.streakFreezeUsed,
      streakFreezeResetWeek:
          streakFreezeResetWeek ?? this.streakFreezeResetWeek,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
