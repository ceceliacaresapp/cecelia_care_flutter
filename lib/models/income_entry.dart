import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/models/budget_entry.dart'; // Import for BudgetPerspective enum

class IncomeEntry {
  final String? id;
  final String userId;
  final String careRecipientId;
  final BudgetPerspective perspective; // ADDED
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final bool isRecurring; // ADDED
  final String? notes;

  IncomeEntry({
    this.id,
    required this.userId,
    required this.careRecipientId,
    required this.perspective, // ADDED
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.isRecurring, // ADDED
    this.notes,
  });

  factory IncomeEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data()!;
    return IncomeEntry(
      id: doc.id,
      userId: data['userId'],
      careRecipientId: data['careRecipientId'],
      // ADDED: Handle enum conversion from string
      perspective: BudgetPerspective.values.firstWhere(
        (e) => e.toString() == data['perspective'],
        orElse: () => BudgetPerspective.caregiver, // Default value
      ),
      description: data['description'],
      amount: (data['amount'] as num).toDouble(),
      category: data['category'],
      date: (data['date'] as Timestamp).toDate(),
      isRecurring: data['isRecurring'] ?? false, // ADDED with default value
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'careRecipientId': careRecipientId,
      'perspective': perspective.toString(), // ADDED: Store enum as string
      'description': description,
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'isRecurring': isRecurring, // ADDED
      'notes': notes,
    };
  }
}