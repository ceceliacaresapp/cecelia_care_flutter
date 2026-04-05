// lib/models/behavioral_entry.dart
//
// Data model for behavioral event observations (agitation, confusion,
// aggression, etc.). Stored in elderProfiles/{elderId}/behavioralEntries.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BehavioralEntry {
  final String? id;
  final String elderId;
  final String behaviorType;
  final int severity; // 1–5
  final int? durationMinutes;
  final String? trigger;
  final String? deEscalationTechnique;
  final String? outcome;
  final String timeOfDay; // HH:mm
  final String? notes;
  final String loggedBy;
  final String loggedByName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const BehavioralEntry({
    this.id,
    required this.elderId,
    required this.behaviorType,
    required this.severity,
    this.durationMinutes,
    this.trigger,
    this.deEscalationTechnique,
    this.outcome,
    required this.timeOfDay,
    this.notes,
    required this.loggedBy,
    required this.loggedByName,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed getters ────────────────────────────────────────────

  String get severityLabel {
    switch (severity) {
      case 1: return 'Minimal';
      case 2: return 'Mild';
      case 3: return 'Moderate';
      case 4: return 'Severe';
      case 5: return 'Crisis';
      default: return '$severity';
    }
  }

  Color get severityColor {
    switch (severity) {
      case 1: return const Color(0xFF43A047);
      case 2: return const Color(0xFF7CB342);
      case 3: return const Color(0xFFF57C00);
      case 4: return const Color(0xFFE64A19);
      case 5: return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  String get durationLabel {
    if (durationMinutes == null) return '';
    if (durationMinutes! < 5) return '<5 min';
    if (durationMinutes! <= 15) return '5\u201315 min';
    if (durationMinutes! <= 30) return '15\u201330 min';
    if (durationMinutes! <= 60) return '30\u201360 min';
    return '>1 hour';
  }

  // ── Static constants ────────────────────────────────────────────

  static const List<String> kBehaviorTypes = [
    'Agitation',
    'Verbal aggression',
    'Physical aggression',
    'Confusion / Disorientation',
    'Repetitive questioning',
    'Repetitive movements',
    'Shadowing / Following',
    'Sundowning episode',
    'Wandering attempt',
    'Refusal of care',
    'Sleep disturbance',
    'Delusions / Hallucinations',
    'Inappropriate undressing',
    'Hoarding / Rummaging',
    'Other',
  ];

  static const List<String> kCommonTriggers = [
    'Change in routine',
    'Unfamiliar person / environment',
    'Overstimulation (noise, crowds)',
    'Pain or discomfort',
    'Hunger / Thirst',
    'Need for bathroom',
    'Fatigue / Overtired',
    'Medication change',
    'Time of day (sundowning)',
    'Boredom / Understimulation',
    'Caregiver stress / Tone of voice',
    'Unknown / No clear trigger',
  ];

  static const List<String> kTechniques = [
    'Redirect attention',
    'Calm voice / Reassurance',
    'Offered food or drink',
    'Changed environment (moved rooms)',
    'Physical comfort (hand-holding, blanket)',
    'Played familiar music',
    'Went for a walk together',
    'Reduced stimulation (TV off, lights dim)',
    'Validated feelings',
    'Gave space / Stepped away',
    'PRN medication administered',
    'Called for backup caregiver',
    'Other',
  ];

  static const List<String> kOutcomes = [
    'Resolved quickly (<5 min)',
    'Gradually calmed (5\u201315 min)',
    'Took extended time (>15 min)',
    'Required medication',
    'Required additional caregiver',
    'Did not fully resolve',
    'Escalated to crisis',
  ];

  static const List<int> kDurationOptions = [3, 10, 22, 45, 75];
  static const List<String> kDurationLabels = [
    '<5 min', '5\u201315 min', '15\u201330 min', '30\u201360 min', '>1 hour',
  ];

  // ── Serialization ───────────────────────────────────────────────

  factory BehavioralEntry.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return BehavioralEntry(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      behaviorType: data['behaviorType'] as String? ?? '',
      severity: data['severity'] as int? ?? 1,
      durationMinutes: data['durationMinutes'] as int?,
      trigger: data['trigger'] as String?,
      deEscalationTechnique: data['deEscalationTechnique'] as String?,
      outcome: data['outcome'] as String?,
      timeOfDay: data['timeOfDay'] as String? ?? '',
      notes: data['notes'] as String?,
      loggedBy: data['loggedBy'] as String? ?? '',
      loggedByName: data['loggedByName'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'elderId': elderId,
        'behaviorType': behaviorType,
        'severity': severity,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (trigger != null && trigger!.isNotEmpty) 'trigger': trigger,
        if (deEscalationTechnique != null && deEscalationTechnique!.isNotEmpty)
          'deEscalationTechnique': deEscalationTechnique,
        if (outcome != null && outcome!.isNotEmpty) 'outcome': outcome,
        'timeOfDay': timeOfDay,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'loggedBy': loggedBy,
        'loggedByName': loggedByName,
      };
}
