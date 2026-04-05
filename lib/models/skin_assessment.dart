// lib/models/skin_assessment.dart
//
// Braden-inspired skin integrity assessment. Tracks pressure points at risk,
// wound stages per site, and simplified Braden sub-scores.
// Stored in elderProfiles/{elderId}/skinAssessments.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SkinAssessment {
  final String? id;
  final String elderId;
  final String assessedBy;
  final String assessedByName;
  final String dateString;

  /// immobile, veryLimited, slightlyLimited, noImpairment
  final String mobilityLevel;

  /// Pressure points at risk: { 'sacrum': true, 'heelLeft': false, ... }
  final Map<String, bool> atRiskSites;

  /// Wound stage per at-risk site: { 'sacrum': 'stage1', 'heelLeft': 'intact' }
  final Map<String, String> siteConditions;

  // Braden-inspired sub-scores (simplified).
  final int sensoryPerception; // 1-4
  final int moisture;          // 1-4
  final int nutrition;         // 1-4
  final int frictionShear;     // 1-3

  final String? notes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const SkinAssessment({
    this.id,
    required this.elderId,
    required this.assessedBy,
    required this.assessedByName,
    required this.dateString,
    required this.mobilityLevel,
    this.atRiskSites = const {},
    this.siteConditions = const {},
    this.sensoryPerception = 4,
    this.moisture = 4,
    this.nutrition = 4,
    this.frictionShear = 3,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed getters ────────────────────────────────────────────

  int get bradenScore =>
      sensoryPerception + moisture + nutrition + frictionShear +
      _mobilityScore;

  int get _mobilityScore {
    switch (mobilityLevel) {
      case 'immobile': return 1;
      case 'veryLimited': return 2;
      case 'slightlyLimited': return 3;
      case 'noImpairment': return 4;
      default: return 4;
    }
  }

  String get riskLevel {
    final s = bradenScore;
    if (s <= 9) return 'Very High';
    if (s <= 12) return 'High';
    if (s <= 14) return 'Moderate';
    return 'Low';
  }

  Color get riskColor {
    final s = bradenScore;
    if (s <= 9) return const Color(0xFFE53935);
    if (s <= 12) return const Color(0xFFE64A19);
    if (s <= 14) return const Color(0xFFF57C00);
    return const Color(0xFF43A047);
  }

  int get atRiskSiteCount =>
      atRiskSites.values.where((v) => v).length;

  int get woundedSiteCount =>
      siteConditions.values
          .where((s) => s != 'intact' && s != 'notAssessed')
          .length;

  String get riskSummary =>
      'Braden $bradenScore \u00B7 $atRiskSiteCount site${atRiskSiteCount == 1 ? '' : 's'} at risk'
      '${woundedSiteCount > 0 ? ' \u00B7 $woundedSiteCount with breakdown' : ''}';

  // ── Static constants ────────────────────────────────────────────

  static const Map<String, String> kPressureSiteLabels = {
    'sacrum': 'Sacrum / Coccyx',
    'heelLeft': 'Left Heel',
    'heelRight': 'Right Heel',
    'ischialLeft': 'Left Ischial Tuberosity',
    'ischialRight': 'Right Ischial Tuberosity',
    'trochanterLeft': 'Left Trochanter (Hip)',
    'trochanterRight': 'Right Trochanter (Hip)',
    'scapulae': 'Scapulae (Shoulder Blades)',
    'occiput': 'Occiput (Back of Head)',
  };

  static const Map<String, String> kWoundStageLabels = {
    'intact': 'Intact',
    'stage1': 'Stage 1 — Non-blanchable redness',
    'stage2': 'Stage 2 — Partial thickness loss',
    'stage3': 'Stage 3 — Full thickness loss',
    'stage4': 'Stage 4 — Deep tissue injury',
    'unstageable': 'Unstageable',
  };

  static const Map<String, Color> kStageColors = {
    'intact': Color(0xFF43A047),
    'stage1': Color(0xFFF57C00),
    'stage2': Color(0xFFE64A19),
    'stage3': Color(0xFFE53935),
    'stage4': Color(0xFFB71C1C),
    'unstageable': Color(0xFF616161),
  };

  static const Map<String, String> kMobilityLabels = {
    'immobile': 'Immobile',
    'veryLimited': 'Very limited',
    'slightlyLimited': 'Slightly limited',
    'noImpairment': 'No impairment',
  };

  static const Map<int, String> kSensoryLabels = {
    1: 'Completely limited',
    2: 'Very limited',
    3: 'Slightly limited',
    4: 'No impairment',
  };

  static const Map<int, String> kMoistureLabels = {
    1: 'Constantly moist',
    2: 'Very moist',
    3: 'Occasionally moist',
    4: 'Rarely moist',
  };

  static const Map<int, String> kNutritionLabels = {
    1: 'Very poor',
    2: 'Probably inadequate',
    3: 'Adequate',
    4: 'Excellent',
  };

  static const Map<int, String> kFrictionLabels = {
    1: 'Problem',
    2: 'Potential problem',
    3: 'No apparent problem',
  };

  // ── Serialization ───────────────────────────────────────────────

  factory SkinAssessment.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return SkinAssessment(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      assessedBy: data['assessedBy'] as String? ?? '',
      assessedByName: data['assessedByName'] as String? ?? '',
      dateString: data['dateString'] as String? ?? '',
      mobilityLevel: data['mobilityLevel'] as String? ?? 'noImpairment',
      atRiskSites: Map<String, bool>.from(
          (data['atRiskSites'] as Map<String, dynamic>?) ?? {}),
      siteConditions: Map<String, String>.from(
          (data['siteConditions'] as Map<String, dynamic>?) ?? {}),
      sensoryPerception: data['sensoryPerception'] as int? ?? 4,
      moisture: data['moisture'] as int? ?? 4,
      nutrition: data['nutrition'] as int? ?? 4,
      frictionShear: data['frictionShear'] as int? ?? 3,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'elderId': elderId,
        'assessedBy': assessedBy,
        'assessedByName': assessedByName,
        'dateString': dateString,
        'mobilityLevel': mobilityLevel,
        'atRiskSites': atRiskSites,
        'siteConditions': siteConditions,
        'sensoryPerception': sensoryPerception,
        'moisture': moisture,
        'nutrition': nutrition,
        'frictionShear': frictionShear,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
