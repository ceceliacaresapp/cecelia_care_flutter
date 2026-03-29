// lib/models/wellness_checkin.dart
//
// Daily caregiver wellness check-in — the data backbone for burnout detection.
//
// Five dimensions, each scored 1–5:
//   mood, sleepQuality, exercise, socialConnection, meTime
//
// The burnout risk score is computed client-side from the last 7 days of
// check-ins (see WellnessProvider). This model is just the storage shape.

import 'package:cloud_firestore/cloud_firestore.dart';

class WellnessCheckin {
  final String? id;
  final String userId;

  /// ISO date string (yyyy-MM-dd) — one check-in per user per day.
  final String dateString;

  // Each dimension is 1–5:
  //   1 = struggling / terrible / none / isolated / zero
  //   5 = thriving / great / solid workout / quality time / recharged
  final int mood;
  final int sleepQuality;
  final int exercise;
  final int socialConnection;
  final int meTime;

  /// Optional free-text note attached to the check-in.
  final String? note;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  WellnessCheckin({
    this.id,
    required this.userId,
    required this.dateString,
    required this.mood,
    required this.sleepQuality,
    required this.exercise,
    required this.socialConnection,
    required this.meTime,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  // ---------------------------------------------------------------------------
  // Computed — composite wellbeing score (0–100, higher = healthier).
  //
  // Weights: mood 30%, sleep 25%, social 20%, meTime 15%, exercise 10%.
  // Each dimension is (value - 1) / 4 to normalize 1–5 → 0.0–1.0,
  // then the weighted sum is scaled to 0–100.
  // ---------------------------------------------------------------------------
  double get wellbeingScore {
    final m = (mood - 1) / 4;
    final s = (sleepQuality - 1) / 4;
    final e = (exercise - 1) / 4;
    final sc = (socialConnection - 1) / 4;
    final mt = (meTime - 1) / 4;
    return (m * 0.30 + s * 0.25 + sc * 0.20 + mt * 0.15 + e * 0.10) * 100;
  }

  /// Burnout risk is the inverse of wellbeing: 100 - wellbeingScore.
  /// 0 = no risk, 100 = critical.
  double get burnoutRisk => 100 - wellbeingScore;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory WellnessCheckin.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final map = snapshot.data();
    if (map == null) {
      throw StateError('Missing data for WellnessCheckin ${snapshot.id}');
    }
    return WellnessCheckin(
      id: snapshot.id,
      userId: map['userId'] as String,
      dateString: map['dateString'] as String,
      mood: (map['mood'] as num).toInt(),
      sleepQuality: (map['sleepQuality'] as num).toInt(),
      exercise: (map['exercise'] as num).toInt(),
      socialConnection: (map['socialConnection'] as num).toInt(),
      meTime: (map['meTime'] as num).toInt(),
      note: map['note'] as String?,
      createdAt: map['createdAt'] as Timestamp?,
      updatedAt: map['updatedAt'] as Timestamp?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'userId': userId,
      'dateString': dateString,
      'mood': mood,
      'sleepQuality': sleepQuality,
      'exercise': exercise,
      'socialConnection': socialConnection,
      'meTime': meTime,
      if (note != null) 'note': note,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  WellnessCheckin copyWith({
    String? id,
    String? userId,
    String? dateString,
    int? mood,
    int? sleepQuality,
    int? exercise,
    int? socialConnection,
    int? meTime,
    String? note,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return WellnessCheckin(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateString: dateString ?? this.dateString,
      mood: mood ?? this.mood,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      exercise: exercise ?? this.exercise,
      socialConnection: socialConnection ?? this.socialConnection,
      meTime: meTime ?? this.meTime,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Display helpers
  // ---------------------------------------------------------------------------

  static const List<String> moodLabels = [
    'Struggling',
    'Low',
    'Okay',
    'Good',
    'Thriving',
  ];

  static const List<String> sleepLabels = [
    'Terrible',
    'Poor',
    'Fair',
    'Good',
    'Great',
  ];

  static const List<String> exerciseLabels = [
    'None',
    'Light walk',
    'Some movement',
    'Good session',
    'Solid workout',
  ];

  static const List<String> socialLabels = [
    'Isolated',
    'Brief contact',
    'Some interaction',
    'Good connection',
    'Quality time',
  ];

  static const List<String> meTimeLabels = [
    'Zero',
    'A few minutes',
    'Some downtime',
    'Good break',
    'Recharged',
  ];

  String get moodLabel => moodLabels[mood.clamp(1, 5) - 1];
  String get sleepLabel => sleepLabels[sleepQuality.clamp(1, 5) - 1];
  String get exerciseLabel => exerciseLabels[exercise.clamp(1, 5) - 1];
  String get socialLabel => socialLabels[socialConnection.clamp(1, 5) - 1];
  String get meTimeLabel => meTimeLabels[meTime.clamp(1, 5) - 1];
}
