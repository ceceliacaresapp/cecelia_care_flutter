import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/models/caregiver_role.dart';

class ElderProfile {
  final String id;
  final String profileName;
  final String primaryAdminUserId;
  final List<String> caregiverUserIds;

  // NEW: maps UID → role string ("caregiver" | "viewer").
  // primaryAdminUserId is always "admin" and is NOT stored here — it is
  // derived from primaryAdminUserId at runtime via roleForUser().
  // Kept as Map<String,String> (not the enum) so Firestore round-trips cleanly.
  final Map<String, String> caregiverRoles;

  final String dateOfBirth;
  final List<String> allergies;
  final String dietaryRestrictions;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  int? priorityIndex;
  final String? preferredName;
  final String? sexualOrientation;
  final String? genderIdentity;
  final String? preferredPronouns;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;
  final String? photoUrl;

  /// Sensory preference matrix — keys: light, sound, texture, foodTemp,
  /// smell, touch. Values are free-text preferences set by caregivers.
  final Map<String, String> sensoryPreferences;

  ElderProfile({
    required this.id,
    required this.profileName,
    required this.primaryAdminUserId,
    required this.caregiverUserIds,
    this.caregiverRoles = const {},
    this.dateOfBirth = '',
    this.allergies = const [],
    this.dietaryRestrictions = '',
    this.createdAt,
    this.updatedAt,
    this.priorityIndex,
    this.preferredName,
    this.sexualOrientation,
    this.genderIdentity,
    this.preferredPronouns,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
    this.photoUrl,
    this.sensoryPreferences = const {},
  });

  // ---------------------------------------------------------------------------
  // Role helper
  // ---------------------------------------------------------------------------

  /// Returns the [CaregiverRole] for [uid] on this elder profile.
  ///
  /// Logic:
  ///   1. uid == primaryAdminUserId → admin
  ///   2. uid in caregiverRoles → caregiver or viewer (explicit assignment)
  ///   3. uid in caregiverUserIds but not in caregiverRoles → caregiver
  ///      (backwards-compat: existing invites before roles were added)
  ///   4. otherwise → unknown
  CaregiverRole roleForUser(String? uid) {
    if (uid == null || uid.isEmpty) return CaregiverRole.unknown;
    if (uid == primaryAdminUserId) return CaregiverRole.admin;
    if (caregiverRoles.containsKey(uid)) {
      return CaregiverRoleX.fromString(caregiverRoles[uid]);
    }
    if (caregiverUserIds.contains(uid)) return CaregiverRole.caregiver;
    return CaregiverRole.unknown;
  }

  // ---------------------------------------------------------------------------
  // Firestore serialisation
  // ---------------------------------------------------------------------------

  factory ElderProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for ElderProfile ${snapshot.id}');
    }
    return ElderProfile(
      id: snapshot.id,
      profileName: data['profileName'] as String? ?? 'Unnamed Profile',
      primaryAdminUserId: data['primaryAdminUserId'] as String? ?? '',
      caregiverUserIds: List<String>.from(
        data['caregiverUserIds'] as List<dynamic>? ?? [],
      ),
      caregiverRoles: Map<String, String>.from(
        (data['caregiverRoles'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      ),
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      allergies:
          List<String>.from(data['allergies'] as List<dynamic>? ?? []),
      dietaryRestrictions: data['dietaryRestrictions'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      priorityIndex: data['priorityIndex'] as int? ?? 9999,
      preferredName: data['preferredName'] as String?,
      sexualOrientation: data['sexualOrientation'] as String?,
      genderIdentity: data['genderIdentity'] as String?,
      preferredPronouns: data['preferredPronouns'] as String?,
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      emergencyContactRelationship:
          data['emergencyContactRelationship'] as String?,
      photoUrl: data['photoUrl'] as String?,
      sensoryPreferences: Map<String, String>.from(
        (data['sensoryPreferences'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      ),
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'profileName': profileName,
      'primaryAdminUserId': primaryAdminUserId,
      'caregiverUserIds': caregiverUserIds,
      'caregiverRoles': caregiverRoles,
      'dateOfBirth': dateOfBirth,
      'allergies': allergies,
      'dietaryRestrictions': dietaryRestrictions,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (priorityIndex != null) 'priorityIndex': priorityIndex,
      if (preferredName != null) 'preferredName': preferredName,
      if (sexualOrientation != null) 'sexualOrientation': sexualOrientation,
      if (genderIdentity != null) 'genderIdentity': genderIdentity,
      if (preferredPronouns != null) 'preferredPronouns': preferredPronouns,
      if (emergencyContactName != null)
        'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null)
        'emergencyContactPhone': emergencyContactPhone,
      if (emergencyContactRelationship != null)
        'emergencyContactRelationship': emergencyContactRelationship,
      'photoUrl': photoUrl,
      if (sensoryPreferences.isNotEmpty)
        'sensoryPreferences': sensoryPreferences,
    };
  }

  ElderProfile copyWith({
    String? id,
    String? profileName,
    String? primaryAdminUserId,
    List<String>? caregiverUserIds,
    Map<String, String>? caregiverRoles,
    String? dateOfBirth,
    List<String>? allergies,
    String? dietaryRestrictions,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    int? priorityIndex,
    String? preferredName,
    String? sexualOrientation,
    String? genderIdentity,
    String? preferredPronouns,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    String? photoUrl,
    Map<String, String>? sensoryPreferences,
  }) {
    return ElderProfile(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      primaryAdminUserId: primaryAdminUserId ?? this.primaryAdminUserId,
      caregiverUserIds: caregiverUserIds ?? this.caregiverUserIds,
      caregiverRoles: caregiverRoles ?? this.caregiverRoles,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      preferredName: preferredName ?? this.preferredName,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      genderIdentity: genderIdentity ?? this.genderIdentity,
      preferredPronouns: preferredPronouns ?? this.preferredPronouns,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      photoUrl: photoUrl ?? this.photoUrl,
      sensoryPreferences: sensoryPreferences ?? this.sensoryPreferences,
    );
  }
}
