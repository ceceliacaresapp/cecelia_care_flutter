import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationEntry {
  final String firestoreId; // Firestore docId
  final String name; // Display name
  final String rxCui; // RxNorm ID for interaction lookup
  final String dose; // “10 mg”, “5 mL”, …
  final String schedule; // “AM”, “BID”, …
  final String? time; // Actual time taken, e.g., "08:05" (optional)
  final bool taken; // Was the medication taken?
  final String loggedByUserId; // UID of the user who logged this entry
  final String loggedByDisplayName; // Display name of the user who logged this entry
  final Timestamp createdAt;
  final Timestamp updatedAt;

  MedicationEntry({
    required this.firestoreId,
    required this.name,
    required this.rxCui,
    required this.dose,
    required this.schedule,
    this.time,
    required this.taken,
    required this.loggedByUserId,
    required this.loggedByDisplayName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Getter to allow access via 'id' as expected by MedicationProvider
  String get id => firestoreId;

  /// Creates a MedicationEntry from a Firestore data map and document ID.
  static MedicationEntry fromJson(Map<String, dynamic> data, String id) {
    return MedicationEntry(
      firestoreId: id,
      // Apply trim and specific default for name
      name: (data['name'] as String?)?.trim().nullIfEmpty ?? 'Unknown Medication',
      rxCui: data['rxCui'] as String? ?? '',
      dose: data['dose'] as String? ?? '', // Keep N/A or '' based on your preference for empty
      schedule: data['schedule'] as String? ?? '', // Keep N/A or ''
      time: (data['time'] as String?)?.trim().nullIfEmpty, // Allow null time
      taken: data['taken'] as bool? ?? false, // Default to false if missing
      loggedByUserId: data['loggedByUserId'] as String? ?? '', // Default to empty if missing
      loggedByDisplayName:
          (data['loggedByDisplayName'] as String?)?.trim().nullIfEmpty ??
          (data['loggedByUserId'] as String?)?.trim().nullIfEmpty ??
          'Unknown User',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  factory MedicationEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snap, [SnapshotOptions? options]) {
    final data = snap.data();
    if (data == null) {
      throw StateError(
        'Missing data for MedicationEntry from snapshot ${snap.id}',
      );
    }
    return MedicationEntry.fromJson(data, snap.id); // Call the static fromJson method
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rxCui': rxCui,
      'dose': dose,
      'schedule': schedule,
      if (time != null) 'time': time, // Only include if not null
      'taken': taken,
      'loggedByUserId': loggedByUserId,
      'loggedByDisplayName': loggedByDisplayName, // Save as 'loggedByDisplayName'
      'createdAt': createdAt, // Uses the existing createdAt field value
      'updatedAt': FieldValue.serverTimestamp(), // Always update on save
    };
  }

  // Optional: A copyWith method can be useful for updating instances
  MedicationEntry copyWith({
    String? firestoreId,
    String? name,
    String? rxCui,
    String? dose,
    String? schedule,
    String? time,
    bool? taken,
    String? loggedByUserId,
    String? loggedByDisplayName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return MedicationEntry(
      firestoreId: firestoreId ?? this.firestoreId,
      name: name ?? this.name,
      rxCui: rxCui ?? this.rxCui,
      dose: dose ?? this.dose,
      schedule: schedule ?? this.schedule,
      time: time ?? this.time,
      taken: taken ?? this.taken,
      loggedByUserId: loggedByUserId ?? this.loggedByUserId,
      loggedByDisplayName: loggedByDisplayName ?? this.loggedByDisplayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Note on fromJson/toJson:
// The fromFirestore and toFirestore methods serve the purpose of deserialization
// from Firestore and serialization to Firestore, respectively.
// If you need generic fromJson(Map<String, dynamic>) and toJson() methods
// that are not tied to Firestore's specific types (like Timestamp vs. String for dates),
// For direct Firestore usage with converters, these names are conventional.

// Helper extension for String to return null if empty after trimming
extension StringNullIfEmptyExtension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
