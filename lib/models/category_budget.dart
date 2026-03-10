// lib/models/category_budget.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryBudget {
  final String userId;
  final String careRecipientId; // Or 'all'
  final String yearMonth; // e.g., "2025-07"
  final Map<String, double> budgets; // e.g., {"Medical & Health": 500.00, "Housing": 1200.00}

  CategoryBudget({
    required this.userId,
    required this.careRecipientId,
    required this.yearMonth,
    required this.budgets,
  });

  // Methods for Firestore conversion
  factory CategoryBudget.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CategoryBudget(
      userId: data['userId'],
      careRecipientId: data['careRecipientId'],
      yearMonth: doc.id, // We'll use YYYY-MM as the document ID
      budgets: Map<String, double>.from(data['budgets']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'careRecipientId': careRecipientId,
      'budgets': budgets,
    };
  }
}