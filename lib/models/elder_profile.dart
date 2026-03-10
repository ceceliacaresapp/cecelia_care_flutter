import 'package:cloud_firestore/cloud_firestore.dart';

class ElderProfile {
  final String id; // Document ID from Firestore
  final String profileName;
  final String
  primaryAdminUserId; // UID of the user who created/owns this profile
  final List<String>
  caregiverUserIds; // UIDs of all users with access (includes primaryAdminUserId)
  final String dateOfBirth;
  final List<String> allergies;
  final String dietaryRestrictions;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  int? priorityIndex; // Added for reordering
  final String? preferredName; // New field
  // New SOGI fields for ElderProfile
  final String? sexualOrientation;
  final String? genderIdentity;
  final String? preferredPronouns;

  // NEW: Emergency Contact fields
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelationship;  

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
    this.preferredName, // Add to constructor
    this.sexualOrientation, // Add to constructor
    this.genderIdentity, // Add to constructor
    this.preferredPronouns, // Add to constructor
    // NEW: Add to constructor
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,    
  });

  // Updated fromFirestore to match the signature required by .withConverter()
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
          data['primaryAdminUserId'] as String? ??
          '', // Should ideally not be empty
      caregiverUserIds: List<String>.from(
        data['caregiverUserIds'] as List<dynamic>? ?? [],
      ),
      dateOfBirth: data['dateOfBirth'] as String? ?? '',
      allergies: List<String>.from(data['allergies'] as List<dynamic>? ?? []),
      dietaryRestrictions: data['dietaryRestrictions'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      priorityIndex: data['priorityIndex'] as int? ??
          9999, // Default to a high number if not set, so new items go to bottom
      preferredName: data['preferredName'] as String?, // Read new field
      // Read new SOGI fields from Firestore
      sexualOrientation: data['sexualOrientation'] as String?,
      genderIdentity: data['genderIdentity'] as String?,
      preferredPronouns: data['preferredPronouns'] as String?,
      // NEW: Read emergency contact fields from Firestore
      emergencyContactName: data['emergencyContactName'] as String?,
      emergencyContactPhone: data['emergencyContactPhone'] as String?,
      emergencyContactRelationship: data['emergencyContactRelationship'] as String?,      
    );
  }

  // Renamed toMap to toFirestore and ensured it returns Map<String, Object?>
  Map<String, Object?> toFirestore() {
    return {
      'profileName': profileName,
      'primaryAdminUserId': primaryAdminUserId,
      'caregiverUserIds': caregiverUserIds,
      'dateOfBirth': dateOfBirth,
      'allergies': allergies,
      'dietaryRestrictions': dietaryRestrictions,
      // id is not included here as it's the document ID
      'createdAt':
          createdAt ??
          FieldValue.serverTimestamp(), // Sets server timestamp if createdAt is null on creation
      'updatedAt':
          FieldValue.serverTimestamp(), // Always sets/updates server timestamp on save
      if (priorityIndex != null) 'priorityIndex': priorityIndex,
      if (preferredName != null) 'preferredName': preferredName, // Add new field
      // Add new SOGI fields to Firestore map
      if (sexualOrientation != null) 'sexualOrientation': sexualOrientation,
      if (genderIdentity != null) 'genderIdentity': genderIdentity,
      if (preferredPronouns != null) 'preferredPronouns': preferredPronouns,
      // NEW: Add emergency contact fields to Firestore map
      if (emergencyContactName != null) 'emergencyContactName': emergencyContactName,
      if (emergencyContactPhone != null) 'emergencyContactPhone': emergencyContactPhone,
      if (emergencyContactRelationship != null) 'emergencyContactRelationship': emergencyContactRelationship,      
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
    String? preferredName, // Add to copyWith
    String? sexualOrientation, // Add to copyWith
    String? genderIdentity, // Add to copyWith
    String? preferredPronouns, // Add to copyWith
    // NEW: Add to copyWith
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,    
  }) {
    return ElderProfile(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      primaryAdminUserId: primaryAdminUserId ?? this.primaryAdminUserId,
      caregiverUserIds: caregiverUserIds ?? this.caregiverUserIds,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      allergies: allergies ?? this.allergies,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      preferredName: preferredName ?? this.preferredName, // Assign in copyWith
      // Assign new SOGI fields in copyWith
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      genderIdentity: genderIdentity ?? this.genderIdentity,
      preferredPronouns: preferredPronouns ?? this.preferredPronouns,
      // NEW: Assign emergency contact fields in copyWith
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,      
    );
  }
}
