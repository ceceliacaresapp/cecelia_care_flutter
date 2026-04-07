// lib/models/cognitive_assessment.dart
//
// Result record for an in-app cognitive screening session. Each completed
// assessment captures sub-scores for 7 clinical sub-tests (Mini-Cog, SLUMS,
// Trail Making, Digit Span, Category Fluency, Orientation, Pattern Sequence)
// plus the raw data needed for clinical review.
//
// Total possible score: 34. Stored monthly under
// elderProfiles/{elderId}/cognitiveAssessments.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CognitiveAssessment {
  final String? id;
  final String elderId;
  final String assessedBy;
  final String assessedByName;
  final String monthString; // 'yyyy-MM'

  // Sub-scores. null = test skipped.
  final int? wordRecallScore; // 0-5
  final int? clockDrawingScore; // 0-4
  final int? trailMakingScore; // 0-5
  final int? digitSpanScore; // 0-5
  final int? categoryFluencyScore; // 0-5
  final int? orientationScore; // 0-6
  final int? patternSequenceScore; // 0-4

  // Raw data for clinical review.
  final List<String>? wordsShown;
  final List<String>? wordsRecalled;
  final int? trailMakingTimeSeconds;
  final int? trailMakingErrors;
  final int? digitSpanMaxForward;
  final int? digitSpanMaxBackward;
  final int? categoryFluencyCount;
  final String? categoryFluencyCategory;
  final Map<String, bool>? orientationAnswers;

  final String? notes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CognitiveAssessment({
    this.id,
    required this.elderId,
    required this.assessedBy,
    required this.assessedByName,
    required this.monthString,
    this.wordRecallScore,
    this.clockDrawingScore,
    this.trailMakingScore,
    this.digitSpanScore,
    this.categoryFluencyScore,
    this.orientationScore,
    this.patternSequenceScore,
    this.wordsShown,
    this.wordsRecalled,
    this.trailMakingTimeSeconds,
    this.trailMakingErrors,
    this.digitSpanMaxForward,
    this.digitSpanMaxBackward,
    this.categoryFluencyCount,
    this.categoryFluencyCategory,
    this.orientationAnswers,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // ── Domain max-points lookup ──────────────────────────────────
  static const Map<String, int> kDomainMax = {
    'Memory': 5,
    'Visuospatial': 4,
    'Attention': 5,
    'Working Memory': 5,
    'Language': 5,
    'Orientation': 6,
    'Executive': 4,
  };

  static const int kMaxTotalScore = 34;

  static const Map<String, String> kDomainDescriptions = {
    'Memory':
        'Ability to learn and recall new information after a delay. The single most predictive marker for early dementia.',
    'Visuospatial':
        'Ability to process visual information and produce a spatial representation (like drawing a clock).',
    'Attention':
        'Sustained focus and the ability to track sequences without losing place.',
    'Working Memory':
        'Holding information in mind and manipulating it (like repeating digits backward).',
    'Language':
        'Word generation and verbal fluency under a time pressure.',
    'Orientation':
        'Awareness of time, place, and current events.',
    'Executive':
        'Higher-level reasoning, pattern recognition, and mental flexibility.',
  };

  // ── Computed scores ───────────────────────────────────────────

  int get totalScore =>
      (wordRecallScore ?? 0) +
      (clockDrawingScore ?? 0) +
      (trailMakingScore ?? 0) +
      (digitSpanScore ?? 0) +
      (categoryFluencyScore ?? 0) +
      (orientationScore ?? 0) +
      (patternSequenceScore ?? 0);

  int get maxPossibleScore {
    int max = 0;
    if (wordRecallScore != null) max += 5;
    if (clockDrawingScore != null) max += 4;
    if (trailMakingScore != null) max += 5;
    if (digitSpanScore != null) max += 5;
    if (categoryFluencyScore != null) max += 5;
    if (orientationScore != null) max += 6;
    if (patternSequenceScore != null) max += 4;
    return max;
  }

  double get scorePercent =>
      maxPossibleScore > 0 ? totalScore / maxPossibleScore : 0;

  String get cognitiveLevel {
    final pct = scorePercent;
    if (pct >= 0.85) return 'Normal';
    if (pct >= 0.70) return 'Mild Impairment';
    if (pct >= 0.50) return 'Moderate Impairment';
    return 'Severe Impairment';
  }

  Color get levelColor {
    final pct = scorePercent;
    if (pct >= 0.85) return const Color(0xFF43A047);
    if (pct >= 0.70) return const Color(0xFF1E88E5);
    if (pct >= 0.50) return const Color(0xFFF57C00);
    return const Color(0xFFE53935);
  }

  /// Per-domain normalized scores (0..1) for radar/dimension chart.
  /// Domains where the test was skipped are reported as null.
  Map<String, double?> get domainScores => {
        'Memory': _norm(wordRecallScore, 5),
        'Visuospatial': _norm(clockDrawingScore, 4),
        'Attention': _norm(trailMakingScore, 5),
        'Working Memory': _norm(digitSpanScore, 5),
        'Language': _norm(categoryFluencyScore, 5),
        'Orientation': _norm(orientationScore, 6),
        'Executive': _norm(patternSequenceScore, 4),
      };

  static double? _norm(int? value, int max) =>
      value == null ? null : (max == 0 ? 0 : value / max);

  /// Lowest-scoring domain (excludes skipped tests).
  String? get weakestDomain {
    String? key;
    double lowest = double.infinity;
    domainScores.forEach((k, v) {
      if (v != null && v < lowest) {
        lowest = v;
        key = k;
      }
    });
    return key;
  }

  /// Highest-scoring domain.
  String? get strongestDomain {
    String? key;
    double highest = -1;
    domainScores.forEach((k, v) {
      if (v != null && v > highest) {
        highest = v;
        key = k;
      }
    });
    return key;
  }

  // ── Serialization ─────────────────────────────────────────────

  factory CognitiveAssessment.fromFirestore(
      String id, Map<String, dynamic> data) {
    Map<String, bool>? oa;
    final raw = data['orientationAnswers'];
    if (raw is Map) {
      oa = raw.map((k, v) => MapEntry(k.toString(), v == true));
    }
    return CognitiveAssessment(
      id: id,
      elderId: data['elderId'] as String? ?? '',
      assessedBy: data['assessedBy'] as String? ?? '',
      assessedByName: data['assessedByName'] as String? ?? '',
      monthString: data['monthString'] as String? ?? '',
      wordRecallScore: data['wordRecallScore'] as int?,
      clockDrawingScore: data['clockDrawingScore'] as int?,
      trailMakingScore: data['trailMakingScore'] as int?,
      digitSpanScore: data['digitSpanScore'] as int?,
      categoryFluencyScore: data['categoryFluencyScore'] as int?,
      orientationScore: data['orientationScore'] as int?,
      patternSequenceScore: data['patternSequenceScore'] as int?,
      wordsShown: (data['wordsShown'] as List?)?.cast<String>(),
      wordsRecalled: (data['wordsRecalled'] as List?)?.cast<String>(),
      trailMakingTimeSeconds: data['trailMakingTimeSeconds'] as int?,
      trailMakingErrors: data['trailMakingErrors'] as int?,
      digitSpanMaxForward: data['digitSpanMaxForward'] as int?,
      digitSpanMaxBackward: data['digitSpanMaxBackward'] as int?,
      categoryFluencyCount: data['categoryFluencyCount'] as int?,
      categoryFluencyCategory: data['categoryFluencyCategory'] as String?,
      orientationAnswers: oa,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'elderId': elderId,
      'assessedBy': assessedBy,
      'assessedByName': assessedByName,
      'monthString': monthString,
      if (wordRecallScore != null) 'wordRecallScore': wordRecallScore,
      if (clockDrawingScore != null) 'clockDrawingScore': clockDrawingScore,
      if (trailMakingScore != null) 'trailMakingScore': trailMakingScore,
      if (digitSpanScore != null) 'digitSpanScore': digitSpanScore,
      if (categoryFluencyScore != null)
        'categoryFluencyScore': categoryFluencyScore,
      if (orientationScore != null) 'orientationScore': orientationScore,
      if (patternSequenceScore != null)
        'patternSequenceScore': patternSequenceScore,
      if (wordsShown != null) 'wordsShown': wordsShown,
      if (wordsRecalled != null) 'wordsRecalled': wordsRecalled,
      if (trailMakingTimeSeconds != null)
        'trailMakingTimeSeconds': trailMakingTimeSeconds,
      if (trailMakingErrors != null) 'trailMakingErrors': trailMakingErrors,
      if (digitSpanMaxForward != null)
        'digitSpanMaxForward': digitSpanMaxForward,
      if (digitSpanMaxBackward != null)
        'digitSpanMaxBackward': digitSpanMaxBackward,
      if (categoryFluencyCount != null)
        'categoryFluencyCount': categoryFluencyCount,
      if (categoryFluencyCategory != null)
        'categoryFluencyCategory': categoryFluencyCategory,
      if (orientationAnswers != null)
        'orientationAnswers': orientationAnswers,
      if (notes != null) 'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
