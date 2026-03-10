import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/models/budget_entry.dart'; // Import for BudgetPerspective enum

class FinancialLiability {
  final String? id;
  final String userId;
  final String careRecipientId;
  final BudgetPerspective perspective; // ADDED
  final String description;             // ADDED (replaces 'name')
  final double amount;
  final String category;                // ADDED (replaces 'type')
  final double? interestRate;           // ADDED
  final String? notes;

  FinancialLiability({
    this.id,
    required this.userId,
    required this.careRecipientId,
    required this.perspective,         // ADDED
    required this.description,          // ADDED
    required this.amount,
    required this.category,              // ADDED
    this.interestRate,                  // ADDED
    this.notes,
  });

  factory FinancialLiability.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data()!;
    return FinancialLiability(
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
      amount: (data['amount'] as num).toDouble(),
      // UPDATED: Use 'category' field, provide fallback from 'type' for old data
      category: data['category'] ?? data['type'] ?? 'Other',
      // ADDED: Handle optional double
      interestRate: (data['interestRate'] as num?)?.toDouble(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'careRecipientId': careRecipientId,
      'perspective': perspective.toString(), // ADDED
      'description': description,              // ADDED
      'amount': amount,
      'category': category,                  // ADDED
      'interestRate': interestRate,          // ADDED
      'notes': notes,
       // 'name' and 'type' are omitted as they are replaced
    };
  }
}