import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationDefinition {
  final String? id; // Document ID from Firestore, nullable for new instances
  final String name;
  final String? rxCui; // RxNorm ID, optional
  final List<String>? interactionNotes; // Added field
  final String? dose; // e.g., "10mg", "1 tablet"
  final String? defaultTime; // Optional: HH:mm format, e.g., "08:00"
  final String elderId; // To scope definitions per elder

  MedicationDefinition({
    this.id,
    required this.name,
    this.rxCui,
    this.interactionNotes,
    this.dose,
    this.defaultTime,
    required this.elderId,
  });

  /// Returns an empty placeholder definition.
  static MedicationDefinition empty() {
    return MedicationDefinition(
      id: null,
      name: '',
      rxCui: null,
      interactionNotes: const [],
      dose: null,
      defaultTime: null,
      elderId: '',
    );
  }

  factory MedicationDefinition.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return MedicationDefinition(
      id: doc.id,
      name: data?['name'] as String? ?? '',
      rxCui: data?['rxCui'] as String?,
      dose: data?['dose'] as String?,
      interactionNotes: data?['interactionNotes'] != null
          ? List<String>.from(data!['interactionNotes'] as List)
          : null,
      defaultTime: data?['defaultTime'] as String?,
      elderId: data?['elderId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rxCui': rxCui,
      'dose': dose,
      'interactionNotes': interactionNotes,
      'defaultTime': defaultTime,
      'elderId': elderId,
      // Note: `id` is the document ID and is not stored in the document fields.
    };
  }

  /// Returns a copy of this instance with the given fields replaced.
  MedicationDefinition copyWith({
    String? id,
    String? name,
    String? rxCui,
    List<String>? interactionNotes,
    String? dose,
    String? defaultTime,
    String? elderId,
  }) {
    return MedicationDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      rxCui: rxCui ?? this.rxCui,
      interactionNotes: interactionNotes ?? this.interactionNotes,
      dose: dose ?? this.dose,
      defaultTime: defaultTime ?? this.defaultTime,
      elderId: elderId ?? this.elderId,
    );
  }
}
