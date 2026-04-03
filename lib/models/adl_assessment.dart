// lib/models/adl_assessment.dart
//
// Data model for a single Katz ADL Index assessment. One doc per elder per
// week, stored in elderProfiles/{elderId}/adlAssessments.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdlAssessment {
  final String? id;
  final String elderId;
  final String assessedBy;
  final String assessedByName;
  final String weekString; // '2026-W14'

  // 6 ADL dimensions, each 0–2.
  final int bathing;
  final int dressing;
  final int eating;
  final int toileting;
  final int transferring;
  final int continence;

  final String? notes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const AdlAssessment({
    this.id,
    required this.elderId,
    required this.assessedBy,
    required this.assessedByName,
    required this.weekString,
    required this.bathing,
    required this.dressing,
    required this.eating,
    required this.toileting,
    required this.transferring,
    required this.continence,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed getters ────────────────────────────────────────────

  int get totalScore =>
      bathing + dressing + eating + toileting + transferring + continence;

  double get scorePercent => totalScore / 12;

  String get scoreLabel {
    if (totalScore <= 2) return 'Severe Dependence';
    if (totalScore <= 6) return 'Moderate Dependence';
    if (totalScore <= 9) return 'Mild Dependence';
    return 'Independent';
  }

  Color get scoreColor {
    if (totalScore <= 2) return const Color(0xFFE53935);
    if (totalScore <= 6) return const Color(0xFFF57C00);
    if (totalScore <= 9) return const Color(0xFF1565C0);
    return const Color(0xFF43A047);
  }

  Map<String, int> get dimensionMap => {
        'Bathing': bathing,
        'Dressing': dressing,
        'Eating': eating,
        'Toileting': toileting,
        'Transferring': transferring,
        'Continence': continence,
      };

  // ── Static constants ────────────────────────────────────────────

  static const List<String> kDimensions = [
    'Bathing', 'Dressing', 'Eating', 'Toileting', 'Transferring', 'Continence',
  ];

  static const Map<int, String> kScoreLabels = {
    0: 'Dependent',
    1: 'Needs help',
    2: 'Independent',
  };

  static const Map<String, String> kDimensionDescriptions = {
    'Bathing': 'Can bathe independently, or needs help with one body part',
    'Dressing': 'Gets clothes from closet and dresses without help',
    'Eating': 'Feeds self without assistance',
    'Toileting': 'Goes to toilet, cleans self, arranges clothes without help',
    'Transferring': 'Moves in and out of bed and chair without assistance',
    'Continence': 'Has complete control of bladder and bowel',
  };

  static const List<Color> kScoreColors = [
    Color(0xFFE53935), // 0 — dependent
    Color(0xFFF57C00), // 1 — needs help
    Color(0xFF43A047), // 2 — independent
  ];

  // ── Serialization ───────────────────────────────────────────────

  factory AdlAssessment.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return AdlAssessment(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      assessedBy: data['assessedBy'] as String? ?? '',
      assessedByName: data['assessedByName'] as String? ?? '',
      weekString: data['weekString'] as String? ?? '',
      bathing: data['bathing'] as int? ?? 0,
      dressing: data['dressing'] as int? ?? 0,
      eating: data['eating'] as int? ?? 0,
      toileting: data['toileting'] as int? ?? 0,
      transferring: data['transferring'] as int? ?? 0,
      continence: data['continence'] as int? ?? 0,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'elderId': elderId,
        'assessedBy': assessedBy,
        'assessedByName': assessedByName,
        'weekString': weekString,
        'bathing': bathing,
        'dressing': dressing,
        'eating': eating,
        'toileting': toileting,
        'transferring': transferring,
        'continence': continence,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
