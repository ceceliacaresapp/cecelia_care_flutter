// lib/models/weekly_challenge.dart
//
// Rotating weekly challenges that give caregivers concrete goals.
//
// Two parts:
//   1. ChallengeDef — the template (title, target count, category, points).
//      Defined as a static pool in this file. New challenges are added here.
//   2. ChallengeProgress — per-user progress for the current week's challenge.
//      Stored in Firestore under `challengeProgress/{userId}_{weekStart}`.
//
// GamificationProvider picks a new challenge every Monday, writes a
// ChallengeProgress doc, and increments `current` as the user completes
// qualifying actions during the week.

import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Challenge category — determines which user actions increment progress.
// ---------------------------------------------------------------------------
enum ChallengeCategory {
  checkin,    // Complete daily wellness check-ins
  journal,    // Write caregiver journal entries
  breathing,  // Complete breathing exercises
  careLog,    // Log care entries for the elder
  mixed,      // Any qualifying action counts
}

// ---------------------------------------------------------------------------
// ChallengeDef — static template. Not stored in Firestore.
// ---------------------------------------------------------------------------
class ChallengeDef {
  final String id;
  final String title;
  final String description;
  final ChallengeCategory category;

  /// Number of actions needed to complete the challenge.
  final int target;

  /// Bonus points awarded on completion (on top of per-action points).
  final int bonusPoints;

  const ChallengeDef({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.target,
    this.bonusPoints = 50,
  });

  // -------------------------------------------------------------------------
  // Challenge pool — add new challenges here. GamificationProvider picks one
  // at random each Monday (avoiding the previous week's challenge).
  // -------------------------------------------------------------------------
  static const List<ChallengeDef> pool = [
    ChallengeDef(
      id: 'checkin_7',
      title: 'Daily check-in streak',
      description: 'Complete a wellness check-in every day this week.',
      category: ChallengeCategory.checkin,
      target: 7,
    ),
    ChallengeDef(
      id: 'journal_3',
      title: 'Reflective writer',
      description: 'Write in your caregiver journal 3 times this week.',
      category: ChallengeCategory.journal,
      target: 3,
    ),
    ChallengeDef(
      id: 'breathing_3',
      title: 'Breathe easy',
      description: 'Complete 3 breathing exercises this week.',
      category: ChallengeCategory.breathing,
      target: 3,
    ),
    ChallengeDef(
      id: 'breathing_5',
      title: 'Deep breather',
      description: 'Complete 5 breathing exercises this week.',
      category: ChallengeCategory.breathing,
      target: 5,
      bonusPoints: 75,
    ),
    ChallengeDef(
      id: 'carelog_10',
      title: 'Consistent caregiver',
      description: 'Log 10 care entries for your care recipient this week.',
      category: ChallengeCategory.careLog,
      target: 10,
    ),
    ChallengeDef(
      id: 'carelog_20',
      title: 'Care champion',
      description: 'Log 20 care entries this week.',
      category: ChallengeCategory.careLog,
      target: 20,
      bonusPoints: 75,
    ),
    ChallengeDef(
      id: 'mixed_15',
      title: 'All-rounder',
      description: 'Complete 15 wellness or care actions this week.',
      category: ChallengeCategory.mixed,
      target: 15,
    ),
    ChallengeDef(
      id: 'checkin_journal_combo',
      title: 'Mind and body',
      description:
          'Check in daily AND journal twice — full self-care package.',
      category: ChallengeCategory.mixed,
      target: 9, // 7 check-ins + 2 journals
      bonusPoints: 75,
    ),
  ];

  /// Finds a challenge definition by id. Returns null if not found.
  static ChallengeDef? byId(String id) {
    try {
      return pool.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// ChallengeProgress — per-user, per-week progress. Stored in Firestore.
// ---------------------------------------------------------------------------
class ChallengeProgress {
  final String? id;
  final String userId;

  /// The challenge definition id (maps to ChallengeDef.pool).
  final String challengeId;

  /// ISO date of the Monday this challenge started (e.g. '2025-03-31').
  final String weekStart;

  /// Current progress count.
  final int current;

  /// Target count (copied from ChallengeDef at creation time so it's
  /// self-contained even if the pool changes later).
  final int target;

  /// Whether the bonus has been awarded (prevents double-awarding).
  final bool completed;

  /// Bonus points for this challenge (copied from ChallengeDef).
  final int bonusPoints;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  ChallengeProgress({
    this.id,
    required this.userId,
    required this.challengeId,
    required this.weekStart,
    this.current = 0,
    required this.target,
    this.completed = false,
    this.bonusPoints = 50,
    this.createdAt,
    this.updatedAt,
  });

  bool get isComplete => current >= target;

  double get progress => target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

  int get remaining => (target - current).clamp(0, target);

  /// Resolves the challenge title from the static pool.
  /// Returns a fallback if the challenge was removed from the pool.
  String get title => ChallengeDef.byId(challengeId)?.title ?? 'Challenge';

  String get description =>
      ChallengeDef.byId(challengeId)?.description ?? '';

  ChallengeCategory get category =>
      ChallengeDef.byId(challengeId)?.category ?? ChallengeCategory.mixed;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory ChallengeProgress.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final map = snapshot.data();
    if (map == null) {
      throw StateError(
          'Missing data for ChallengeProgress ${snapshot.id}');
    }
    return ChallengeProgress(
      id: snapshot.id,
      userId: map['userId'] as String,
      challengeId: map['challengeId'] as String,
      weekStart: map['weekStart'] as String,
      current: (map['current'] as num?)?.toInt() ?? 0,
      target: (map['target'] as num?)?.toInt() ?? 1,
      completed: map['completed'] as bool? ?? false,
      bonusPoints: (map['bonusPoints'] as num?)?.toInt() ?? 50,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'weekStart': weekStart,
      'current': current,
      'target': target,
      'completed': completed,
      'bonusPoints': bonusPoints,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ChallengeProgress copyWith({
    String? id,
    String? userId,
    String? challengeId,
    String? weekStart,
    int? current,
    int? target,
    bool? completed,
    int? bonusPoints,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ChallengeProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      challengeId: challengeId ?? this.challengeId,
      weekStart: weekStart ?? this.weekStart,
      current: current ?? this.current,
      target: target ?? this.target,
      completed: completed ?? this.completed,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
