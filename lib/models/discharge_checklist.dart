// lib/models/discharge_checklist.dart
//
// Hospital-to-home discharge wizard record. Stored under
// elderProfiles/{elderId}/dischargeChecklists.

import 'package:cloud_firestore/cloud_firestore.dart';

class DischargeChecklist {
  final String? id;
  final String elderId;
  final String createdBy;
  final String createdByName;
  final String dischargeDate; // yyyy-MM-dd
  final String? facilityName;
  final String? dischargeReason;
  final Map<String, bool> checklistSteps;
  final List<Map<String, dynamic>> medChanges;
  final Map<String, bool> safetyChecks;
  final List<Map<String, dynamic>> followUps;
  final bool isComplete;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const DischargeChecklist({
    this.id,
    required this.elderId,
    required this.createdBy,
    required this.createdByName,
    required this.dischargeDate,
    this.facilityName,
    this.dischargeReason,
    required this.checklistSteps,
    required this.medChanges,
    required this.safetyChecks,
    required this.followUps,
    this.isComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  static const List<Map<String, String>> kDischargeSteps = [
    {
      'id': 'dischargeSummary',
      'title': 'Obtain discharge summary',
      'desc':
          'Get a printed copy of the discharge instructions, diagnosis, and treatment summary.',
    },
    {
      'id': 'newMedList',
      'title': 'Get updated medication list',
      'desc':
          'Printed list of ALL medications — new, changed, and stopped. Compare with what you had before.',
    },
    {
      'id': 'prescriptionsFilled',
      'title': 'Fill new prescriptions',
      'desc':
          'Pick up any new medications BEFORE leaving the hospital if possible, or have pharmacy deliver same-day.',
    },
    {
      'id': 'woundCareInstructions',
      'title': 'Wound / drain care instructions',
      'desc':
          'Written instructions for any wound care, drain management, or dressing changes. Ask for a demonstration.',
    },
    {
      'id': 'activityRestrictions',
      'title': 'Understand activity restrictions',
      'desc':
          'Weight lifting limits, driving restrictions, bathing rules, when to resume normal activity.',
    },
    {
      'id': 'warningSignsReviewed',
      'title': 'Review warning signs',
      'desc':
          'Know exactly what symptoms mean "call the doctor" vs "go to the ER immediately."',
    },
    {
      'id': 'followUpsScheduled',
      'title': 'Schedule follow-up appointments',
      'desc':
          'PCP within 7 days, specialist as directed. Do NOT leave without dates on the calendar.',
    },
    {
      'id': 'transportArranged',
      'title': 'Arrange transport home',
      'desc':
          'Vehicle accessible, wheelchair if needed, someone to help at home for first 24 hours.',
    },
    {
      'id': 'homePrepped',
      'title': 'Home prepared',
      'desc':
          'Clear pathways, bed on main floor if needed, grab bars, supplies stocked.',
    },
    {
      'id': 'emergencyPlanReviewed',
      'title': 'Emergency plan reviewed',
      'desc':
          'Team knows what to do if something goes wrong in the first 48 hours.',
    },
  ];

  static const List<Map<String, String>> kSafetyChecks = [
    {'id': 'pathwaysClear', 'title': 'Walking pathways clear of clutter'},
    {'id': 'grabBarsInstalled', 'title': 'Grab bars in bathroom'},
    {'id': 'bedAccessible', 'title': 'Bed at accessible height'},
    {
      'id': 'lightingAdequate',
      'title': 'Adequate lighting in hallways, stairs, bedroom'
    },
    {'id': 'rugsSecured', 'title': 'Rugs secured or removed'},
    {
      'id': 'suppliesStocked',
      'title': 'Medical supplies stocked (bandages, gloves, etc.)'
    },
    {
      'id': 'equipmentReady',
      'title': 'Equipment set up (walker, oxygen, hospital bed)'
    },
    {'id': 'phoneCharging', 'title': 'Phone charged and within reach of bed'},
    {'id': 'emergencyNumbersPosted', 'title': 'Emergency numbers posted'},
    {'id': 'foodPrepared', 'title': 'Meals prepared or service arranged'},
  ];

  static const List<Map<String, String>> kFollowUpTypes = [
    {'type': 'PCP', 'label': 'PCP visit (within 7 days)'},
    {'type': 'specialist', 'label': 'Specialist follow-up'},
    {'type': 'lab', 'label': 'Lab work'},
    {'type': 'wound', 'label': 'Wound check'},
    {'type': 'pt', 'label': 'Physical therapy'},
  ];

  factory DischargeChecklist.fromFirestore(
      String elderId, String id, Map<String, dynamic> data) {
    return DischargeChecklist(
      id: id,
      elderId: elderId,
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      dischargeDate: data['dischargeDate'] as String? ?? '',
      facilityName: data['facilityName'] as String?,
      dischargeReason: data['dischargeReason'] as String?,
      checklistSteps: Map<String, bool>.from(
          (data['checklistSteps'] as Map?) ?? const {}),
      medChanges: List<Map<String, dynamic>>.from(
          (data['medChanges'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map)) ??
              const []),
      safetyChecks: Map<String, bool>.from(
          (data['safetyChecks'] as Map?) ?? const {}),
      followUps: List<Map<String, dynamic>>.from(
          (data['followUps'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map)) ??
              const []),
      isComplete: data['isComplete'] as bool? ?? false,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'createdByName': createdByName,
      'dischargeDate': dischargeDate,
      if (facilityName != null) 'facilityName': facilityName,
      if (dischargeReason != null) 'dischargeReason': dischargeReason,
      'checklistSteps': checklistSteps,
      'medChanges': medChanges,
      'safetyChecks': safetyChecks,
      'followUps': followUps,
      'isComplete': isComplete,
    };
  }

  /// Overall completion percentage across all sections (0..1).
  double get overallProgress {
    final stepDone =
        checklistSteps.values.where((v) => v).length / kDischargeSteps.length;
    final safetyDone =
        safetyChecks.values.where((v) => v).length / kSafetyChecks.length;
    final medDone =
        medChanges.isEmpty ? 0.0 : 1.0; // any reconciliation entered
    final followDone = followUps.where((f) {
      final d = f['scheduledDate'];
      return d != null && d.toString().isNotEmpty;
    }).length;
    final followFrac = followUps.isEmpty ? 0.0 : followDone / followUps.length;
    return (stepDone + safetyDone + medDone + followFrac) / 4;
  }
}
