// lib/models/incident_report.dart
//
// Regulatory-grade incident report. Covers falls, elopements,
// medication errors, behavioral incidents, injuries, property damage,
// and "other." Every field a facility compliance officer or liability
// attorney would expect is present; optional fields are nullable so
// the form stays fast for routine entries while still capturing
// everything when a serious event occurs.
//
// Storage: elderProfiles/{elderId}/incidentReports/{id}
//
// Audit trail: createdAt, updatedAt, reportedByUid, reportedByName,
// plus an immutable createdAt so edits never hide the original
// reporting timestamp.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// The broad category of the incident. Determines which follow-up
/// fields are required and which compliance PDF template sections
/// appear.
enum IncidentType {
  fall,
  elopement,
  medicationError,
  behavioralIncident,
  injury,
  propertyDamage,
  skinBreakdown,
  choking,
  other,
}

extension IncidentTypeX on IncidentType {
  String get label {
    switch (this) {
      case IncidentType.fall:
        return 'Fall';
      case IncidentType.elopement:
        return 'Elopement / wandering';
      case IncidentType.medicationError:
        return 'Medication error';
      case IncidentType.behavioralIncident:
        return 'Behavioral incident';
      case IncidentType.injury:
        return 'Injury';
      case IncidentType.propertyDamage:
        return 'Property damage';
      case IncidentType.skinBreakdown:
        return 'Skin breakdown / pressure injury';
      case IncidentType.choking:
        return 'Choking / aspiration';
      case IncidentType.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentType.fall:
        return Icons.elderly_outlined;
      case IncidentType.elopement:
        return Icons.directions_walk_outlined;
      case IncidentType.medicationError:
        return Icons.medication_outlined;
      case IncidentType.behavioralIncident:
        return Icons.psychology_outlined;
      case IncidentType.injury:
        return Icons.healing_outlined;
      case IncidentType.propertyDamage:
        return Icons.broken_image_outlined;
      case IncidentType.skinBreakdown:
        return Icons.airline_seat_flat_outlined;
      case IncidentType.choking:
        return Icons.warning_amber_outlined;
      case IncidentType.other:
        return Icons.report_outlined;
    }
  }

  Color get color {
    switch (this) {
      case IncidentType.fall:
        return AppTheme.statusAmber;
      case IncidentType.elopement:
        return AppTheme.dangerColor;
      case IncidentType.medicationError:
        return AppTheme.tileOrange;
      case IncidentType.behavioralIncident:
        return AppTheme.tileOrangeDeep;
      case IncidentType.injury:
        return AppTheme.statusRed;
      case IncidentType.propertyDamage:
        return AppTheme.textSecondary;
      case IncidentType.skinBreakdown:
        return AppTheme.entryVitalAccent;
      case IncidentType.choking:
        return AppTheme.dangerColor;
      case IncidentType.other:
        return AppTheme.tileBlueGrey;
    }
  }

  String get firestoreValue {
    switch (this) {
      case IncidentType.fall:
        return 'fall';
      case IncidentType.elopement:
        return 'elopement';
      case IncidentType.medicationError:
        return 'medication_error';
      case IncidentType.behavioralIncident:
        return 'behavioral_incident';
      case IncidentType.injury:
        return 'injury';
      case IncidentType.propertyDamage:
        return 'property_damage';
      case IncidentType.skinBreakdown:
        return 'skin_breakdown';
      case IncidentType.choking:
        return 'choking';
      case IncidentType.other:
        return 'other';
    }
  }

  static IncidentType fromString(String? s) {
    switch (s) {
      case 'fall':
        return IncidentType.fall;
      case 'elopement':
        return IncidentType.elopement;
      case 'medication_error':
        return IncidentType.medicationError;
      case 'behavioral_incident':
        return IncidentType.behavioralIncident;
      case 'injury':
        return IncidentType.injury;
      case 'property_damage':
        return IncidentType.propertyDamage;
      case 'skin_breakdown':
        return IncidentType.skinBreakdown;
      case 'choking':
        return IncidentType.choking;
      default:
        return IncidentType.other;
    }
  }
}

/// Severity guides triage priority and determines whether the PDF
/// flags the report as requiring supervisor review.
enum IncidentSeverity { minor, moderate, serious, critical }

extension IncidentSeverityX on IncidentSeverity {
  String get label {
    switch (this) {
      case IncidentSeverity.minor:
        return 'Minor — no injury, no medical attention';
      case IncidentSeverity.moderate:
        return 'Moderate — first aid or observation needed';
      case IncidentSeverity.serious:
        return 'Serious — medical treatment required';
      case IncidentSeverity.critical:
        return 'Critical — 911 called or hospitalization';
    }
  }

  String get shortLabel {
    switch (this) {
      case IncidentSeverity.minor:
        return 'Minor';
      case IncidentSeverity.moderate:
        return 'Moderate';
      case IncidentSeverity.serious:
        return 'Serious';
      case IncidentSeverity.critical:
        return 'Critical';
    }
  }

  Color get color {
    switch (this) {
      case IncidentSeverity.minor:
        return AppTheme.statusGreen;
      case IncidentSeverity.moderate:
        return AppTheme.statusAmber;
      case IncidentSeverity.serious:
        return AppTheme.statusRed;
      case IncidentSeverity.critical:
        return AppTheme.dangerColor;
    }
  }

  String get firestoreValue {
    switch (this) {
      case IncidentSeverity.minor:
        return 'minor';
      case IncidentSeverity.moderate:
        return 'moderate';
      case IncidentSeverity.serious:
        return 'serious';
      case IncidentSeverity.critical:
        return 'critical';
    }
  }

  static IncidentSeverity fromString(String? s) {
    switch (s) {
      case 'minor':
        return IncidentSeverity.minor;
      case 'moderate':
        return IncidentSeverity.moderate;
      case 'serious':
        return IncidentSeverity.serious;
      case 'critical':
        return IncidentSeverity.critical;
      default:
        return IncidentSeverity.minor;
    }
  }
}

/// Current workflow state. "Closed" means the follow-up plan has been
/// completed and signed off.
enum IncidentStatus { open, underReview, closed }

extension IncidentStatusX on IncidentStatus {
  String get label {
    switch (this) {
      case IncidentStatus.open:
        return 'Open';
      case IncidentStatus.underReview:
        return 'Under review';
      case IncidentStatus.closed:
        return 'Closed';
    }
  }

  Color get color {
    switch (this) {
      case IncidentStatus.open:
        return AppTheme.statusAmber;
      case IncidentStatus.underReview:
        return AppTheme.tileIndigo;
      case IncidentStatus.closed:
        return AppTheme.statusGreen;
    }
  }

  String get firestoreValue {
    switch (this) {
      case IncidentStatus.open:
        return 'open';
      case IncidentStatus.underReview:
        return 'under_review';
      case IncidentStatus.closed:
        return 'closed';
    }
  }

  static IncidentStatus fromString(String? s) {
    switch (s) {
      case 'under_review':
        return IncidentStatus.underReview;
      case 'closed':
        return IncidentStatus.closed;
      default:
        return IncidentStatus.open;
    }
  }
}

class IncidentReport {
  final String? id;
  final String elderId;

  // ── What happened ─────────────────────────────────────────
  final IncidentType type;
  final IncidentSeverity severity;
  final DateTime occurredAt;
  final String location; // "Bedroom", "Bathroom", "Kitchen", …
  final String description; // free-text narrative (REQUIRED)

  // ── Who was involved ──────────────────────────────────────
  final String careRecipientName;
  final List<String> witnessNames;
  final List<String> staffInvolved;

  // ── Immediate actions ─────────────────────────────────────
  final String immediateActions; // REQUIRED
  final bool injuryOccurred;
  final String? injuryDescription;
  final bool emergencyServicesContacted;
  final bool familyNotified;
  final String? familyNotifiedDetails;

  // ── Follow-up plan ────────────────────────────────────────
  final String followUpPlan; // REQUIRED
  final DateTime? followUpDueDate;
  final String? preventiveMeasures;
  final String? supervisorNotes;

  // ── Metadata / audit ──────────────────────────────────────
  final IncidentStatus status;
  final String reportedByUid;
  final String reportedByName;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const IncidentReport({
    this.id,
    required this.elderId,
    required this.type,
    this.severity = IncidentSeverity.minor,
    required this.occurredAt,
    required this.location,
    required this.description,
    required this.careRecipientName,
    this.witnessNames = const [],
    this.staffInvolved = const [],
    required this.immediateActions,
    this.injuryOccurred = false,
    this.injuryDescription,
    this.emergencyServicesContacted = false,
    this.familyNotified = false,
    this.familyNotifiedDetails,
    required this.followUpPlan,
    this.followUpDueDate,
    this.preventiveMeasures,
    this.supervisorNotes,
    this.status = IncidentStatus.open,
    required this.reportedByUid,
    required this.reportedByName,
    this.createdAt,
    this.updatedAt,
  });

  /// Convenience: true when all three required narratives are non-empty.
  bool get isComplete =>
      description.trim().isNotEmpty &&
      immediateActions.trim().isNotEmpty &&
      followUpPlan.trim().isNotEmpty;

  /// True when severity is serious or critical.
  bool get requiresSupervisorReview =>
      severity == IncidentSeverity.serious ||
      severity == IncidentSeverity.critical;

  // ── Common locations preset list ──────────────────────────
  static const List<String> kLocations = [
    'Bedroom',
    'Bathroom',
    'Kitchen',
    'Living room',
    'Hallway / stairs',
    'Dining area',
    'Outdoors / yard',
    'Vehicle / transport',
    'Facility common area',
    'Other',
  ];

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory IncidentReport.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return IncidentReport(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      type: IncidentTypeX.fromString(data['type'] as String?),
      severity:
          IncidentSeverityX.fromString(data['severity'] as String?),
      occurredAt: (data['occurredAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      location: data['location'] as String? ?? '',
      description: data['description'] as String? ?? '',
      careRecipientName: data['careRecipientName'] as String? ?? '',
      witnessNames: (data['witnessNames'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      staffInvolved:
          (data['staffInvolved'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      immediateActions: data['immediateActions'] as String? ?? '',
      injuryOccurred: data['injuryOccurred'] as bool? ?? false,
      injuryDescription: data['injuryDescription'] as String?,
      emergencyServicesContacted:
          data['emergencyServicesContacted'] as bool? ?? false,
      familyNotified: data['familyNotified'] as bool? ?? false,
      familyNotifiedDetails: data['familyNotifiedDetails'] as String?,
      followUpPlan: data['followUpPlan'] as String? ?? '',
      followUpDueDate:
          (data['followUpDueDate'] as Timestamp?)?.toDate(),
      preventiveMeasures: data['preventiveMeasures'] as String?,
      supervisorNotes: data['supervisorNotes'] as String?,
      status: IncidentStatusX.fromString(data['status'] as String?),
      reportedByUid: data['reportedByUid'] as String? ?? '',
      reportedByName: data['reportedByName'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'elderId': elderId,
        'type': type.firestoreValue,
        'severity': severity.firestoreValue,
        'occurredAt': Timestamp.fromDate(occurredAt),
        'location': location,
        'description': description,
        'careRecipientName': careRecipientName,
        if (witnessNames.isNotEmpty) 'witnessNames': witnessNames,
        if (staffInvolved.isNotEmpty) 'staffInvolved': staffInvolved,
        'immediateActions': immediateActions,
        'injuryOccurred': injuryOccurred,
        if (injuryDescription != null && injuryDescription!.isNotEmpty)
          'injuryDescription': injuryDescription,
        'emergencyServicesContacted': emergencyServicesContacted,
        'familyNotified': familyNotified,
        if (familyNotifiedDetails != null &&
            familyNotifiedDetails!.isNotEmpty)
          'familyNotifiedDetails': familyNotifiedDetails,
        'followUpPlan': followUpPlan,
        if (followUpDueDate != null)
          'followUpDueDate': Timestamp.fromDate(followUpDueDate!),
        if (preventiveMeasures != null &&
            preventiveMeasures!.isNotEmpty)
          'preventiveMeasures': preventiveMeasures,
        if (supervisorNotes != null && supervisorNotes!.isNotEmpty)
          'supervisorNotes': supervisorNotes,
        'status': status.firestoreValue,
        'reportedByUid': reportedByUid,
        'reportedByName': reportedByName,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  IncidentReport copyWith({
    String? id,
    String? elderId,
    IncidentType? type,
    IncidentSeverity? severity,
    DateTime? occurredAt,
    String? location,
    String? description,
    String? careRecipientName,
    List<String>? witnessNames,
    List<String>? staffInvolved,
    String? immediateActions,
    bool? injuryOccurred,
    String? injuryDescription,
    bool? emergencyServicesContacted,
    bool? familyNotified,
    String? familyNotifiedDetails,
    String? followUpPlan,
    DateTime? followUpDueDate,
    String? preventiveMeasures,
    String? supervisorNotes,
    IncidentStatus? status,
    String? reportedByUid,
    String? reportedByName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return IncidentReport(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      occurredAt: occurredAt ?? this.occurredAt,
      location: location ?? this.location,
      description: description ?? this.description,
      careRecipientName: careRecipientName ?? this.careRecipientName,
      witnessNames: witnessNames ?? this.witnessNames,
      staffInvolved: staffInvolved ?? this.staffInvolved,
      immediateActions: immediateActions ?? this.immediateActions,
      injuryOccurred: injuryOccurred ?? this.injuryOccurred,
      injuryDescription: injuryDescription ?? this.injuryDescription,
      emergencyServicesContacted:
          emergencyServicesContacted ?? this.emergencyServicesContacted,
      familyNotified: familyNotified ?? this.familyNotified,
      familyNotifiedDetails:
          familyNotifiedDetails ?? this.familyNotifiedDetails,
      followUpPlan: followUpPlan ?? this.followUpPlan,
      followUpDueDate: followUpDueDate ?? this.followUpDueDate,
      preventiveMeasures: preventiveMeasures ?? this.preventiveMeasures,
      supervisorNotes: supervisorNotes ?? this.supervisorNotes,
      status: status ?? this.status,
      reportedByUid: reportedByUid ?? this.reportedByUid,
      reportedByName: reportedByName ?? this.reportedByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
