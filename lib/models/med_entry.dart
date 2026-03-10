import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationEntry {
  final String firestoreId; // Document ID from Firestore
  final String name; 
  final String rxCui; // RxNorm ID for interaction lookup, now non-nullable
  final String? dose;
  final String? time; // Optional, stored as "HH:mm"
  final bool taken;
  final String date; // "YYYY-MM-DD"
  final String elderId;
  final String loggedByUserId;
  final String? loggedByDisplayName;
  final String? loggedByUserAvatarUrl; // Optional
  final Timestamp stamp; // Actual timestamp of the event/logging
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String? timelineEntryId; // Optional link to a timeline summary document

  MedicationEntry({
    required this.firestoreId,
    required this.name,
    required this.rxCui, // Made required in constructor
    this.dose,
    this.time,
    required this.taken,
    required this.date,
    required this.elderId,
    required this.loggedByUserId,
    this.loggedByDisplayName,
    this.loggedByUserAvatarUrl,
    required this.stamp,
    required this.createdAt,
    required this.updatedAt,
    this.timelineEntryId,
  });

  /// Convenience getter to access firestoreId as 'id'.
  String get id => firestoreId;

  /// Creates a MedicationEntry from a Firestore document snapshot.
  factory MedicationEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _, // Added to match Firestore converter signature
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Missing data for MedicationEntry from snapshot ${snapshot.id}',
      );
    }
    // Pass the document ID along with its data to the static fromJson method
    return MedicationEntry.fromJson(data, snapshot.id);
  }

  /// Creates a MedicationEntry from a map of data and a document ID.
  static MedicationEntry fromJson(Map<String, dynamic> data, String id) {
    return MedicationEntry(
      firestoreId: id,
      name: (data['name'] as String?)?.trim().nullIfEmpty ?? 'Unknown Medication',
      rxCui: data['rxCui'] as String? ?? '', // Default to empty string if null
      dose: data['dose'] as String?,
      time: (data['time'] as String?)?.trim().nullIfEmpty,
      taken: data['taken'] as bool? ?? false,
      date: data['date'] as String? ?? '', // Expects 'date' (YYYY-MM-DD string)
      elderId: data['elderId'] as String? ?? '',
      loggedByUserId: data['loggedByUserId'] as String? ?? '',
      loggedByDisplayName: (data['loggedByDisplayName'] as String?)?.trim().nullIfEmpty ??
                           (data['loggedByUserId'] as String?)?.trim().nullIfEmpty ?? // Fallback to UID if name is empty
                           'Unknown User',
      loggedByUserAvatarUrl: data['loggedByUserAvatarUrl'] as String?,
      stamp: data['stamp'] as Timestamp? ?? Timestamp.now(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
      timelineEntryId: data['timelineEntryId'] as String?,
    );
  }

  /// Converts this MedicationEntry instance to a Map for Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rxCui': rxCui, // Always include rxCui as it's non-nullable
      if (dose != null) 'dose': dose,
      if (time != null) 'time': time,
      'taken': taken,
      'date': date, // Store as 'date' (YYYY-MM-DD string)
      'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      if (loggedByDisplayName != null) 'loggedByDisplayName': loggedByDisplayName,
      if (loggedByUserAvatarUrl != null) 'loggedByUserAvatarUrl': loggedByUserAvatarUrl,
      'stamp': stamp,
      // For new entries, createdAt should be set by the service/form.
      // If it's null here (e.g., client-side object creation before first save),
      // Firestore will use the server timestamp.
      'createdAt': createdAt, // Or use: this.createdAt ?? FieldValue.serverTimestamp() if it can be null before first save
      'updatedAt': FieldValue.serverTimestamp(), // Always update on save
      if (timelineEntryId != null) 'timelineEntryId': timelineEntryId,
    };
  }

  MedicationEntry copyWith({
    String? firestoreId,
    String? name,
    String? rxCui, // Still String? here to allow selective override
    String? dose,
    String? time,
    bool? taken,
    String? date,
    String? elderId,
    String? loggedByUserId,
    String? loggedByDisplayName,
    String? loggedByUserAvatarUrl,
    Timestamp? stamp,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? timelineEntryId,
  }) {
    return MedicationEntry(
      firestoreId: firestoreId ?? this.firestoreId,
      name: name ?? this.name,
      rxCui: rxCui ?? this.rxCui, // Uses existing non-nullable or new value
      dose: dose ?? this.dose,
      time: time ?? this.time,
      taken: taken ?? this.taken,
      date: date ?? this.date,
      elderId: elderId ?? this.elderId,
      loggedByUserId: loggedByUserId ?? this.loggedByUserId,
      loggedByDisplayName: loggedByDisplayName ?? this.loggedByDisplayName,
      loggedByUserAvatarUrl: loggedByUserAvatarUrl ?? this.loggedByUserAvatarUrl,
      stamp: stamp ?? this.stamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      timelineEntryId: timelineEntryId ?? this.timelineEntryId,
    );
  }
}

// Helper extension for String to return null if empty after trimming
extension StringNullIfEmptyExtension on String {
  String? get nullIfEmpty => trim().isEmpty ? null : trim();
}
