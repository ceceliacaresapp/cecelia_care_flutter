import 'package:cloud_firestore/cloud_firestore.dart';

class MoodEntry {
  final String firestoreId; // Document ID from Firestore
  final String? mood; // e.g., "Happy", "Anxious", or custom mood text
  final int? intensity; // Optional, 1-5
  final String? note; // Optional
  final DateTime? stamp; // The actual time of the mood logging
  final String? time; // Formatted time string for display (e.g., "HH:mm")
  final String? date; // Formatted date string (e.g., "YYYY-MM-DD")
  final String? elderId;
  final String loggedByUserId;
  final String loggedBy; // Display name of the user who logged the entry
  final Timestamp createdAt;
  final Timestamp updatedAt;

  MoodEntry({
    required this.firestoreId,
    this.mood,
    this.intensity,
    this.note,
    this.stamp, // Made optional
    this.time,  // Made optional
    this.date,  // Made optional
    this.elderId, // Made optional
    required this.loggedByUserId,
    required this.loggedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [MoodEntry] from a standard JSON map.
  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      firestoreId: json['firestoreId'] as String,
      mood: json['mood'] as String?,
      intensity: json['intensity'] as int?,
      note: json['note'] as String?,
      stamp: (json['stamp'] as Timestamp?)?.toDate(),
      time: json['time'] as String?,
      date: json['date'] as String?,
      elderId: json['elderId'] as String?,
      loggedByUserId: json['loggedByUserId'] as String,
      loggedBy: json['loggedBy'] as String,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  /// Converts this [MoodEntry] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'mood': mood,
      'intensity': intensity,
      'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null,
      'time': time,
      'date': date,
      'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Factory constructor to create a MoodEntry from a Firestore document
  factory MoodEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _, // match Firestore converter signature
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Missing data for MoodEntry from snapshot ${snapshot.id}',
      );
    }

    return MoodEntry(
      firestoreId: snapshot.id,
      mood: data['mood'] as String? ?? 'Unknown',
      intensity: data['intensity'] as int?,
      note: data['note'] as String?,
      stamp: (data['stamp'] as Timestamp?)?.toDate(),
      time: data['time'] as String?,
      date: data['date'] as String?,
      elderId: data['elderId'] as String?,
      loggedByUserId: data['loggedByUserId'] as String? ?? '',
      loggedBy: data['loggedByDisplayName'] as String? ?? 'Unknown User',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Converts this instance to a Map suitable for writing to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'mood': mood,
      if (intensity != null) 'intensity': intensity,
      if (note != null) 'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null,
      if (time != null) 'time': time,
      if (date != null) 'date': date,
      if (elderId != null) 'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Alias for `intensity` to match form code expectations.
  int? get moodLevel => intensity;
}
