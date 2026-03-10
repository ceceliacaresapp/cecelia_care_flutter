import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityEntry {
  final String firestoreId; // Document ID from Firestore
  final String activityType;
  final String? duration; // Optional in form, so nullable
  final String? assistanceLevel; // Optional in form, so nullable
  final String? note; // Optional in form, so nullable
  final DateTime? stamp; // The actual time of the activity
  final String? time; // Formatted time string for display (e.g., "HH:mm")
  final String? date; // Formatted date string (e.g., "YYYY-MM-DD")
  final String? elderId;
  final String? loggedByUserId;
  final String loggedBy; // Display name of the user who logged the entry
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ActivityEntry({
    required this.firestoreId,
    required this.activityType,
    this.duration,
    this.assistanceLevel,
    this.note,
    this.stamp, // Made optional to match field type
    this.time,  // Made optional
    this.date,  // Made optional
    this.elderId, // Made optional
    this.loggedByUserId, // Made optional
    required this.loggedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [ActivityEntry] from a JSON map.
  ///
  /// Assumes the [json] map contains keys corresponding to the [ActivityEntry]
  /// fields, with appropriate types (e.g., Timestamps for date/time fields if not strings).
  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    return ActivityEntry(
      firestoreId: json['firestoreId'] as String,
      activityType: json['activityType'] as String,
      duration: json['duration'] as String?,
      assistanceLevel: json['assistanceLevel'] as String?,
      note: json['note'] as String?,
      // Assumes 'stamp' in JSON is a Timestamp, converts to DateTime
      stamp: (json['stamp'] as Timestamp?)?.toDate(),
      time: json['time'] as String?,
      date: json['date'] as String?,
      elderId: json['elderId'] as String?,
      loggedByUserId: json['loggedByUserId'] as String?,
      loggedBy: json['loggedBy'] as String,
      // Assumes 'createdAt' and 'updatedAt' in JSON are Timestamps
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  /// Converts this [ActivityEntry] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'activityType': activityType,
      'duration': duration,
      'assistanceLevel': assistanceLevel,
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

  // Updated fromFirestore to match Firestore converter signature and use fromJson
  factory ActivityEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _,
  ]) {
    final data = snapshot.data(); // Data from the specific ActivityEntry document
    if (data == null) {
      throw StateError(
        'Missing data for ActivityEntry from snapshot ${snapshot.id}',
      );
    }

    return ActivityEntry(
      firestoreId: snapshot.id, // The ID of the JournalEntry document
      activityType: data['activityType'] as String? ?? 'Unknown Activity',
      duration: data['duration'] as String?,
      assistanceLevel: data['assistanceLevel'] as String?,
      note: data['note'] as String?,
      stamp: (data['stamp'] as Timestamp?)?.toDate(), // From 'stamp' field
      time: data['time'] as String?, // From 'time' field
      date: data['date'] as String?, // From 'date' field
      elderId: data['elderId'] as String?,
      loggedByUserId: data['loggedByUserId'] as String?,
      loggedBy: data['loggedByDisplayName'] as String? ?? 'Unknown User', // From 'loggedByDisplayName'
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // The fromJson factory might be removed if not used elsewhere,
  // as fromFirestore now directly calls the constructor.
  // factory ActivityEntry.fromJson(Map<String, dynamic> json) { ... }

  // Method to convert ActivityEntry instance to a Map for Firestore
  // This is useful if you ever need to create/update entries directly using the model
  // However, your forms are already creating the Map payload.
  Map<String, dynamic> toFirestore() {
    return {
      'activityType': activityType,
      if (duration != null) 'duration': duration,
      if (assistanceLevel != null) 'assistanceLevel': assistanceLevel,
      if (note != null) 'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null, // Convert DateTime back to Timestamp if not null
      if (time != null) 'time': time,
      if (date != null) 'date': date,
      if (elderId != null) 'elderId': elderId,
      if (loggedByUserId != null) 'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt':
          createdAt, // Should be FieldValue.serverTimestamp() on creation
      'updatedAt': FieldValue.serverTimestamp(), // Always update on save
    };
  }
}
