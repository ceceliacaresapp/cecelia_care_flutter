import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarEvent {
  final String?
  id; // Document ID from Firestore, nullable if creating a new one
  final String title;
  final String? notes; // Used for description/notes
  final Timestamp startDateTime; // Storing as Timestamp
  final Timestamp?
  endDateTime; // Storing as Timestamp, nullable for single-point events
  final bool allDay;
  final String elderId; // Links to the ElderProfile
  final String
  eventType; // e.g., 'appointment', 'medication_reminder', 'social', 'other'
  final String createdBy; // UID of the user who created the event
  final String? createdByDisplayName; // Optional: For easier display
  final Timestamp? createdAt; // Firestore server timestamp for creation
  final Timestamp? updatedAt; // Firestore server timestamp for updates
  final String? recurrenceRule; // 'daily', 'weekly', 'monthly', or null
  final String? recurrenceParentId; // links instances back to the original event
  final Timestamp? recurrenceEndDate; // how far out to generate instances

  CalendarEvent({
    this.id,
    required this.title,
    this.notes,
    required this.startDateTime,
    this.endDateTime,
    required this.allDay,
    required this.elderId,
    required this.eventType,
    required this.createdBy,
    this.createdByDisplayName,
    this.createdAt,
    this.updatedAt,
    this.recurrenceRule,
    this.recurrenceParentId,
    this.recurrenceEndDate,
  });

  // Updated fromFirestore to use an intermediate fromJson factory
  factory CalendarEvent.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _, // Parameter name changed to _ to indicate it's unused
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Calendar event data is null for doc ID: ${snapshot.id}',
      );
    }
    final Map<String, dynamic> jsonData = Map.from(data);
    jsonData['id'] = snapshot.id; // Add 'id' to the map
    return CalendarEvent.fromJson(jsonData); // Call the new fromJson
  }

  // New factory constructor to create a CalendarEvent from a JSON map (expected to include 'id')
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String?, // Expect 'id' from the json map
      title: json['title'] as String? ?? 'Untitled Event',
      notes: json['notes'] as String?,
      startDateTime:
          json['startDateTime'] as Timestamp? ??
          Timestamp.now(), // Provide a default if critical
      endDateTime: json['endDateTime'] as Timestamp?,
      allDay: json['allDay'] as bool? ?? false,
      elderId: json['elderId'] as String, // elderId should be non-nullable
      eventType: json['eventType'] as String? ?? 'other',
      createdBy:
          json['createdBy'] as String, // createdBy should be non-nullable
      createdByDisplayName: json['createdByDisplayName'] as String?,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
      recurrenceRule: json['recurrenceRule'] as String?,
      recurrenceParentId: json['recurrenceParentId'] as String?,
      recurrenceEndDate: json['recurrenceEndDate'] as Timestamp?,
    );
  }

  // Renamed toMap to toFirestore and ensured it returns Map<String, Object?>
  Map<String, Object?> toFirestore() {
    return {
      // 'id' is not included here as it's the document ID, not part of the document data itself
      'title': title,
      'notes': notes,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'allDay': allDay,
      'elderId': elderId,
      'eventType': eventType,
      'createdBy': createdBy,
      'createdByDisplayName': createdByDisplayName,
      'createdAt':
          createdAt ??
          FieldValue.serverTimestamp(), // Sets server timestamp if createdAt is null on creation
      'updatedAt':
          FieldValue.serverTimestamp(), // Always sets/updates server timestamp on save
      'recurrenceRule': recurrenceRule,
      'recurrenceParentId': recurrenceParentId,
      'recurrenceEndDate': recurrenceEndDate,
    };
  }

  CalendarEvent copyWith({
    String? id, // Allow id to be explicitly passed for copying
    String? title,
    String? notes,
    Timestamp? startDateTime,
    Timestamp? endDateTime,
    bool? allDay,
    String? elderId,
    String? eventType,
    String? createdBy,
    String? createdByDisplayName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? recurrenceRule,
    String? recurrenceParentId,
    Timestamp? recurrenceEndDate,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      allDay: allDay ?? this.allDay,
      elderId: elderId ?? this.elderId,
      eventType: eventType ?? this.eventType,
      createdBy: createdBy ?? this.createdBy,
      createdByDisplayName: createdByDisplayName ?? this.createdByDisplayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      recurrenceParentId: recurrenceParentId ?? this.recurrenceParentId,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
    );
  }
}
