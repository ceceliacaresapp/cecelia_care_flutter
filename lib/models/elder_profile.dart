import 'package:cloud_firestore/cloud_firestore.dart';

class ElderProfile {
  final String id;
  final String profileName;
  final String primaryAdminUserId;
  final List<String> caregiverUserIds;
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

  // NEW: Profile photo URL stored in Firebase Storage and persisted here.
  // Null means no photo has been uploaded yet — UI falls back to initials.
  final String? photoUrl;

  ElderProfile({
    required this.id,
    required this.profileName,
    required this.primaryAdminUserId,
    required this.caregiverUserIds,
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
  });

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
      primaryAdminUserId:
          data['primaryAdminUserId'] as String? ?? '',
      caregiverUserIds: List<String>.from(
        data['caregiverUserIds'] as List<dynamic>? ?? [],
      ),
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      allergies:
          List<String>.from(data['allergies'] as List<dynamic>? ?? []),
      dietaryRestrictions:
          data['dietaryRestrictions'] as String? ?? '',
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
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'profileName': profileName,
      'primaryAdminUserId': primaryAdminUserId,
      'caregiverUserIds': caregiverUserIds,
      'dateOfBirth': dateOfBirth,
      'allergies': allergies,
      'dietaryRestrictions': dietaryRestrictions,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (priorityIndex != null) 'priorityIndex': priorityIndex,
      if (preferredName != null) 'preferredName': preferredName,
      if (sexualOrientation != null)
        'sexualOrientation': sexualOrientation,
      if (genderIdentity != null) 'genderIdentity': genderIdentity,
      if (preferredPronouns != null)
        'preferredPronouns': preferredPronouns,
      if (emergencyContactName != null)
        'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null)
        'emergencyContactPhone': emergencyContactPhone,
      if (emergencyContactRelationship != null)
        'emergencyContactRelationship': emergencyContactRelationship,
      // Always write photoUrl — null clears a previously set photo.
      'photoUrl': photoUrl,
    };
  }

  ElderProfile copyWith({
    String? id,
    String? profileName,
    String? primaryAdminUserId,
    List<String>? caregiverUserIds,
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
  }) {
    return ElderProfile(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      primaryAdminUserId:
          primaryAdminUserId ?? this.primaryAdminUserId,
      caregiverUserIds: caregiverUserIds ?? this.caregiverUserIds,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions:
          dietaryRestrictions ?? this.dietaryRestrictions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      preferredName: preferredName ?? this.preferredName,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      genderIdentity: genderIdentity ?? this.genderIdentity,
      preferredPronouns: preferredPronouns ?? this.preferredPronouns,
      emergencyContactName:
          emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ??
          this.emergencyContactRelationship,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
