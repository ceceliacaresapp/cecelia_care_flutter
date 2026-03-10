import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? dateOfBirth; // Store as YYYY-MM-DD or use DateTime and convert
  final String? relationshipToElder; // New field
  final String? preferredTerm; // Field for user's preferred term for "Elder"
  final String? activeElderId; // ID of the currently active elder for this user
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  // SOGI and Identity Fields
  final String? sexualOrientation;
  final String? genderIdentity;
  final String? preferredPronouns;
  final String? userGoals; // New field for questionnaire response  
  final String? preferredName; // New field for preferred name

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.dateOfBirth,
    this.relationshipToElder,
    this.preferredTerm,
    this.activeElderId,
    this.createdAt,
    this.updatedAt,
    // SOGI and Identity Fields in constructor
    this.sexualOrientation,
    this.genderIdentity,
    this.preferredPronouns,
    this.userGoals, // Add to constructor

    this.preferredName, // Add to constructor
  });

  // Factory constructor to create a UserProfile from a Firestore document
  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options, // Made options an optional positional parameter
  ]) {
    final data = snapshot.data();
    // It's good practice to check for null data, though with converters and strong typing,
    // this might be less critical if your rules/app logic ensures data exists.
    // However, for robustness, especially if documents might be incomplete:
    if (data == null) {
      throw StateError('Missing data for UserProfile ${snapshot.id}');
    }
    return UserProfile(
      uid: snapshot.id, // Use the document ID as uid
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      dateOfBirth: data['dateOfBirth'] as String?,
      relationshipToElder: data['relationshipToElder'] as String?,
      preferredTerm: data['preferredTerm'] as String?,
      activeElderId: data['activeElderId'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      // Read SOGI and Identity Fields from Firestore
      sexualOrientation: data['sexualOrientation'] as String?,
      genderIdentity: data['genderIdentity'] as String?,
      preferredPronouns: data['preferredPronouns'] as String?,
      preferredName: data['preferredName'] as String?, // Read new field
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (relationshipToElder != null)
        'relationshipToElder': relationshipToElder,
      if (preferredTerm != null)
        'preferredTerm': preferredTerm,
      if (activeElderId != null)
        'activeElderId': activeElderId,
      if (createdAt != null) 'createdAt': createdAt,
      'updatedAt':
          FieldValue.serverTimestamp(), // Always update 'updatedAt' on save
      // Add SOGI and Identity Fields to Firestore map
      if (sexualOrientation != null) 'sexualOrientation': sexualOrientation,
      if (genderIdentity != null) 'genderIdentity': genderIdentity,
      if (preferredPronouns != null) 'preferredPronouns': preferredPronouns,
      if (userGoals != null) 'userGoals': userGoals, // Add new field      
      if (preferredName != null) 'preferredName': preferredName, // Add new field
    };
  }

  // Optional: A copyWith method can be useful for updating instances
  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarUrl,
    String? dateOfBirth,
    String? relationshipToElder,
    String? preferredTerm,
    String? activeElderId,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    // SOGI and Identity Fields in copyWith
    String? sexualOrientation,
    String? genderIdentity,
    String? preferredPronouns,
    String? userGoals,    
    String? preferredName, // Add to copyWith
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      relationshipToElder: relationshipToElder ?? this.relationshipToElder,
      preferredTerm: preferredTerm ?? this.preferredTerm,
      activeElderId: activeElderId ?? this.activeElderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Assign SOGI and Identity Fields in copyWith
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      genderIdentity: genderIdentity ?? this.genderIdentity,
      preferredPronouns: preferredPronouns ?? this.preferredPronouns,
      userGoals: userGoals ?? this.userGoals,      
      preferredName: preferredName ?? this.preferredName, // Assign in copyWith
    );
  }
}