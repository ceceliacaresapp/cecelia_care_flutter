// lib/models/insurance_claim.dart
//
// A single insurance claim — EOB-style record linking a date-of-service
// to what was billed, what insurance paid, and what the family owes.
// Carries full denial + appeal state inline so the advocate doesn't
// juggle two collections when escalating.
//
// Storage: top-level `insuranceClaims/{id}`, owner-scoped via userId.
// Linked to an InsurancePolicy via `policyId` but kept decoupled so
// a claim survives if the policy doc is deleted.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Lifecycle of an insurance claim. `appealed` flows back into either
/// `paid` (won) or `denied` (lost) — we keep "appealed" distinct so
/// the dashboard can flag it as an open action item.
enum ClaimStatus {
  submitted,
  pending,
  paid,
  partiallyPaid,
  denied,
  appealed,
  withdrawn,
}

extension ClaimStatusX on ClaimStatus {
  String get label {
    switch (this) {
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.paid:
        return 'Paid';
      case ClaimStatus.partiallyPaid:
        return 'Partially paid';
      case ClaimStatus.denied:
        return 'Denied';
      case ClaimStatus.appealed:
        return 'Appealed';
      case ClaimStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  Color get color {
    switch (this) {
      case ClaimStatus.submitted:
        return AppTheme.tileBlue;
      case ClaimStatus.pending:
        return AppTheme.statusAmber;
      case ClaimStatus.paid:
        return AppTheme.statusGreen;
      case ClaimStatus.partiallyPaid:
        return AppTheme.tileTeal;
      case ClaimStatus.denied:
        return AppTheme.dangerColor;
      case ClaimStatus.appealed:
        return AppTheme.tileIndigoDeep;
      case ClaimStatus.withdrawn:
        return AppTheme.textSecondary;
    }
  }

  IconData get icon {
    switch (this) {
      case ClaimStatus.submitted:
        return Icons.send_outlined;
      case ClaimStatus.pending:
        return Icons.hourglass_bottom_outlined;
      case ClaimStatus.paid:
        return Icons.check_circle_outline;
      case ClaimStatus.partiallyPaid:
        return Icons.check_circle_outline;
      case ClaimStatus.denied:
        return Icons.cancel_outlined;
      case ClaimStatus.appealed:
        return Icons.gavel_outlined;
      case ClaimStatus.withdrawn:
        return Icons.remove_circle_outline;
    }
  }

  /// Does this status require an action from the family?
  bool get needsAction =>
      this == ClaimStatus.denied ||
      this == ClaimStatus.appealed ||
      this == ClaimStatus.submitted ||
      this == ClaimStatus.pending;

  String get firestoreValue {
    switch (this) {
      case ClaimStatus.submitted:
        return 'submitted';
      case ClaimStatus.pending:
        return 'pending';
      case ClaimStatus.paid:
        return 'paid';
      case ClaimStatus.partiallyPaid:
        return 'partially_paid';
      case ClaimStatus.denied:
        return 'denied';
      case ClaimStatus.appealed:
        return 'appealed';
      case ClaimStatus.withdrawn:
        return 'withdrawn';
    }
  }

  static ClaimStatus fromString(String? s) {
    switch (s) {
      case 'submitted':
        return ClaimStatus.submitted;
      case 'pending':
        return ClaimStatus.pending;
      case 'paid':
        return ClaimStatus.paid;
      case 'partially_paid':
        return ClaimStatus.partiallyPaid;
      case 'denied':
        return ClaimStatus.denied;
      case 'appealed':
        return ClaimStatus.appealed;
      case 'withdrawn':
        return ClaimStatus.withdrawn;
      default:
        return ClaimStatus.submitted;
    }
  }
}

/// Appeal lifecycle — lives inside `InsuranceClaim.appeal` when the
/// claim is in denied / appealed status.
class ClaimAppeal {
  final String denialReason;
  final DateTime? appealDeadline;
  final DateTime? appealSubmittedOn;
  final String? appealLetterText;
  final ClaimAppealOutcome outcome;
  final String? outcomeNotes;

  const ClaimAppeal({
    this.denialReason = '',
    this.appealDeadline,
    this.appealSubmittedOn,
    this.appealLetterText,
    this.outcome = ClaimAppealOutcome.pending,
    this.outcomeNotes,
  });

  bool get isEmpty =>
      denialReason.isEmpty &&
      appealDeadline == null &&
      appealSubmittedOn == null &&
      (appealLetterText == null || appealLetterText!.isEmpty) &&
      outcome == ClaimAppealOutcome.pending;

  Map<String, dynamic> toMap() => {
        'denialReason': denialReason,
        if (appealDeadline != null)
          'appealDeadline': Timestamp.fromDate(appealDeadline!),
        if (appealSubmittedOn != null)
          'appealSubmittedOn': Timestamp.fromDate(appealSubmittedOn!),
        if (appealLetterText != null && appealLetterText!.isNotEmpty)
          'appealLetterText': appealLetterText,
        'outcome': outcome.firestoreValue,
        if (outcomeNotes != null && outcomeNotes!.isNotEmpty)
          'outcomeNotes': outcomeNotes,
      };

  factory ClaimAppeal.fromMap(Map<String, dynamic>? m) {
    if (m == null) return const ClaimAppeal();
    return ClaimAppeal(
      denialReason: m['denialReason'] as String? ?? '',
      appealDeadline: (m['appealDeadline'] as Timestamp?)?.toDate(),
      appealSubmittedOn: (m['appealSubmittedOn'] as Timestamp?)?.toDate(),
      appealLetterText: m['appealLetterText'] as String?,
      outcome: ClaimAppealOutcomeX.fromString(m['outcome'] as String?),
      outcomeNotes: m['outcomeNotes'] as String?,
    );
  }

  ClaimAppeal copyWith({
    String? denialReason,
    DateTime? appealDeadline,
    DateTime? appealSubmittedOn,
    String? appealLetterText,
    ClaimAppealOutcome? outcome,
    String? outcomeNotes,
  }) =>
      ClaimAppeal(
        denialReason: denialReason ?? this.denialReason,
        appealDeadline: appealDeadline ?? this.appealDeadline,
        appealSubmittedOn: appealSubmittedOn ?? this.appealSubmittedOn,
        appealLetterText: appealLetterText ?? this.appealLetterText,
        outcome: outcome ?? this.outcome,
        outcomeNotes: outcomeNotes ?? this.outcomeNotes,
      );
}

enum ClaimAppealOutcome { pending, overturnedFull, overturnedPartial, upheld }

extension ClaimAppealOutcomeX on ClaimAppealOutcome {
  String get label {
    switch (this) {
      case ClaimAppealOutcome.pending:
        return 'Awaiting decision';
      case ClaimAppealOutcome.overturnedFull:
        return 'Overturned — fully paid';
      case ClaimAppealOutcome.overturnedPartial:
        return 'Overturned — partially paid';
      case ClaimAppealOutcome.upheld:
        return 'Upheld — still denied';
    }
  }

  String get firestoreValue {
    switch (this) {
      case ClaimAppealOutcome.pending:
        return 'pending';
      case ClaimAppealOutcome.overturnedFull:
        return 'overturned_full';
      case ClaimAppealOutcome.overturnedPartial:
        return 'overturned_partial';
      case ClaimAppealOutcome.upheld:
        return 'upheld';
    }
  }

  static ClaimAppealOutcome fromString(String? s) {
    switch (s) {
      case 'overturned_full':
        return ClaimAppealOutcome.overturnedFull;
      case 'overturned_partial':
        return ClaimAppealOutcome.overturnedPartial;
      case 'upheld':
        return ClaimAppealOutcome.upheld;
      default:
        return ClaimAppealOutcome.pending;
    }
  }
}

class InsuranceClaim {
  final String? id;
  final String userId;
  final String careRecipientId;
  final String? policyId; // References InsurancePolicy.id

  final DateTime dateOfService;
  final String provider; // "Dr. Chen, Cardiology"
  final String serviceDescription;
  final String? cptCode;
  final String? claimNumber;

  final double billedAmount;
  final double insurancePaid;
  final double patientResponsibility;

  final ClaimStatus status;
  final DateTime? dateSubmitted;
  final DateTime? dateResolved;

  final ClaimAppeal appeal;

  final String? notes;
  final List<String> linkedVaultDocIds;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const InsuranceClaim({
    this.id,
    required this.userId,
    required this.careRecipientId,
    this.policyId,
    required this.dateOfService,
    required this.provider,
    required this.serviceDescription,
    this.cptCode,
    this.claimNumber,
    required this.billedAmount,
    this.insurancePaid = 0,
    this.patientResponsibility = 0,
    this.status = ClaimStatus.submitted,
    this.dateSubmitted,
    this.dateResolved,
    this.appeal = const ClaimAppeal(),
    this.notes,
    this.linkedVaultDocIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// What the patient owes but isn't yet insured against (bill minus
  /// what insurance paid, minus what's already attributed to patient
  /// responsibility). When negative, insurance overpaid — which
  /// usually means wait for an adjustment.
  double get amountOutstanding {
    final total = billedAmount - insurancePaid - patientResponsibility;
    return total.clamp(-billedAmount, billedAmount).toDouble();
  }

  /// True when the appeal window is within 14 days and the claim is
  /// still in denied/appealed status. Drives the "URGENT" pill.
  bool get hasImminentAppealDeadline {
    final deadline = appeal.appealDeadline;
    if (deadline == null) return false;
    if (status != ClaimStatus.denied && status != ClaimStatus.appealed) {
      return false;
    }
    final diff = deadline.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 14;
  }

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory InsuranceClaim.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, [
    SnapshotOptions? _,
  ]) {
    final data = doc.data() ?? const <String, dynamic>{};
    return InsuranceClaim(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      careRecipientId: data['careRecipientId'] as String? ?? '',
      policyId: data['policyId'] as String?,
      dateOfService: (data['dateOfService'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      provider: data['provider'] as String? ?? '',
      serviceDescription: data['serviceDescription'] as String? ?? '',
      cptCode: data['cptCode'] as String?,
      claimNumber: data['claimNumber'] as String?,
      billedAmount: (data['billedAmount'] as num?)?.toDouble() ?? 0,
      insurancePaid: (data['insurancePaid'] as num?)?.toDouble() ?? 0,
      patientResponsibility:
          (data['patientResponsibility'] as num?)?.toDouble() ?? 0,
      status: ClaimStatusX.fromString(data['status'] as String?),
      dateSubmitted: (data['dateSubmitted'] as Timestamp?)?.toDate(),
      dateResolved: (data['dateResolved'] as Timestamp?)?.toDate(),
      appeal: ClaimAppeal.fromMap(data['appeal'] as Map<String, dynamic>?),
      notes: data['notes'] as String?,
      linkedVaultDocIds: (data['linkedVaultDocIds'] as List<dynamic>? ??
              const <dynamic>[])
          .map((e) => e.toString())
          .toList(),
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'careRecipientId': careRecipientId,
      if (policyId != null) 'policyId': policyId,
      'dateOfService': Timestamp.fromDate(dateOfService),
      'provider': provider,
      'serviceDescription': serviceDescription,
      if (cptCode != null && cptCode!.isNotEmpty) 'cptCode': cptCode,
      if (claimNumber != null && claimNumber!.isNotEmpty)
        'claimNumber': claimNumber,
      'billedAmount': billedAmount,
      'insurancePaid': insurancePaid,
      'patientResponsibility': patientResponsibility,
      'status': status.firestoreValue,
      if (dateSubmitted != null)
        'dateSubmitted': Timestamp.fromDate(dateSubmitted!),
      if (dateResolved != null)
        'dateResolved': Timestamp.fromDate(dateResolved!),
      if (!appeal.isEmpty) 'appeal': appeal.toMap(),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (linkedVaultDocIds.isNotEmpty)
        'linkedVaultDocIds': linkedVaultDocIds,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  InsuranceClaim copyWith({
    String? id,
    String? userId,
    String? careRecipientId,
    String? policyId,
    DateTime? dateOfService,
    String? provider,
    String? serviceDescription,
    String? cptCode,
    String? claimNumber,
    double? billedAmount,
    double? insurancePaid,
    double? patientResponsibility,
    ClaimStatus? status,
    DateTime? dateSubmitted,
    DateTime? dateResolved,
    ClaimAppeal? appeal,
    String? notes,
    List<String>? linkedVaultDocIds,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) =>
      InsuranceClaim(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        careRecipientId: careRecipientId ?? this.careRecipientId,
        policyId: policyId ?? this.policyId,
        dateOfService: dateOfService ?? this.dateOfService,
        provider: provider ?? this.provider,
        serviceDescription: serviceDescription ?? this.serviceDescription,
        cptCode: cptCode ?? this.cptCode,
        claimNumber: claimNumber ?? this.claimNumber,
        billedAmount: billedAmount ?? this.billedAmount,
        insurancePaid: insurancePaid ?? this.insurancePaid,
        patientResponsibility:
            patientResponsibility ?? this.patientResponsibility,
        status: status ?? this.status,
        dateSubmitted: dateSubmitted ?? this.dateSubmitted,
        dateResolved: dateResolved ?? this.dateResolved,
        appeal: appeal ?? this.appeal,
        notes: notes ?? this.notes,
        linkedVaultDocIds: linkedVaultDocIds ?? this.linkedVaultDocIds,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

// ---------------------------------------------------------------------------
// Benefit counter — "20 PT visits per year" / "100 SNF days per benefit
// period" / "$2000 annual PT cap." Stored as a subcollection of the
// policy it belongs to.
// ---------------------------------------------------------------------------

enum BenefitUnit { visit, day, hour, dollar, session }

extension BenefitUnitX on BenefitUnit {
  String get label {
    switch (this) {
      case BenefitUnit.visit:
        return 'visits';
      case BenefitUnit.day:
        return 'days';
      case BenefitUnit.hour:
        return 'hours';
      case BenefitUnit.dollar:
        return 'dollars';
      case BenefitUnit.session:
        return 'sessions';
    }
  }

  String get singular {
    switch (this) {
      case BenefitUnit.visit:
        return 'visit';
      case BenefitUnit.day:
        return 'day';
      case BenefitUnit.hour:
        return 'hour';
      case BenefitUnit.dollar:
        return 'dollar';
      case BenefitUnit.session:
        return 'session';
    }
  }

  String get firestoreValue {
    switch (this) {
      case BenefitUnit.visit:
        return 'visit';
      case BenefitUnit.day:
        return 'day';
      case BenefitUnit.hour:
        return 'hour';
      case BenefitUnit.dollar:
        return 'dollar';
      case BenefitUnit.session:
        return 'session';
    }
  }

  static BenefitUnit fromString(String? s) {
    switch (s) {
      case 'day':
        return BenefitUnit.day;
      case 'hour':
        return BenefitUnit.hour;
      case 'dollar':
        return BenefitUnit.dollar;
      case 'session':
        return BenefitUnit.session;
      case 'visit':
      default:
        return BenefitUnit.visit;
    }
  }
}

class BenefitCounter {
  final String? id;
  final String policyId;

  /// Duplicated from the parent policy so the Firestore rule can
  /// enforce owner-only access without an extra read on the parent.
  final String userId;

  final String benefitName; // "Physical therapy"
  final double limit; // 20.0
  final double used; // 7.5
  final BenefitUnit unit;

  /// Coverage period the limit applies to. e.g. "annual", "per benefit
  /// period", "lifetime". Stored as explicit start/end dates for the
  /// current period so we can prorate + reset correctly.
  final DateTime periodStart;
  final DateTime? periodEnd;

  final String? notes;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const BenefitCounter({
    this.id,
    required this.policyId,
    required this.userId,
    required this.benefitName,
    required this.limit,
    this.used = 0,
    this.unit = BenefitUnit.visit,
    required this.periodStart,
    this.periodEnd,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  double get remaining => (limit - used).clamp(0, limit).toDouble();
  double get progress => limit == 0 ? 0 : (used / limit).clamp(0, 1);
  bool get isExhausted => used >= limit;

  /// Days left in the coverage period, or null if open-ended.
  int? get daysLeftInPeriod {
    final end = periodEnd;
    if (end == null) return null;
    return end.difference(DateTime.now()).inDays;
  }

  String get displaySummary {
    final u = limit == 1 ? unit.singular : unit.label;
    final usedFmt = unit == BenefitUnit.dollar
        ? '\$${used.toStringAsFixed(0)}'
        : _trim(used);
    final limitFmt = unit == BenefitUnit.dollar
        ? '\$${limit.toStringAsFixed(0)}'
        : _trim(limit);
    return '$usedFmt / $limitFmt $u';
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory BenefitCounter.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String policyId, [
    SnapshotOptions? _,
  ]) {
    final data = doc.data() ?? const <String, dynamic>{};
    return BenefitCounter(
      id: doc.id,
      policyId: policyId,
      userId: data['userId'] as String? ?? '',
      benefitName: data['benefitName'] as String? ?? '',
      limit: (data['limit'] as num?)?.toDouble() ?? 0,
      used: (data['used'] as num?)?.toDouble() ?? 0,
      unit: BenefitUnitX.fromString(data['unit'] as String?),
      periodStart: (data['periodStart'] as Timestamp?)?.toDate() ??
          DateTime(DateTime.now().year, 1, 1),
      periodEnd: (data['periodEnd'] as Timestamp?)?.toDate(),
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'benefitName': benefitName,
        'limit': limit,
        'used': used,
        'unit': unit.firestoreValue,
        'periodStart': Timestamp.fromDate(periodStart),
        if (periodEnd != null) 'periodEnd': Timestamp.fromDate(periodEnd!),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  BenefitCounter copyWith({
    String? id,
    String? policyId,
    String? userId,
    String? benefitName,
    double? limit,
    double? used,
    BenefitUnit? unit,
    DateTime? periodStart,
    DateTime? periodEnd,
    String? notes,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) =>
      BenefitCounter(
        id: id ?? this.id,
        policyId: policyId ?? this.policyId,
        userId: userId ?? this.userId,
        benefitName: benefitName ?? this.benefitName,
        limit: limit ?? this.limit,
        used: used ?? this.used,
        unit: unit ?? this.unit,
        periodStart: periodStart ?? this.periodStart,
        periodEnd: periodEnd ?? this.periodEnd,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
