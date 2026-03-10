import 'package:cloud_firestore/cloud_firestore.dart';

class MealEntry {
  final String firestoreId; // Document ID from Firestore
  final String? intakeCategory; // "Food" or "Water"
  final String? mealType; // For Food: "Breakfast", "Lunch", etc. For Water: context like "Morning", "With meds"
  final String? description; // For Food: description of meal. For Water: amount of water (e.g., "250ml")
  final int? calories; // Calories for food entries
  final String? note; // Optional
  final DateTime? stamp; // The actual time of the meal/intake
  final String? time; // Formatted time string for display (e.g., "HH:mm")
  final String? date; // Formatted date string (e.g., "YYYY-MM-DD")
  final String elderId;
  final String loggedByUserId;
  final String loggedBy; // Display name of the user who logged the entry
  final Timestamp createdAt;
  final Timestamp updatedAt;

  MealEntry({
    required this.firestoreId,
    this.intakeCategory,
    this.mealType,
    this.description,
    this.calories,
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

  /// Creates a [MealEntry] from a standard JSON map.
  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      firestoreId: json['firestoreId'] as String,
      intakeCategory: json['intakeCategory'] as String?,
      mealType: json['mealType'] as String?,
      description: json['description'] as String?,
      calories: (json['calories'] as num?)?.toInt(),
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

  /// Converts this [MealEntry] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'intakeCategory': intakeCategory,
      'mealType': mealType,
      'description': description,
      'calories': calories,
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

  // Factory constructor to create a MealEntry from a Firestore document
  factory MealEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _, // match Firestore converter signature
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Missing data for MealEntry from snapshot ${snapshot.id}',
      );
    }

    return MealEntry(
      firestoreId: snapshot.id,
      intakeCategory: data['intakeCategory'] as String? ?? 'Food',
      mealType: data['mealType'] as String?,
      description: data['description'] as String?,
      calories: (data['calories'] as num?)?.toInt(),
      note: data['note'] as String?,
      stamp: (data['stamp'] as Timestamp?)?.toDate(),
      time: data['time'] as String?,
      date: data['date'] as String?,
      elderId: data['elderId'] as String? ?? '',
      loggedByUserId: data['loggedByUserId'] as String? ?? '',
      loggedBy: data['loggedByDisplayName'] as String? ?? 'Unknown User',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Method to convert MealEntry instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'intakeCategory': intakeCategory,
      'mealType': mealType,
      'description': description,
      if (calories != null) 'calories': calories,
      if (note != null) 'note': note,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null,
      if (time != null) 'time': time,
      if (date != null) 'date': date,
      'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// For food entries, returns the calories if set.
  int? get mealCalories => calories;
}
