// lib/models/zarit_assessment.dart
//
// Zarit Burden Interview — Short Form (ZBI-12).
//
// 12 items, each scored 0–4. Total range 0–48. This is the validated
// clinical instrument recognized by social workers and insurance
// companies when advocating for respite funding. Monthly cadence is
// the accepted follow-up interval (Bédard et al., 2001).
//
// Interpretation bands are widely used in practice but remain under
// active research — use them as guidance, not diagnosis.
//
// Storage: per-user private docs at `zaritAssessments/{userId}_{iso8601}`.
// Each assessment optionally carries an `elderId` so a caregiver with
// multiple care recipients can track burden context separately.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Response option for any Zarit item. Labels match the validated
/// instrument — do not localize these to other wordings without
/// clinical review.
enum ZaritResponse {
  never, // 0
  rarely, // 1
  sometimes, // 2
  quiteFrequently, // 3
  nearlyAlways, // 4
}

extension ZaritResponseX on ZaritResponse {
  int get score => index;
  String get label {
    switch (this) {
      case ZaritResponse.never:
        return 'Never';
      case ZaritResponse.rarely:
        return 'Rarely';
      case ZaritResponse.sometimes:
        return 'Sometimes';
      case ZaritResponse.quiteFrequently:
        return 'Quite frequently';
      case ZaritResponse.nearlyAlways:
        return 'Nearly always';
    }
  }

  static ZaritResponse fromScore(int score) {
    final s = score.clamp(0, 4);
    return ZaritResponse.values[s];
  }
}

/// A single question in the ZBI-12. Text matches Bédard et al. (2001).
class ZaritItem {
  final int number; // 1..12 (display order)
  final String prompt;
  final String domain; // personal strain / role strain
  const ZaritItem({
    required this.number,
    required this.prompt,
    required this.domain,
  });
}

/// The 12 items of the ZBI-12 short form. Order and wording follow the
/// published instrument. Domains (personal strain vs role strain) let
/// the trend view break down WHERE the burden is concentrated.
const List<ZaritItem> kZaritItems = [
  ZaritItem(
    number: 1,
    prompt:
        'Do you feel that because of the time you spend with your relative, '
        'you don\'t have enough time for yourself?',
    domain: 'Role strain',
  ),
  ZaritItem(
    number: 2,
    prompt:
        'Do you feel stressed between caring for your relative and trying '
        'to meet other responsibilities (work, family)?',
    domain: 'Role strain',
  ),
  ZaritItem(
    number: 3,
    prompt: 'Do you feel angry when you are around your relative?',
    domain: 'Personal strain',
  ),
  ZaritItem(
    number: 4,
    prompt:
        'Do you feel that your relative currently affects your relationships '
        'with other family members or friends in a negative way?',
    domain: 'Role strain',
  ),
  ZaritItem(
    number: 5,
    prompt: 'Do you feel strained when you are around your relative?',
    domain: 'Personal strain',
  ),
  ZaritItem(
    number: 6,
    prompt:
        'Do you feel your health has suffered because of your involvement '
        'with your relative?',
    domain: 'Personal strain',
  ),
  ZaritItem(
    number: 7,
    prompt:
        'Do you feel that you don\'t have as much privacy as you would like '
        'because of your relative?',
    domain: 'Role strain',
  ),
  ZaritItem(
    number: 8,
    prompt:
        'Do you feel that your social life has suffered because you are '
        'caring for your relative?',
    domain: 'Role strain',
  ),
  ZaritItem(
    number: 9,
    prompt:
        'Do you feel that you have lost control of your life since your '
        'relative\'s illness?',
    domain: 'Personal strain',
  ),
  ZaritItem(
    number: 10,
    prompt: 'Do you feel uncertain about what to do about your relative?',
    domain: 'Personal strain',
  ),
  ZaritItem(
    number: 11,
    prompt: 'Do you feel you should be doing more for your relative?',
    domain: 'Personal strain',
  ),
  ZaritItem(
    number: 12,
    prompt:
        'Do you feel you could do a better job in caring for your relative?',
    domain: 'Personal strain',
  ),
];

/// The interpretive burden level for a ZBI-12 total.
enum ZaritBurdenLevel { little, mild, moderate, severe }

extension ZaritBurdenLevelX on ZaritBurdenLevel {
  String get label {
    switch (this) {
      case ZaritBurdenLevel.little:
        return 'Little or no burden';
      case ZaritBurdenLevel.mild:
        return 'Mild to moderate burden';
      case ZaritBurdenLevel.moderate:
        return 'Moderate to severe burden';
      case ZaritBurdenLevel.severe:
        return 'Severe burden';
    }
  }

  /// Short actionable guidance shown in UI + PDF. Framed as "what this
  /// usually means for social workers / respite advocates" to match the
  /// real-world use case: advocacy, not diagnosis.
  String get guidance {
    switch (this) {
      case ZaritBurdenLevel.little:
        return 'Your current load looks sustainable. Keep up the self-care '
            'routines that are working.';
      case ZaritBurdenLevel.mild:
        return 'Small stressors are accumulating. Now is a good time to '
            'add respite hours or protect more me-time before things tip.';
      case ZaritBurdenLevel.moderate:
        return 'A score in this range is what social workers look for '
            'when advocating for respite services, in-home aides, or '
            'additional support. Consider scheduling a conversation.';
      case ZaritBurdenLevel.severe:
        return 'Caregivers at this level are at high risk of burnout and '
            'health decline. Please reach out — to a social worker, '
            'your doctor, or a support line — this week.';
    }
  }

  Color get color {
    switch (this) {
      case ZaritBurdenLevel.little:
        return AppTheme.statusGreen;
      case ZaritBurdenLevel.mild:
        return const Color(0xFFF9A825); // amber
      case ZaritBurdenLevel.moderate:
        return AppTheme.statusAmber;
      case ZaritBurdenLevel.severe:
        return AppTheme.dangerColor;
    }
  }

  static ZaritBurdenLevel fromTotal(int total) {
    if (total <= 10) return ZaritBurdenLevel.little;
    if (total <= 20) return ZaritBurdenLevel.mild;
    if (total <= 40) return ZaritBurdenLevel.moderate;
    return ZaritBurdenLevel.severe;
  }
}

/// A completed ZBI-12 assessment.
class ZaritAssessment {
  final String? id;
  final String userId;

  /// Optional — the elder this assessment was taken about. Caregivers
  /// with multiple recipients get per-elder trends.
  final String? elderId;

  /// Scores for items 1..12, indexed 0..11. Each 0..4.
  final List<int> itemScores;

  /// Optional free-text reflection attached to the assessment.
  final String? note;

  final Timestamp? completedAt;

  const ZaritAssessment({
    this.id,
    required this.userId,
    this.elderId,
    required this.itemScores,
    this.note,
    this.completedAt,
  });

  factory ZaritAssessment.empty(String userId, {String? elderId}) =>
      ZaritAssessment(
        userId: userId,
        elderId: elderId,
        itemScores: List<int>.filled(kZaritItems.length, 0),
      );

  // ---------------------------------------------------------------------------
  // Scoring
  // ---------------------------------------------------------------------------

  int get total => itemScores.fold<int>(0, (acc, s) => acc + s.clamp(0, 4));

  double get percent => (total / 48 * 100).clamp(0, 100);

  ZaritBurdenLevel get level => ZaritBurdenLevelX.fromTotal(total);

  /// Sub-scale score for "personal strain" items.
  int get personalStrain {
    var s = 0;
    for (int i = 0; i < kZaritItems.length; i++) {
      if (kZaritItems[i].domain == 'Personal strain') {
        s += itemScores[i].clamp(0, 4);
      }
    }
    return s;
  }

  /// Sub-scale score for "role strain" items.
  int get roleStrain {
    var s = 0;
    for (int i = 0; i < kZaritItems.length; i++) {
      if (kZaritItems[i].domain == 'Role strain') {
        s += itemScores[i].clamp(0, 4);
      }
    }
    return s;
  }

  /// True when every item has been answered (including 0=never, which
  /// is still a valid answer). Used to validate save eligibility.
  bool get isComplete =>
      itemScores.length == kZaritItems.length &&
      !itemScores.any((s) => s < 0 || s > 4);

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory ZaritAssessment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap, [
    SnapshotOptions? _,
  ]) {
    final data = snap.data();
    if (data == null) {
      throw StateError('Missing data for ZaritAssessment ${snap.id}');
    }
    final rawScores =
        (data['itemScores'] as List<dynamic>?) ?? const <dynamic>[];
    final scores = rawScores
        .map((v) => (v as num).toInt().clamp(0, 4))
        .toList();
    // Pad / truncate defensively so bad data never crashes the UI.
    while (scores.length < kZaritItems.length) {
      scores.add(0);
    }
    if (scores.length > kZaritItems.length) {
      scores.removeRange(kZaritItems.length, scores.length);
    }
    return ZaritAssessment(
      id: snap.id,
      userId: data['userId'] as String? ?? '',
      elderId: data['elderId'] as String?,
      itemScores: scores,
      note: data['note'] as String?,
      completedAt: data['completedAt'] as Timestamp?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'userId': userId,
      if (elderId != null) 'elderId': elderId,
      'itemScores': itemScores,
      'total': total,
      'level': level.name,
      if (note != null && note!.isNotEmpty) 'note': note,
      'completedAt': completedAt ?? FieldValue.serverTimestamp(),
    };
  }

  ZaritAssessment copyWith({
    String? id,
    String? userId,
    String? elderId,
    List<int>? itemScores,
    String? note,
    Timestamp? completedAt,
  }) {
    return ZaritAssessment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      elderId: elderId ?? this.elderId,
      itemScores: itemScores ?? this.itemScores,
      note: note ?? this.note,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
