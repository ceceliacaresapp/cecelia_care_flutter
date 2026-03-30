import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationDefinition {
  final String? id;
  final String name;
  final String? rxCui;
  final List<String>? interactionNotes;
  final String? dose;
  final String? defaultTime; // HH:mm format, e.g. "08:00"
  final String elderId;

  // Persists whether a daily reminder is currently scheduled.
  final bool reminderEnabled;

  // NEW: Pinned medications appear on the dashboard for one-tap logging.
  final bool pinned;

  // Refill reminder fields.
  final int? pillCount;
  final int? refillThreshold;

  MedicationDefinition({
    this.id,
    required this.name,
    this.rxCui,
    this.interactionNotes,
    this.dose,
    this.defaultTime,
    required this.elderId,
    this.reminderEnabled = false,
    this.pinned = false,
    this.pillCount,
    this.refillThreshold,
  });

  static MedicationDefinition empty() {
    return MedicationDefinition(
      id: null,
      name: '',
      rxCui: null,
      interactionNotes: const [],
      dose: null,
      defaultTime: null,
      elderId: '',
      reminderEnabled: false,
      pinned: false,
      pillCount: null,
      refillThreshold: null,
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
      reminderEnabled: data?['reminderEnabled'] as bool? ?? false,
      pinned: data?['pinned'] as bool? ?? false,
      pillCount: data?['pillCount'] as int?,
      refillThreshold: data?['refillThreshold'] as int?,
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
      'reminderEnabled': reminderEnabled,
      'pinned': pinned,
      if (pillCount != null) 'pillCount': pillCount,
      if (refillThreshold != null) 'refillThreshold': refillThreshold,
    };
  }

  MedicationDefinition copyWith({
    String? id,
    String? name,
    String? rxCui,
    List<String>? interactionNotes,
    String? dose,
    String? defaultTime,
    String? elderId,
    bool? reminderEnabled,
    bool? pinned,
    // Sentinel pattern so callers can explicitly pass null to clear the value.
    Object? pillCount = _kSentinel,
    Object? refillThreshold = _kSentinel,
  }) {
    return MedicationDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      rxCui: rxCui ?? this.rxCui,
      interactionNotes: interactionNotes ?? this.interactionNotes,
      dose: dose ?? this.dose,
      defaultTime: defaultTime ?? this.defaultTime,
      elderId: elderId ?? this.elderId,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      pinned: pinned ?? this.pinned,
      pillCount:
          identical(pillCount, _kSentinel) ? this.pillCount : pillCount as int?,
      refillThreshold: identical(refillThreshold, _kSentinel)
          ? this.refillThreshold
          : refillThreshold as int?,
    );
  }
}

// Private sentinel so copyWith can distinguish "not passed" from "null".
const Object _kSentinel = Object();
