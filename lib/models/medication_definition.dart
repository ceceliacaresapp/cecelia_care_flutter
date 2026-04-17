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

  // Photo of the pill/bottle for visual identification.
  final String? photoUrl;

  // PRN (as-needed) medication tracking.
  final bool isPRN;

  /// Delay in minutes before a "did it help?" follow-up notification.
  /// null = follow-up disabled. Common values: 30, 60, 90.
  final int? prnFollowUpMinutes;

  // Controlled substance fields.
  /// True if this medication is a controlled/scheduled substance (opioids, etc.).
  final bool isControlled;

  /// DEA schedule (2-5). null = not applicable.
  final int? deaSchedule;

  /// If true, opening controlled substance details requires the care team PIN.
  final bool requiresVerification;

  /// If true, two caregivers must confirm each dose administration.
  final bool requiresTwoPersonVerify;

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
    this.photoUrl,
    this.isPRN = false,
    this.prnFollowUpMinutes,
    this.isControlled = false,
    this.deaSchedule,
    this.requiresVerification = false,
    this.requiresTwoPersonVerify = false,
  });

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

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
      photoUrl: null,
      isPRN: false,
      prnFollowUpMinutes: null,
      isControlled: false,
      deaSchedule: null,
      requiresVerification: false,
      requiresTwoPersonVerify: false,
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
      photoUrl: data?['photoUrl'] as String?,
      isPRN: data?['isPRN'] as bool? ?? false,
      prnFollowUpMinutes: data?['prnFollowUpMinutes'] as int?,
      isControlled: data?['isControlled'] as bool? ?? false,
      deaSchedule: data?['deaSchedule'] as int?,
      requiresVerification: data?['requiresVerification'] as bool? ?? false,
      requiresTwoPersonVerify: data?['requiresTwoPersonVerify'] as bool? ?? false,
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
      if (photoUrl != null) 'photoUrl': photoUrl,
      'isPRN': isPRN,
      if (prnFollowUpMinutes != null)
        'prnFollowUpMinutes': prnFollowUpMinutes,
      'isControlled': isControlled,
      if (deaSchedule != null) 'deaSchedule': deaSchedule,
      'requiresVerification': requiresVerification,
      'requiresTwoPersonVerify': requiresTwoPersonVerify,
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
    Object? photoUrl = _kSentinel,
    bool? isPRN,
    Object? prnFollowUpMinutes = _kSentinel,
    bool? isControlled,
    Object? deaSchedule = _kSentinel,
    bool? requiresVerification,
    bool? requiresTwoPersonVerify,
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
      photoUrl: identical(photoUrl, _kSentinel)
          ? this.photoUrl
          : photoUrl as String?,
      isPRN: isPRN ?? this.isPRN,
      prnFollowUpMinutes: identical(prnFollowUpMinutes, _kSentinel)
          ? this.prnFollowUpMinutes
          : prnFollowUpMinutes as int?,
      isControlled: isControlled ?? this.isControlled,
      deaSchedule: identical(deaSchedule, _kSentinel)
          ? this.deaSchedule
          : deaSchedule as int?,
      requiresVerification:
          requiresVerification ?? this.requiresVerification,
      requiresTwoPersonVerify:
          requiresTwoPersonVerify ?? this.requiresTwoPersonVerify,
    );
  }
}

// Private sentinel so copyWith can distinguish "not passed" from "null".
const Object _kSentinel = Object();
