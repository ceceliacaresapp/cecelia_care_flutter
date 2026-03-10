import 'package:cloud_firestore/cloud_firestore.dart';

class VitalEntry {
  final String firestoreId; // Document ID from Firestore
  final String vitalType; // e.g., "BP", "HR", "Temp"
  final String? value; // The actual reading, e.g., "120/80", "98.6"
  final String? unit; // e.g., "mmHg", "°F"
  final String? note; // Optional
  final DateTime? stamp; // The actual time of the vital logging
  final String?
  time; // Formatted time string of when the log was made (e.g., "HH:mm")
  final String? date; // Formatted date string (e.g., "YYYY-MM-DD")
  final String? elderId;
  final String loggedByUserId;
  final String loggedBy; // Display name of the user who logged the entry
  final Timestamp createdAt;
  final Timestamp updatedAt;

  VitalEntry({
    required this.firestoreId,
    required this.vitalType,
    this.value,
    this.unit,
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

  /// Creates a [VitalEntry] from a standard JSON map.
  ///
  /// Assumes the [json] map contains keys corresponding to the [VitalEntry]
  /// fields, with appropriate types.
  /// - 'stamp', 'createdAt', 'updatedAt' are expected as Timestamps if not null.
  factory VitalEntry.fromJson(Map<String, dynamic> json) {
    return VitalEntry(
      firestoreId: json['firestoreId'] as String,
      vitalType: json['vitalType'] as String,
      value: json['value'] as String?,
      unit: json['unit'] as String?,
      note: json['note'] as String?,
      stamp: (json['stamp'] as Timestamp?)?.toDate(), // Expect Timestamp, convert to DateTime
      time: json['time'] as String?,
      date: json['date'] as String?,
      elderId: json['elderId'] as String?,
      loggedByUserId: json['loggedByUserId'] as String,
      loggedBy: json['loggedBy'] as String,
      createdAt: json['createdAt'] as Timestamp, // Expect Timestamp
      updatedAt: json['updatedAt'] as Timestamp, // Expect Timestamp
    );
  }

  /// Converts this [VitalEntry] instance to a JSON map.
  ///
  /// Converts DateTime fields back to Timestamps for consistency.
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'vitalType': vitalType,
      'value': value,
      'unit': unit,
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

  // Factory constructor to create a VitalEntry from a Firestore document
  factory VitalEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _, // Added to match Firestore converter signature
  ]) {
    final data = snapshot.data(); // Data from the specific VitalEntry document
    if (data == null) {
      throw StateError(
        'Missing data for VitalEntry from snapshot ${snapshot.id}',
      );
    }

    return VitalEntry(
      firestoreId: snapshot.id, // The ID of the JournalEntry document
      vitalType: data['vitalType'] as String? ?? 'Unknown',
      value: data['value'] as String?,
      unit: data['unit'] as String?,
      note: data['note'] as String?,
      stamp: (data['stamp'] as Timestamp?)?.toDate(), // From 'stamp' field
      time: data['time'] as String?, // From 'time' field
      date: data['date'] as String?, // From 'date' field
      elderId: data['elderId'] as String?,
      loggedByUserId: data['loggedByUserId'] as String? ?? '',
      loggedBy: data['loggedByDisplayName'] as String? ?? 'Unknown User', // From 'loggedByDisplayName'
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Method to convert VitalEntry instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'vitalType': vitalType,
      'value': value,
      'unit': unit,
      if (note != null) 'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null, // Convert DateTime back to Timestamp
      if (time != null) 'time': time,
      if (date != null) 'date': date,
      if (elderId != null) 'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt':
          createdAt, // Should be FieldValue.serverTimestamp() on creation if using this method
      'updatedAt': FieldValue.serverTimestamp(), // Always update on save
    };
  }
}
