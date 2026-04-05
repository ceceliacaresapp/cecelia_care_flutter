// lib/models/fall_risk_assessment.dart
//
// CDC STEADI-based fall risk assessment. 15 risk factors across 4 categories
// + 5 protective measures. Fall history factors weighted x2 since prior falls
// are the top STEADI predictor. Stored in
// elderProfiles/{elderId}/fallRiskAssessments.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FallRiskAssessment {
  final String? id;
  final String elderId;
  final String assessedBy;
  final String assessedByName;
  final String dateString; // yyyy-MM-dd

  // ── Fall History (weighted x2) ──────────────────────────────────
  final bool hasFallenPastYear;
  final bool hasFallenMultipleTimes;
  final bool hasInjuryFromFall;

  // ── Balance & Mobility ──────────────────────────────────────────
  final bool hasUnsteadyGait;
  final bool needsAssistanceWalking;
  final bool hasDifficultyRising;
  final bool hasBalanceProblems;
  final bool hasFeetOrLegProblems;

  // ── Medication Risks ────────────────────────────────────────────
  final bool takesSedatives;
  final bool takesFourPlusMeds;
  final bool hasMedsCausingDizziness;

  // ── Environmental Hazards ───────────────────────────────────────
  final bool hasLooseRugs;
  final bool hasPoorLighting;
  final bool lacksGrabBars;
  final bool hasClutteredPaths;

  // ── Protective Measures (true = in place) ───────────────────────
  final bool usesAssistiveDevice;
  final bool hasGrabBarsInstalled;
  final bool wearsProperFootwear;
  final bool doesExerciseProgram;
  final bool hasHomeAssessed;

  final String? notes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const FallRiskAssessment({
    this.id,
    required this.elderId,
    required this.assessedBy,
    required this.assessedByName,
    required this.dateString,
    this.hasFallenPastYear = false,
    this.hasFallenMultipleTimes = false,
    this.hasInjuryFromFall = false,
    this.hasUnsteadyGait = false,
    this.needsAssistanceWalking = false,
    this.hasDifficultyRising = false,
    this.hasBalanceProblems = false,
    this.hasFeetOrLegProblems = false,
    this.takesSedatives = false,
    this.takesFourPlusMeds = false,
    this.hasMedsCausingDizziness = false,
    this.hasLooseRugs = false,
    this.hasPoorLighting = false,
    this.lacksGrabBars = false,
    this.hasClutteredPaths = false,
    this.usesAssistiveDevice = false,
    this.hasGrabBarsInstalled = false,
    this.wearsProperFootwear = false,
    this.doesExerciseProgram = false,
    this.hasHomeAssessed = false,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed getters ────────────────────────────────────────────

  int get _fallHistoryScore {
    int c = 0;
    if (hasFallenPastYear) c++;
    if (hasFallenMultipleTimes) c++;
    if (hasInjuryFromFall) c++;
    return c * 2; // Weighted x2
  }

  int get _balanceScore {
    int c = 0;
    if (hasUnsteadyGait) c++;
    if (needsAssistanceWalking) c++;
    if (hasDifficultyRising) c++;
    if (hasBalanceProblems) c++;
    if (hasFeetOrLegProblems) c++;
    return c;
  }

  int get _medicationScore {
    int c = 0;
    if (takesSedatives) c++;
    if (takesFourPlusMeds) c++;
    if (hasMedsCausingDizziness) c++;
    return c;
  }

  int get _environmentalScore {
    int c = 0;
    if (hasLooseRugs) c++;
    if (hasPoorLighting) c++;
    if (lacksGrabBars) c++;
    if (hasClutteredPaths) c++;
    return c;
  }

  int get protectiveCount {
    int c = 0;
    if (usesAssistiveDevice) c++;
    if (hasGrabBarsInstalled) c++;
    if (wearsProperFootwear) c++;
    if (doesExerciseProgram) c++;
    if (hasHomeAssessed) c++;
    return c;
  }

  int get riskFactorCount =>
      _fallHistoryScore ~/ 2 + _balanceScore + _medicationScore + _environmentalScore;

  int get rawRiskScore =>
      (_fallHistoryScore + _balanceScore + _medicationScore +
              _environmentalScore - protectiveCount)
          .clamp(0, 20);

  String get riskLevel {
    final s = rawRiskScore;
    if (s <= 3) return 'Low';
    if (s <= 7) return 'Moderate';
    if (s <= 12) return 'High';
    return 'Very High';
  }

  Color get riskColor {
    final s = rawRiskScore;
    if (s <= 3) return const Color(0xFF43A047);
    if (s <= 7) return const Color(0xFFF57C00);
    if (s <= 12) return const Color(0xFFE64A19);
    return const Color(0xFFE53935);
  }

  String get riskSummary =>
      '$riskFactorCount risk factor${riskFactorCount == 1 ? '' : 's'}, '
      '$protectiveCount protection${protectiveCount == 1 ? '' : 's'} in place';

  String get steadiRecommendation {
    final s = rawRiskScore;
    if (s <= 3) return 'Low risk. Re-assess in 12 months or after any fall.';
    if (s <= 7) return 'Moderate risk. Review medications and home environment. Re-assess in 6 months.';
    if (s <= 12) return 'High risk. Schedule a fall prevention consultation. Consider physical therapy referral.';
    return 'Very high risk. Urgent fall prevention intervention needed. Consult physician immediately.';
  }

  List<String> get missingProtections {
    final missing = <String>[];
    if (!usesAssistiveDevice) missing.add('No assistive device (cane/walker)');
    if (!hasGrabBarsInstalled) missing.add('No grab bars in bathroom');
    if (!wearsProperFootwear) missing.add('Improper footwear');
    if (!doesExerciseProgram) missing.add('No exercise/balance program');
    if (!hasHomeAssessed) missing.add('Home not assessed for hazards');
    return missing;
  }

  // ── Static constants ────────────────────────────────────────────

  static const Map<String, String> kFallHistoryLabels = {
    'hasFallenPastYear': 'Fell in the past 12 months',
    'hasFallenMultipleTimes': 'Fell 2 or more times in past year',
    'hasInjuryFromFall': 'Injured in a fall (fracture, head injury)',
  };

  static const Map<String, String> kBalanceLabels = {
    'hasUnsteadyGait': 'Unsteady or shuffling walk',
    'needsAssistanceWalking': 'Needs help walking or uses furniture for support',
    'hasDifficultyRising': 'Difficulty rising from a chair',
    'hasBalanceProblems': 'Balance problems when standing or turning',
    'hasFeetOrLegProblems': 'Foot, leg, or joint pain affecting mobility',
  };

  static const Map<String, String> kMedicationLabels = {
    'takesSedatives': 'Takes sedatives, sleep aids, or anti-anxiety medication',
    'takesFourPlusMeds': 'Takes 4 or more prescription medications',
    'hasMedsCausingDizziness': 'Takes medications that cause dizziness or drowsiness',
  };

  static const Map<String, String> kEnvironmentalLabels = {
    'hasLooseRugs': 'Loose rugs or slippery floors in the home',
    'hasPoorLighting': 'Poor lighting in hallways, stairs, or bathroom',
    'lacksGrabBars': 'No grab bars near toilet or in shower/tub',
    'hasClutteredPaths': 'Cluttered walkways or stairs without handrails',
  };

  static const Map<String, String> kProtectiveLabels = {
    'usesAssistiveDevice': 'Uses cane, walker, or other assistive device',
    'hasGrabBarsInstalled': 'Grab bars installed in bathroom',
    'wearsProperFootwear': 'Wears non-skid, supportive footwear',
    'doesExerciseProgram': 'Participates in exercise or balance program',
    'hasHomeAssessed': 'Home assessed for fall hazards',
  };

  // ── Serialization ───────────────────────────────────────────────

  factory FallRiskAssessment.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return FallRiskAssessment(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      assessedBy: data['assessedBy'] as String? ?? '',
      assessedByName: data['assessedByName'] as String? ?? '',
      dateString: data['dateString'] as String? ?? '',
      hasFallenPastYear: data['hasFallenPastYear'] as bool? ?? false,
      hasFallenMultipleTimes: data['hasFallenMultipleTimes'] as bool? ?? false,
      hasInjuryFromFall: data['hasInjuryFromFall'] as bool? ?? false,
      hasUnsteadyGait: data['hasUnsteadyGait'] as bool? ?? false,
      needsAssistanceWalking: data['needsAssistanceWalking'] as bool? ?? false,
      hasDifficultyRising: data['hasDifficultyRising'] as bool? ?? false,
      hasBalanceProblems: data['hasBalanceProblems'] as bool? ?? false,
      hasFeetOrLegProblems: data['hasFeetOrLegProblems'] as bool? ?? false,
      takesSedatives: data['takesSedatives'] as bool? ?? false,
      takesFourPlusMeds: data['takesFourPlusMeds'] as bool? ?? false,
      hasMedsCausingDizziness: data['hasMedsCausingDizziness'] as bool? ?? false,
      hasLooseRugs: data['hasLooseRugs'] as bool? ?? false,
      hasPoorLighting: data['hasPoorLighting'] as bool? ?? false,
      lacksGrabBars: data['lacksGrabBars'] as bool? ?? false,
      hasClutteredPaths: data['hasClutteredPaths'] as bool? ?? false,
      usesAssistiveDevice: data['usesAssistiveDevice'] as bool? ?? false,
      hasGrabBarsInstalled: data['hasGrabBarsInstalled'] as bool? ?? false,
      wearsProperFootwear: data['wearsProperFootwear'] as bool? ?? false,
      doesExerciseProgram: data['doesExerciseProgram'] as bool? ?? false,
      hasHomeAssessed: data['hasHomeAssessed'] as bool? ?? false,
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
        'hasFallenPastYear': hasFallenPastYear,
        'hasFallenMultipleTimes': hasFallenMultipleTimes,
        'hasInjuryFromFall': hasInjuryFromFall,
        'hasUnsteadyGait': hasUnsteadyGait,
        'needsAssistanceWalking': needsAssistanceWalking,
        'hasDifficultyRising': hasDifficultyRising,
        'hasBalanceProblems': hasBalanceProblems,
        'hasFeetOrLegProblems': hasFeetOrLegProblems,
        'takesSedatives': takesSedatives,
        'takesFourPlusMeds': takesFourPlusMeds,
        'hasMedsCausingDizziness': hasMedsCausingDizziness,
        'hasLooseRugs': hasLooseRugs,
        'hasPoorLighting': hasPoorLighting,
        'lacksGrabBars': lacksGrabBars,
        'hasClutteredPaths': hasClutteredPaths,
        'usesAssistiveDevice': usesAssistiveDevice,
        'hasGrabBarsInstalled': hasGrabBarsInstalled,
        'wearsProperFootwear': wearsProperFootwear,
        'doesExerciseProgram': doesExerciseProgram,
        'hasHomeAssessed': hasHomeAssessed,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
