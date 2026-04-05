// lib/models/wound_entry.dart
//
// Data model for clinical wound/condition photo documentation.
// Stored in elderProfiles/{elderId}/woundEntries.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BodyRegion {
  final String id;
  final String label;
  final String icon;
  final String group;

  const BodyRegion({
    required this.id,
    required this.label,
    required this.icon,
    required this.group,
  });

  static BodyRegion fromId(String id) =>
      WoundEntry.kBodyRegions.firstWhere(
        (r) => r.id == id,
        orElse: () => WoundEntry.kBodyRegions.last,
      );
}

class WoundEntry {
  final String? id;
  final String photoUrl;
  final String storagePath;
  final String title;
  final String bodyRegion;
  final String woundType;
  final String severity; // 'mild', 'moderate', 'severe'
  final String? notes;
  final String? linkedEntryId;
  final String elderId;
  final String uploadedBy;
  final String uploadedByName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const WoundEntry({
    this.id,
    required this.photoUrl,
    required this.storagePath,
    required this.title,
    required this.bodyRegion,
    required this.woundType,
    required this.severity,
    this.notes,
    this.linkedEntryId,
    required this.elderId,
    required this.uploadedBy,
    required this.uploadedByName,
    this.createdAt,
    this.updatedAt,
  });

  // ── Computed getters ────────────────────────────────────────────

  String get severityLabel {
    switch (severity) {
      case 'mild': return 'Mild';
      case 'moderate': return 'Moderate';
      case 'severe': return 'Severe';
      default: return severity;
    }
  }

  Color get severityColor {
    switch (severity) {
      case 'mild': return const Color(0xFF43A047);
      case 'moderate': return const Color(0xFFF57C00);
      case 'severe': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  BodyRegion get region => BodyRegion.fromId(bodyRegion);

  // ── Static constants ────────────────────────────────────────────

  static const List<BodyRegion> kBodyRegions = [
    BodyRegion(id: 'head', label: 'Head / Face', icon: '\uD83E\uDDD1', group: 'Upper'),
    BodyRegion(id: 'neck', label: 'Neck', icon: '\uD83E\uDD92', group: 'Upper'),
    BodyRegion(id: 'chest', label: 'Chest', icon: '\uD83E\uDEC1', group: 'Torso'),
    BodyRegion(id: 'abdomen', label: 'Abdomen', icon: '\uD83E\uDEC3', group: 'Torso'),
    BodyRegion(id: 'upperBack', label: 'Upper Back', icon: '\uD83D\uDD19', group: 'Torso'),
    BodyRegion(id: 'lowerBack', label: 'Lower Back / Sacrum', icon: '\uD83D\uDD3B', group: 'Torso'),
    BodyRegion(id: 'leftArm', label: 'Left Arm / Hand', icon: '\uD83D\uDCAA', group: 'Arms'),
    BodyRegion(id: 'rightArm', label: 'Right Arm / Hand', icon: '\uD83D\uDCAA', group: 'Arms'),
    BodyRegion(id: 'leftLeg', label: 'Left Leg / Foot', icon: '\uD83E\uDDB5', group: 'Legs'),
    BodyRegion(id: 'rightLeg', label: 'Right Leg / Foot', icon: '\uD83E\uDDB5', group: 'Legs'),
    BodyRegion(id: 'buttocks', label: 'Buttocks / Perineum', icon: '\uD83E\uDE91', group: 'Torso'),
    BodyRegion(id: 'other', label: 'Other', icon: '\uD83D\uDCCD', group: 'Other'),
  ];

  static const List<String> kWoundTypes = [
    'Pressure sore',
    'Skin tear',
    'Bruise',
    'Rash / Irritation',
    'Surgical wound',
    'Diabetic ulcer',
    'Burn',
    'Incontinence-related',
    'Swelling / Edema',
    'Other',
  ];

  // ── Serialization ───────────────────────────────────────────────

  factory WoundEntry.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return WoundEntry(
      id: docId,
      photoUrl: data['photoUrl'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      title: data['title'] as String? ?? '',
      bodyRegion: data['bodyRegion'] as String? ?? 'other',
      woundType: data['woundType'] as String? ?? 'Other',
      severity: data['severity'] as String? ?? 'mild',
      notes: data['notes'] as String?,
      linkedEntryId: data['linkedEntryId'] as String?,
      elderId: data['elderId'] as String? ?? '',
      uploadedBy: data['uploadedBy'] as String? ?? '',
      uploadedByName: data['uploadedByName'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'photoUrl': photoUrl,
        'storagePath': storagePath,
        'title': title,
        'bodyRegion': bodyRegion,
        'woundType': woundType,
        'severity': severity,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (linkedEntryId != null) 'linkedEntryId': linkedEntryId,
        'elderId': elderId,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
      };
}
