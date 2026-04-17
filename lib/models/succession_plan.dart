// lib/models/succession_plan.dart
//
// SuccessionPlan — "If I Can't Be Here" backup-caregiver documentation.
//
// One plan per elder, stored at:
//   elderProfiles/{elderId}/successionPlan/primary
//
// Captures the irreplaceable tacit knowledge a primary caregiver carries:
// backup caregiver identity, daily routines, medication quirks, behavioral
// triggers + what calms them, doctor & insurance specifics, legal/financial
// contacts, location of important documents, and a free-form "things only
// I know" field.
//
// A derived completeness percentage is shown in the UI and stamped on the
// generated PDF so the primary caregiver can gauge how ready the plan is.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Fixed doc id — there is one succession plan per elder. Using a fixed id
/// means the screen can deterministically read/write without a doc-list
/// round-trip and there is no "which plan is current?" ambiguity.
const String kSuccessionPlanDocId = 'primary';

/// Backup caregiver contact + relationship metadata.
class BackupCaregiver {
  final String name;
  final String relationship;
  final String phone;
  final String email;
  final String notes; // access notes: house key, gate code, pet instructions…

  const BackupCaregiver({
    this.name = '',
    this.relationship = '',
    this.phone = '',
    this.email = '',
    this.notes = '',
  });

  bool get isEmpty =>
      name.isEmpty &&
      relationship.isEmpty &&
      phone.isEmpty &&
      email.isEmpty &&
      notes.isEmpty;

  bool get isComplete =>
      name.trim().isNotEmpty &&
      phone.trim().isNotEmpty &&
      relationship.trim().isNotEmpty;

  Map<String, dynamic> toMap() => {
        'name': name,
        'relationship': relationship,
        'phone': phone,
        'email': email,
        'notes': notes,
      };

  factory BackupCaregiver.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    return BackupCaregiver(
      name: (d['name'] as String?) ?? '',
      relationship: (d['relationship'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      notes: (d['notes'] as String?) ?? '',
    );
  }

  BackupCaregiver copyWith({
    String? name,
    String? relationship,
    String? phone,
    String? email,
    String? notes,
  }) =>
      BackupCaregiver(
        name: name ?? this.name,
        relationship: relationship ?? this.relationship,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        notes: notes ?? this.notes,
      );
}

/// A single doctor reference — name, specialty, phone, preference notes.
class DoctorContact {
  final String name;
  final String specialty;
  final String phone;
  final String preferences; // e.g. "prefers MyChart messages; nurse is Sara"

  const DoctorContact({
    this.name = '',
    this.specialty = '',
    this.phone = '',
    this.preferences = '',
  });

  bool get isEmpty =>
      name.isEmpty && specialty.isEmpty && phone.isEmpty && preferences.isEmpty;

  Map<String, dynamic> toMap() => {
        'name': name,
        'specialty': specialty,
        'phone': phone,
        'preferences': preferences,
      };

  factory DoctorContact.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    return DoctorContact(
      name: (d['name'] as String?) ?? '',
      specialty: (d['specialty'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      preferences: (d['preferences'] as String?) ?? '',
    );
  }

  DoctorContact copyWith({
    String? name,
    String? specialty,
    String? phone,
    String? preferences,
  }) =>
      DoctorContact(
        name: name ?? this.name,
        specialty: specialty ?? this.specialty,
        phone: phone ?? this.phone,
        preferences: preferences ?? this.preferences,
      );
}

/// Insurance policy summary. Policy/member numbers are stored as-is; the
/// user should be aware this appears on any PDF they share.
class SuccessionInsurancePolicy {
  final String provider;
  final String planName;
  final String memberId;
  final String groupNumber;
  final String phone;
  final String notes; // copay info, prior-auth contact, pharmacy benefit, etc.

  const SuccessionInsurancePolicy({
    this.provider = '',
    this.planName = '',
    this.memberId = '',
    this.groupNumber = '',
    this.phone = '',
    this.notes = '',
  });

  bool get isEmpty =>
      provider.isEmpty &&
      planName.isEmpty &&
      memberId.isEmpty &&
      groupNumber.isEmpty &&
      phone.isEmpty &&
      notes.isEmpty;

  Map<String, dynamic> toMap() => {
        'provider': provider,
        'planName': planName,
        'memberId': memberId,
        'groupNumber': groupNumber,
        'phone': phone,
        'notes': notes,
      };

  factory SuccessionInsurancePolicy.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    return SuccessionInsurancePolicy(
      provider: (d['provider'] as String?) ?? '',
      planName: (d['planName'] as String?) ?? '',
      memberId: (d['memberId'] as String?) ?? '',
      groupNumber: (d['groupNumber'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      notes: (d['notes'] as String?) ?? '',
    );
  }

  SuccessionInsurancePolicy copyWith({
    String? provider,
    String? planName,
    String? memberId,
    String? groupNumber,
    String? phone,
    String? notes,
  }) =>
      SuccessionInsurancePolicy(
        provider: provider ?? this.provider,
        planName: planName ?? this.planName,
        memberId: memberId ?? this.memberId,
        groupNumber: groupNumber ?? this.groupNumber,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
      );
}

/// Legal / financial trusted contact (POA, attorney, accountant…).
class LegalContact {
  final String role; // "Power of Attorney", "Attorney", "Accountant", …
  final String name;
  final String phone;
  final String notes;

  const LegalContact({
    this.role = '',
    this.name = '',
    this.phone = '',
    this.notes = '',
  });

  bool get isEmpty =>
      role.isEmpty && name.isEmpty && phone.isEmpty && notes.isEmpty;

  Map<String, dynamic> toMap() => {
        'role': role,
        'name': name,
        'phone': phone,
        'notes': notes,
      };

  factory LegalContact.fromMap(Map<String, dynamic>? data) {
    final d = data ?? const <String, dynamic>{};
    return LegalContact(
      role: (d['role'] as String?) ?? '',
      name: (d['name'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      notes: (d['notes'] as String?) ?? '',
    );
  }

  LegalContact copyWith({
    String? role,
    String? name,
    String? phone,
    String? notes,
  }) =>
      LegalContact(
        role: role ?? this.role,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        notes: notes ?? this.notes,
      );
}

/// The full succession plan document.
class SuccessionPlan {
  final String elderId;

  // --- Backup caregiver ---
  final BackupCaregiver backup;

  // --- Knowledge sections (all free-text, supports multi-line) ---
  final String dailyRoutine;
  final String medicationQuirks;
  final String behavioralTriggers;
  final String calmingTechniques;
  final String communicationTips;
  final String personalHistory; // likes, dislikes, stories, comfort objects

  // --- Contacts ---
  final List<DoctorContact> doctors;
  final SuccessionInsurancePolicy insurance;
  final List<LegalContact> legalContacts;
  final String documentLocations; // where wills, DNR, birth certs live
  final String pharmacyInfo;

  // --- The "only I know" bucket ---
  final String privateKnowledge;

  // --- Audit ---
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? updatedByUid;
  final String? updatedByName;

  const SuccessionPlan({
    required this.elderId,
    this.backup = const BackupCaregiver(),
    this.dailyRoutine = '',
    this.medicationQuirks = '',
    this.behavioralTriggers = '',
    this.calmingTechniques = '',
    this.communicationTips = '',
    this.personalHistory = '',
    this.doctors = const [],
    this.insurance = const SuccessionInsurancePolicy(),
    this.legalContacts = const [],
    this.documentLocations = '',
    this.pharmacyInfo = '',
    this.privateKnowledge = '',
    this.createdAt,
    this.updatedAt,
    this.updatedByUid,
    this.updatedByName,
  });

  /// A starter plan containing only the elderId. Used before any doc exists.
  factory SuccessionPlan.empty(String elderId) =>
      SuccessionPlan(elderId: elderId);

  // ---------------------------------------------------------------------------
  // Completeness
  //
  // 12 tracked sections — each contributes 1/12 to the score.
  // Lets the UI show "Plan is 67% complete" and the PDF stamp the same,
  // so a secondary caregiver knows how much of the plan is filled in.
  // ---------------------------------------------------------------------------
  static const int _trackedSectionCount = 12;

  int get filledSectionCount {
    var n = 0;
    if (backup.isComplete) n++;
    if (dailyRoutine.trim().isNotEmpty) n++;
    if (medicationQuirks.trim().isNotEmpty) n++;
    if (behavioralTriggers.trim().isNotEmpty) n++;
    if (calmingTechniques.trim().isNotEmpty) n++;
    if (communicationTips.trim().isNotEmpty) n++;
    if (personalHistory.trim().isNotEmpty) n++;
    if (doctors.any((d) => !d.isEmpty)) n++;
    if (!insurance.isEmpty) n++;
    if (legalContacts.any((c) => !c.isEmpty)) n++;
    if (documentLocations.trim().isNotEmpty) n++;
    if (privateKnowledge.trim().isNotEmpty) n++;
    return n;
  }

  /// 0.0 – 1.0.
  double get completeness => filledSectionCount / _trackedSectionCount;

  /// Integer 0 – 100 for display.
  int get completenessPercent => (completeness * 100).round();

  /// Used by the UI to gate the share CTA with a confirmation.
  bool get hasAnyContent => filledSectionCount > 0;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory SuccessionPlan.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data();
    if (data == null) {
      // Parent path: elderProfiles/{elderId}/successionPlan/primary
      final segments = snap.reference.path.split('/');
      final elderId = segments.length >= 2 ? segments[1] : '';
      return SuccessionPlan.empty(elderId);
    }
    final segments = snap.reference.path.split('/');
    final elderId = segments.length >= 2 ? segments[1] : '';
    return SuccessionPlan(
      elderId: elderId,
      backup: BackupCaregiver.fromMap(
          data['backup'] as Map<String, dynamic>?),
      dailyRoutine: (data['dailyRoutine'] as String?) ?? '',
      medicationQuirks: (data['medicationQuirks'] as String?) ?? '',
      behavioralTriggers: (data['behavioralTriggers'] as String?) ?? '',
      calmingTechniques: (data['calmingTechniques'] as String?) ?? '',
      communicationTips: (data['communicationTips'] as String?) ?? '',
      personalHistory: (data['personalHistory'] as String?) ?? '',
      doctors: (data['doctors'] as List<dynamic>? ?? [])
          .map((e) => DoctorContact.fromMap(e as Map<String, dynamic>?))
          .toList(),
      insurance: SuccessionInsurancePolicy.fromMap(
          data['insurance'] as Map<String, dynamic>?),
      legalContacts: (data['legalContacts'] as List<dynamic>? ?? [])
          .map((e) => LegalContact.fromMap(e as Map<String, dynamic>?))
          .toList(),
      documentLocations: (data['documentLocations'] as String?) ?? '',
      pharmacyInfo: (data['pharmacyInfo'] as String?) ?? '',
      privateKnowledge: (data['privateKnowledge'] as String?) ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      updatedByUid: data['updatedByUid'] as String?,
      updatedByName: data['updatedByName'] as String?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'backup': backup.toMap(),
      'dailyRoutine': dailyRoutine,
      'medicationQuirks': medicationQuirks,
      'behavioralTriggers': behavioralTriggers,
      'calmingTechniques': calmingTechniques,
      'communicationTips': communicationTips,
      'personalHistory': personalHistory,
      'doctors': doctors.map((e) => e.toMap()).toList(),
      'insurance': insurance.toMap(),
      'legalContacts': legalContacts.map((e) => e.toMap()).toList(),
      'documentLocations': documentLocations,
      'pharmacyInfo': pharmacyInfo,
      'privateKnowledge': privateKnowledge,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (updatedByUid != null) 'updatedByUid': updatedByUid,
      if (updatedByName != null) 'updatedByName': updatedByName,
    };
  }

  SuccessionPlan copyWith({
    String? elderId,
    BackupCaregiver? backup,
    String? dailyRoutine,
    String? medicationQuirks,
    String? behavioralTriggers,
    String? calmingTechniques,
    String? communicationTips,
    String? personalHistory,
    List<DoctorContact>? doctors,
    SuccessionInsurancePolicy? insurance,
    List<LegalContact>? legalContacts,
    String? documentLocations,
    String? pharmacyInfo,
    String? privateKnowledge,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? updatedByUid,
    String? updatedByName,
  }) {
    return SuccessionPlan(
      elderId: elderId ?? this.elderId,
      backup: backup ?? this.backup,
      dailyRoutine: dailyRoutine ?? this.dailyRoutine,
      medicationQuirks: medicationQuirks ?? this.medicationQuirks,
      behavioralTriggers: behavioralTriggers ?? this.behavioralTriggers,
      calmingTechniques: calmingTechniques ?? this.calmingTechniques,
      communicationTips: communicationTips ?? this.communicationTips,
      personalHistory: personalHistory ?? this.personalHistory,
      doctors: doctors ?? this.doctors,
      insurance: insurance ?? this.insurance,
      legalContacts: legalContacts ?? this.legalContacts,
      documentLocations: documentLocations ?? this.documentLocations,
      pharmacyInfo: pharmacyInfo ?? this.pharmacyInfo,
      privateKnowledge: privateKnowledge ?? this.privateKnowledge,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedByUid: updatedByUid ?? this.updatedByUid,
      updatedByName: updatedByName ?? this.updatedByName,
    );
  }
}
