import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseEntry {
  final String firestoreId; // Document ID from Firestore
  final String? description;
  final double? amount; // Stored as a number
  final String? category;
  final String? note; // Optional
  final DateTime? stamp; // The actual time of the expense logging or occurrence
  final String? time; // Formatted time string for display (e.g., "HH:mm")
  final String? date; // Formatted date string (e.g., "YYYY-MM-DD")
  final String elderId;
  final String loggedByUserId;
  final String loggedBy; // Display name of the user who logged the entry
  final Timestamp createdAt;
  final Timestamp updatedAt;

  ExpenseEntry({
    required this.firestoreId,
    this.description,
    this.amount,
    this.category,
    this.note,
    this.stamp, // Made optional to match field type
    this.time,  // Made optional
    this.date,  // Made optional
    required this.elderId,
    required this.loggedByUserId,
    required this.loggedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [ExpenseEntry] from a standard JSON map.
  ///
  /// Assumes the [json] map contains keys corresponding to the [ExpenseEntry]
  /// fields, with appropriate types.
  /// - 'stamp', 'createdAt', 'updatedAt' are expected as Timestamps if not null.
  /// - 'amount' is expected as a num if not null.
  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      firestoreId: json['firestoreId'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      category: json['category'] as String?,
      note: json['note'] as String?,
      stamp: (json['stamp'] as Timestamp?)?.toDate(),
      time: json['time'] as String?,
      date: json['date'] as String?,
      elderId: json['elderId'] as String,
      loggedByUserId: json['loggedByUserId'] as String,
      loggedBy: json['loggedBy'] as String,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  /// Converts this [ExpenseEntry] instance to a JSON map.
  ///
  /// Converts DateTime fields back to Timestamps for consistency.
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'description': description,
      'amount': amount,
      'category': category,
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

  // Factory constructor to create an ExpenseEntry from a Firestore document
  factory ExpenseEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _,
  ]) {
    final data = snapshot.data(); // Data from the specific ExpenseEntry document
    if (data == null) {
      throw StateError(
        'Missing data for ExpenseEntry from snapshot ${snapshot.id}',
      );
    }

    return ExpenseEntry(
      firestoreId: snapshot.id, // The ID of the JournalEntry document
      description: data['description'] as String?,
      amount: (data['amount'] as num?)?.toDouble(),
      category: data['category'] as String? ?? 'Other',
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

  // The fromJson factory might be removed if not used elsewhere,
  // as fromFirestore now directly calls the constructor.
  // factory ExpenseEntry.fromJson(Map<String, dynamic> json) { ... }

  // Method to convert ExpenseEntry instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'category': category,
      if (note != null) 'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null, // Convert DateTime back to Timestamp
      if (time != null) 'time': time,
      if (date != null) 'date': date,
      'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt': createdAt, // Uses existing createdAt; for new entries, ensure it's set or handle in service
      'updatedAt': FieldValue.serverTimestamp(), // Always update on save
    };
  }
}
