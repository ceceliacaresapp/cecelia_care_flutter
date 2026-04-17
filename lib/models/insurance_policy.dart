// lib/models/insurance_policy.dart
//
// A richer "insurance policy" record stored in Firestore. This is
// separate from the existing `InsurancePlan` (SharedPreferences-only
// single-plan settings used by the budget OOP tracker) — families
// often juggle multiple plans (Medicare + supplemental + Part D + LTC)
// and the advocacy workflows (claim tracking, appeals) need something
// structured and shareable across the care team.
//
// Storage: top-level `insurancePolicies/{id}`, owner-scoped via
// `userId`. Claims reference a policy by id.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Major classes of coverage most families deal with. Plain strings in
/// Firestore so future plan types can be added without a migration.
enum InsurancePlanType {
  medicare,
  medicareAdvantage,
  medicarePartD,
  medicaid,
  supplemental, // Medigap
  longTermCare,
  privatePpo,
  privateHmo,
  vaTricare,
  other,
}

extension InsurancePlanTypeX on InsurancePlanType {
  String get label {
    switch (this) {
      case InsurancePlanType.medicare:
        return 'Medicare (A/B)';
      case InsurancePlanType.medicareAdvantage:
        return 'Medicare Advantage (C)';
      case InsurancePlanType.medicarePartD:
        return 'Medicare Part D';
      case InsurancePlanType.medicaid:
        return 'Medicaid';
      case InsurancePlanType.supplemental:
        return 'Medigap / Supplemental';
      case InsurancePlanType.longTermCare:
        return 'Long-term care';
      case InsurancePlanType.privatePpo:
        return 'Private PPO';
      case InsurancePlanType.privateHmo:
        return 'Private HMO';
      case InsurancePlanType.vaTricare:
        return 'VA / TRICARE';
      case InsurancePlanType.other:
        return 'Other';
    }
  }

  String get firestoreValue {
    switch (this) {
      case InsurancePlanType.medicare:
        return 'medicare';
      case InsurancePlanType.medicareAdvantage:
        return 'medicare_advantage';
      case InsurancePlanType.medicarePartD:
        return 'medicare_part_d';
      case InsurancePlanType.medicaid:
        return 'medicaid';
      case InsurancePlanType.supplemental:
        return 'supplemental';
      case InsurancePlanType.longTermCare:
        return 'ltc';
      case InsurancePlanType.privatePpo:
        return 'private_ppo';
      case InsurancePlanType.privateHmo:
        return 'private_hmo';
      case InsurancePlanType.vaTricare:
        return 'va_tricare';
      case InsurancePlanType.other:
        return 'other';
    }
  }

  static InsurancePlanType fromString(String? s) {
    switch (s) {
      case 'medicare':
        return InsurancePlanType.medicare;
      case 'medicare_advantage':
        return InsurancePlanType.medicareAdvantage;
      case 'medicare_part_d':
        return InsurancePlanType.medicarePartD;
      case 'medicaid':
        return InsurancePlanType.medicaid;
      case 'supplemental':
        return InsurancePlanType.supplemental;
      case 'ltc':
        return InsurancePlanType.longTermCare;
      case 'private_ppo':
        return InsurancePlanType.privatePpo;
      case 'private_hmo':
        return InsurancePlanType.privateHmo;
      case 'va_tricare':
        return InsurancePlanType.vaTricare;
      default:
        return InsurancePlanType.other;
    }
  }
}

class InsurancePolicy {
  final String? id;
  final String userId;
  final String careRecipientId;

  final String planName; // "Blue Cross PPO Gold"
  final String carrier; // "Blue Cross Blue Shield"
  final InsurancePlanType planType;

  final String? memberId;
  final String? groupNumber;
  final String? rxBin;

  /// Active coverage window. Both inclusive — endDate null means
  /// "open-ended" (Medicare, for example).
  final DateTime startDate;
  final DateTime? endDate;

  final double? annualDeductible;
  final double? outOfPocketMax;
  final double? monthlyPremium;

  /// Contact strings stored free-form so caregivers can paste whatever
  /// is on their card.
  final String? claimsPhone;
  final String? memberServicesPhone;
  final String? portalUrl;

  final String? notes;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const InsurancePolicy({
    this.id,
    required this.userId,
    required this.careRecipientId,
    required this.planName,
    required this.carrier,
    this.planType = InsurancePlanType.other,
    this.memberId,
    this.groupNumber,
    this.rxBin,
    required this.startDate,
    this.endDate,
    this.annualDeductible,
    this.outOfPocketMax,
    this.monthlyPremium,
    this.claimsPhone,
    this.memberServicesPhone,
    this.portalUrl,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool isActiveOn(DateTime d) {
    if (d.isBefore(startDate)) return false;
    if (endDate == null) return true;
    return !d.isAfter(endDate!);
  }

  bool get isCurrentlyActive => isActiveOn(DateTime.now());

  /// Days until this policy expires, or null if open-ended.
  int? get daysUntilEnd {
    final end = endDate;
    if (end == null) return null;
    final diff = end.difference(DateTime.now()).inDays;
    return diff;
  }

  /// Short label used across the dashboard — "Blue Cross PPO · Member 1234"
  String get displayTitle {
    final short = memberId == null || memberId!.isEmpty
        ? ''
        : ' · Member ${_tail(memberId!, 4)}';
    return '$planName$short';
  }

  static String _tail(String s, int n) =>
      s.length <= n ? s : '…${s.substring(s.length - n)}';

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory InsurancePolicy.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, [
    SnapshotOptions? _,
  ]) {
    final data = doc.data() ?? const <String, dynamic>{};
    return InsurancePolicy(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      careRecipientId: data['careRecipientId'] as String? ?? '',
      planName: data['planName'] as String? ?? '',
      carrier: data['carrier'] as String? ?? '',
      planType: InsurancePlanTypeX.fromString(data['planType'] as String?),
      memberId: data['memberId'] as String?,
      groupNumber: data['groupNumber'] as String?,
      rxBin: data['rxBin'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ??
          DateTime(DateTime.now().year, 1, 1),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      annualDeductible: (data['annualDeductible'] as num?)?.toDouble(),
      outOfPocketMax: (data['outOfPocketMax'] as num?)?.toDouble(),
      monthlyPremium: (data['monthlyPremium'] as num?)?.toDouble(),
      claimsPhone: data['claimsPhone'] as String?,
      memberServicesPhone: data['memberServicesPhone'] as String?,
      portalUrl: data['portalUrl'] as String?,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'careRecipientId': careRecipientId,
      'planName': planName,
      'carrier': carrier,
      'planType': planType.firestoreValue,
      if (memberId != null && memberId!.isNotEmpty) 'memberId': memberId,
      if (groupNumber != null && groupNumber!.isNotEmpty)
        'groupNumber': groupNumber,
      if (rxBin != null && rxBin!.isNotEmpty) 'rxBin': rxBin,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (annualDeductible != null) 'annualDeductible': annualDeductible,
      if (outOfPocketMax != null) 'outOfPocketMax': outOfPocketMax,
      if (monthlyPremium != null) 'monthlyPremium': monthlyPremium,
      if (claimsPhone != null && claimsPhone!.isNotEmpty)
        'claimsPhone': claimsPhone,
      if (memberServicesPhone != null && memberServicesPhone!.isNotEmpty)
        'memberServicesPhone': memberServicesPhone,
      if (portalUrl != null && portalUrl!.isNotEmpty) 'portalUrl': portalUrl,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  InsurancePolicy copyWith({
    String? id,
    String? userId,
    String? careRecipientId,
    String? planName,
    String? carrier,
    InsurancePlanType? planType,
    String? memberId,
    String? groupNumber,
    String? rxBin,
    DateTime? startDate,
    DateTime? endDate,
    double? annualDeductible,
    double? outOfPocketMax,
    double? monthlyPremium,
    String? claimsPhone,
    String? memberServicesPhone,
    String? portalUrl,
    String? notes,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return InsurancePolicy(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      careRecipientId: careRecipientId ?? this.careRecipientId,
      planName: planName ?? this.planName,
      carrier: carrier ?? this.carrier,
      planType: planType ?? this.planType,
      memberId: memberId ?? this.memberId,
      groupNumber: groupNumber ?? this.groupNumber,
      rxBin: rxBin ?? this.rxBin,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      annualDeductible: annualDeductible ?? this.annualDeductible,
      outOfPocketMax: outOfPocketMax ?? this.outOfPocketMax,
      monthlyPremium: monthlyPremium ?? this.monthlyPremium,
      claimsPhone: claimsPhone ?? this.claimsPhone,
      memberServicesPhone: memberServicesPhone ?? this.memberServicesPhone,
      portalUrl: portalUrl ?? this.portalUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
