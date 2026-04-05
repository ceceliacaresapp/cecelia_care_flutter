// lib/models/wandering_assessment.dart
//
// Structured wandering risk assessment. Generates a risk score from
// 8 risk factors and 5 safeguards. Stored in
// elderProfiles/{elderId}/wanderingAssessments.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class WanderingAssessment {
  final String? id;
  final String elderId;
  final String assessedBy;
  final String assessedByName;
  final String dateString; // yyyy-MM-dd

  // 8 risk factors (true = risk present)
  final bool hasWanderedBefore;
  final bool isNewToEnvironment;
  final bool hasSundowningPattern;
  final bool hasExitSeekingBehavior;
  final bool hasImpairedJudgment;
  final bool hasMobilityToWander;
  final bool isOnNewMedication;
  final bool hasRecentDecline;

  // 5 safeguards (true = safeguard in place)
  final bool hasIdBracelet;
  final bool hasSecuredExits;
  final bool hasNeighborAlert;
  final bool hasSafeReturnEnrolled;
  final bool hasRecentPhoto;

  final String? knownTriggers;
  final String? peakRiskTimes;
  final String? notes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const WanderingAssessment({
    this.id,
    required this.elderId,
    required this.assessedBy,
    required this.assessedByName,
    required this.dateString,
    this.hasWanderedBefore = false,
    this.isNewToEnvironment = false,
    this.hasSundowningPattern = false,
    this.hasExitSeekingBehavior = false,
    this.hasImpairedJudgment = false,
    this.hasMobilityToWander = false,
    this.isOnNewMedication = false,
    this.hasRecentDecline = false,
    this.hasIdBracelet = false,
    this.hasSecuredExits = false,
    this.hasNeighborAlert = false,
    this.hasSafeReturnEnrolled = false,
    this.hasRecentPhoto = false,
    this.knownTriggers,
    this.peakRiskTimes,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed getters ────────────────────────────────────────────

  int get riskFactorCount {
    int c = 0;
    if (hasWanderedBefore) c++;
    if (isNewToEnvironment) c++;
    if (hasSundowningPattern) c++;
    if (hasExitSeekingBehavior) c++;
    if (hasImpairedJudgment) c++;
    if (hasMobilityToWander) c++;
    if (isOnNewMedication) c++;
    if (hasRecentDecline) c++;
    return c;
  }

  int get safeguardCount {
    int c = 0;
    if (hasIdBracelet) c++;
    if (hasSecuredExits) c++;
    if (hasNeighborAlert) c++;
    if (hasSafeReturnEnrolled) c++;
    if (hasRecentPhoto) c++;
    return c;
  }

  int get rawRiskScore =>
      (riskFactorCount * 2 - safeguardCount).clamp(0, 10);

  String get riskLevel {
    final s = rawRiskScore;
    if (s <= 2) return 'Low';
    if (s <= 5) return 'Moderate';
    if (s <= 8) return 'High';
    return 'Critical';
  }

  Color get riskColor {
    final s = rawRiskScore;
    if (s <= 2) return const Color(0xFF43A047);
    if (s <= 5) return const Color(0xFFF57C00);
    if (s <= 8) return const Color(0xFFE64A19);
    return const Color(0xFFE53935);
  }

  String get riskSummary =>
      '$riskFactorCount risk factor${riskFactorCount == 1 ? '' : 's'}, '
      '$safeguardCount safeguard${safeguardCount == 1 ? '' : 's'} in place';

  List<String> get missingSafeguards {
    final missing = <String>[];
    if (!hasIdBracelet) missing.add('No ID bracelet or GPS tracker');
    if (!hasSecuredExits) missing.add('Exits not secured');
    if (!hasNeighborAlert) missing.add('Neighbors not alerted');
    if (!hasSafeReturnEnrolled) missing.add('Not enrolled in Safe Return');
    if (!hasRecentPhoto) missing.add('No recent photo on file');
    return missing;
  }

  // ── Static constants ────────────────────────────────────────────

  static const Map<String, String> kRiskFactorLabels = {
    'hasWanderedBefore': 'History of wandering or elopement',
    'isNewToEnvironment': 'New or unfamiliar living environment',
    'hasSundowningPattern': 'Sundowning-related wandering pattern',
    'hasExitSeekingBehavior': 'Exit-seeking behavior (tries doors, packs bags)',
    'hasImpairedJudgment': 'Cannot recognize unsafe situations',
    'hasMobilityToWander': 'Physically able to walk independently',
    'isOnNewMedication': 'Recent medication change causing confusion',
    'hasRecentDecline': 'Noticeable cognitive decline in past month',
  };

  static const Map<String, String> kSafeguardLabels = {
    'hasIdBracelet': 'Wears ID bracelet or GPS tracker',
    'hasSecuredExits': 'Door alarms, locks, or barriers installed',
    'hasNeighborAlert': 'Neighbors alerted and watching',
    'hasSafeReturnEnrolled': 'Enrolled in Safe Return / MedicAlert',
    'hasRecentPhoto': 'Recent photo available for search',
  };

  // ── Serialization ───────────────────────────────────────────────

  factory WanderingAssessment.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return WanderingAssessment(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      assessedBy: data['assessedBy'] as String? ?? '',
      assessedByName: data['assessedByName'] as String? ?? '',
      dateString: data['dateString'] as String? ?? '',
      hasWanderedBefore: data['hasWanderedBefore'] as bool? ?? false,
      isNewToEnvironment: data['isNewToEnvironment'] as bool? ?? false,
      hasSundowningPattern: data['hasSundowningPattern'] as bool? ?? false,
      hasExitSeekingBehavior: data['hasExitSeekingBehavior'] as bool? ?? false,
      hasImpairedJudgment: data['hasImpairedJudgment'] as bool? ?? false,
      hasMobilityToWander: data['hasMobilityToWander'] as bool? ?? false,
      isOnNewMedication: data['isOnNewMedication'] as bool? ?? false,
      hasRecentDecline: data['hasRecentDecline'] as bool? ?? false,
      hasIdBracelet: data['hasIdBracelet'] as bool? ?? false,
      hasSecuredExits: data['hasSecuredExits'] as bool? ?? false,
      hasNeighborAlert: data['hasNeighborAlert'] as bool? ?? false,
      hasSafeReturnEnrolled: data['hasSafeReturnEnrolled'] as bool? ?? false,
      hasRecentPhoto: data['hasRecentPhoto'] as bool? ?? false,
      knownTriggers: data['knownTriggers'] as String?,
      peakRiskTimes: data['peakRiskTimes'] as String?,
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
        'hasWanderedBefore': hasWanderedBefore,
        'isNewToEnvironment': isNewToEnvironment,
        'hasSundowningPattern': hasSundowningPattern,
        'hasExitSeekingBehavior': hasExitSeekingBehavior,
        'hasImpairedJudgment': hasImpairedJudgment,
        'hasMobilityToWander': hasMobilityToWander,
        'isOnNewMedication': isOnNewMedication,
        'hasRecentDecline': hasRecentDecline,
        'hasIdBracelet': hasIdBracelet,
        'hasSecuredExits': hasSecuredExits,
        'hasNeighborAlert': hasNeighborAlert,
        'hasSafeReturnEnrolled': hasSafeReturnEnrolled,
        'hasRecentPhoto': hasRecentPhoto,
        if (knownTriggers != null && knownTriggers!.isNotEmpty)
          'knownTriggers': knownTriggers,
        if (peakRiskTimes != null && peakRiskTimes!.isNotEmpty)
          'peakRiskTimes': peakRiskTimes,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
