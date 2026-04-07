import 'package:cloud_firestore/cloud_firestore.dart';

// This enum determines if the expense was paid by the caregiver
// or from the care recipient's own funds.
enum BudgetPerspective {
  careRecipient,
  caregiver,
}

class BudgetEntry {
  final String? id;
  final String userId;
  final String careRecipientId;
  final BudgetPerspective perspective;
  final String description;
  final double amount;
  final String category;
  final String? subCategory;
  final DateTime date;
  final String? notes;
  final bool isTaxDeductible;
  final bool isRecurring;

  BudgetEntry({
    this.id,
    required this.userId,
    required this.careRecipientId,
    required this.perspective,
    required this.description,
    required this.amount,
    required this.category,
    this.subCategory,
    required this.date,
    this.notes,
    this.isTaxDeductible = false,
    this.isRecurring = false,
  });

  /// **CORRECTED: Converts a Firestore DocumentSnapshot into a BudgetEntry object.**
  /// The signature now includes `SnapshotOptions? options` to match what Firestore expects.
  factory BudgetEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options, // This parameter is required, even if not used.
  ) {
    final data = doc.data()!;
    return BudgetEntry(
      id: doc.id,
      userId: data['userId'] ?? '',
      careRecipientId: data['careRecipientId'] ?? '',
      // Convert the stored string back into an enum value.
      perspective: BudgetPerspective.values.firstWhere(
        (e) => e.name == data['perspective'],
        orElse: () => BudgetPerspective.caregiver, // Default value
      ),
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      category: data['category'] ?? '',
      subCategory: data['subCategory'],
      // Convert the Firestore Timestamp back to a DateTime object.
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: data['notes'],
      isTaxDeductible: data['isTaxDeductible'] ?? false,
      isRecurring: data['isRecurring'] ?? false,
    );
  }

  /// **Converts a BudgetEntry object into a Map for Firestore.**
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'careRecipientId': careRecipientId,
      // Store the enum as a string.
      'perspective': perspective.name,
      'description': description,
      'amount': amount,
      'category': category,
      if (subCategory != null) 'subCategory': subCategory,
      // Convert the DateTime object to a Firestore Timestamp.
      'date': Timestamp.fromDate(date),
      if (notes != null) 'notes': notes,
      'isTaxDeductible': isTaxDeductible,
      'isRecurring': isRecurring,
    };
  }
}