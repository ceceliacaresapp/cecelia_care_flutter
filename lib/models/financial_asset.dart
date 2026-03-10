import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/models/budget_entry.dart'; // Import for BudgetPerspective enum

class FinancialAsset {
  final String? id;
  final String userId;
  final String careRecipientId;
  final BudgetPerspective perspective; // ADDED
  final String description;             // ADDED (replaces 'name')
  final double value;
  final String category;                // ADDED (replaces 'type')
  final DateTime dateOfValuation;     // ADDED
  final String? notes;

  FinancialAsset({
    this.id,
    required this.userId,
    required this.careRecipientId,
    required this.perspective,         // ADDED
    required this.description,          // ADDED
    required this.value,
    required this.category,              // ADDED
    required this.dateOfValuation,     // ADDED
    this.notes,
  });

  factory FinancialAsset.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data()!;
    return FinancialAsset(
      id: doc.id,
      userId: data['userId'],
      careRecipientId: data['careRecipientId'],
      // ADDED: Handle enum conversion and provide a default
      perspective: BudgetPerspective.values.firstWhere(
        (e) => e.toString() == data['perspective'],
        orElse: () => BudgetPerspective.caregiver,
      ),
      // UPDATED: Use 'description' field, provide fallback from 'name' for old data
      description: data['description'] ?? data['name'] ?? '',
      value: (data['value'] as num).toDouble(),
      // UPDATED: Use 'category' field, provide fallback from 'type' for old data
      category: data['category'] ?? data['type'] ?? 'Other',
      // ADDED: Handle Timestamp conversion
      dateOfValuation: (data['dateOfValuation'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'careRecipientId': careRecipientId,
      'perspective': perspective.toString(), // ADDED
      'description': description,              // ADDED
      'value': value,
      'category': category,                  // ADDED
      'dateOfValuation': Timestamp.fromDate(dateOfValuation), // ADDED
      'notes': notes,
      // 'name' and 'type' are omitted as they are replaced by 'description' and 'category'
    };
  }
}