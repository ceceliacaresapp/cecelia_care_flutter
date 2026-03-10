import 'package:cloud_firestore/cloud_firestore.dart';

class PainEntry {
  final String firestoreId; // Document ID from Firestore
  final String? location;
  final int? intensity; // 0-10
  final String? description; // Could be a chip option or custom text
  final String? note; // Optional
  final DateTime? stamp; // The actual time of the pain logging
  final String? time; // Formatted time string for display (e.g., "HH:mm")
  final String? date; // Formatted date string (e.g., "YYYY-MM-DD")
  final String elderId;
  final String loggedByUserId;
  final String loggedBy; // Display name of the user who logged the entry
  final Timestamp createdAt;
  final Timestamp updatedAt;

  PainEntry({
    required this.firestoreId,
    this.location,
    this.intensity,
    this.description,
    this.note,
    this.stamp, // Made optional
    this.time,  // Made optional
    this.date,  // Made optional
    required this.elderId,
    required this.loggedByUserId,
    required this.loggedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [PainEntry] from a standard JSON map.
  ///
  /// Assumes the [json] map contains keys corresponding to the [PainEntry]
  /// fields, with appropriate types.
  /// - 'stamp', 'createdAt', 'updatedAt' are expected as Timestamps if not null.
  /// - 'intensity' is expected as an int if not null.
  factory PainEntry.fromJson(Map<String, dynamic> json) {
    return PainEntry(
      firestoreId: json['firestoreId'] as String,
      location: json['location'] as String?,
      intensity: json['intensity'] as int?,
      description: json['description'] as String?,
      note: json['note'] as String?,
      stamp: (json['stamp'] as Timestamp?)?.toDate(), // Expect Timestamp, convert to DateTime
      time: json['time'] as String?,
      date: json['date'] as String?,
      elderId: json['elderId'] as String,
      loggedByUserId: json['loggedByUserId'] as String,
      loggedBy: json['loggedBy'] as String,
      createdAt: json['createdAt'] as Timestamp, // Expect Timestamp
      updatedAt: json['updatedAt'] as Timestamp, // Expect Timestamp
    );
  }

  /// Converts this [PainEntry] instance to a JSON map.
  ///
  /// Converts DateTime fields back to Timestamps for consistency.
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'location': location,
      'intensity': intensity,
      'description': description,
      'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null, // Convert DateTime back to Timestamp
      'time': time,
      'date': date,
      'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Factory constructor to create a PainEntry from a Firestore document
  factory PainEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _, // Added to match Firestore converter signature
  ]) {
    final data = snapshot.data(); // Data from the specific PainEntry document
    if (data == null) {
      throw StateError(
        'Missing data for PainEntry from snapshot ${snapshot.id}',
      );
    }

    return PainEntry(
      firestoreId: snapshot.id, // The ID of the JournalEntry document
      location: data['location'] as String?,
      intensity: data['intensity'] as int?,
      description: data['description'] as String?,
      note: data['note'] as String?,
      stamp: (data['stamp'] as Timestamp?)?.toDate(), // From 'stamp' field
      time: data['time'] as String?, // From 'time' field
      date: data['date'] as String?, // From 'date' field
      elderId: data['elderId'] as String? ?? '',
      loggedByUserId: data['loggedByUserId'] as String? ?? '',
      loggedBy: data['loggedByDisplayName'] as String? ?? 'Unknown User', // From 'loggedByDisplayName'
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Method to convert PainEntry instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'location': location,
      'intensity': intensity,
      'description': description,
      if (note != null) 'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null, // Convert DateTime back to Timestamp
      if (time != null) 'time': time,
      if (date != null) 'date': date,
      'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt':
          createdAt, // Should be FieldValue.serverTimestamp() on creation if using this method
      'updatedAt': FieldValue.serverTimestamp(), // Always update on save
    };
  }
}
