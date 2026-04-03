import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? relationshipToElder;
  final String? preferredTerm;
  final String? activeElderId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final Timestamp? lastActiveAt;

  // SOGI and Identity Fields
  final String? sexualOrientation;
  final String? genderIdentity;
  final String? preferredPronouns;
  final String? userGoals;
  final String? preferredName;

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
    this.lastActiveAt,
    this.sexualOrientation,
    this.genderIdentity,
    this.preferredPronouns,
    this.userGoals,
    this.preferredName,
  });

  /// Human-readable relative time label for [lastActiveAt].
  String get lastActiveLabel {
    if (lastActiveAt == null) return '';
    final now = DateTime.now();
    final active = lastActiveAt!.toDate();
    final diff = now.difference(active);
    if (diff.inMinutes < 1) return 'Active now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return 'Active ${DateFormat('MMM d').format(active)}';
  }

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for UserProfile ${snapshot.id}');
    }
    return UserProfile(
      uid: snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      avatarUrl: data['avatarUrl'] as String?,
      dateOfBirth: data['dateOfBirth'] as String?,
      relationshipToElder: data['relationshipToElder'] as String?,
      preferredTerm: data['preferredTerm'] as String?,
      activeElderId: data['activeElderId'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      sexualOrientation: data['sexualOrientation'] as String?,
      genderIdentity: data['genderIdentity'] as String?,
      preferredPronouns: data['preferredPronouns'] as String?,
      // FIX: userGoals was missing from fromFirestore — it existed in
      // the constructor, toFirestore, and copyWith but was never read back
      // from Firestore, so it always returned null after any reload.
      userGoals: data['userGoals'] as String?,
      preferredName: data['preferredName'] as String?,
      lastActiveAt: data['lastActiveAt'] as Timestamp?,
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
      if (preferredTerm != null) 'preferredTerm': preferredTerm,
      if (activeElderId != null) 'activeElderId': activeElderId,
      if (createdAt != null) 'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
      if (sexualOrientation != null) 'sexualOrientation': sexualOrientation,
      if (genderIdentity != null) 'genderIdentity': genderIdentity,
      if (preferredPronouns != null) 'preferredPronouns': preferredPronouns,
      if (userGoals != null) 'userGoals': userGoals,
      if (preferredName != null) 'preferredName': preferredName,
      if (lastActiveAt != null) 'lastActiveAt': lastActiveAt,
    };
  }

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
    Timestamp? lastActiveAt,
    String? sexualOrientation,
    String? genderIdentity,
    String? preferredPronouns,
    String? userGoals,
    String? preferredName,
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
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      genderIdentity: genderIdentity ?? this.genderIdentity,
      preferredPronouns: preferredPronouns ?? this.preferredPronouns,
      userGoals: userGoals ?? this.userGoals,
      preferredName: preferredName ?? this.preferredName,
    );
  }
}
