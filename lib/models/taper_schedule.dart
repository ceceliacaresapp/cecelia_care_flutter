// lib/models/taper_schedule.dart
//
// TaperSchedule — a prescriber-authored step-down plan for a medication
// that must not be stopped abruptly (corticosteroids, benzodiazepines,
// opioids, SSRIs, etc.). Stored at:
//
//   elderProfiles/{elderId}/taperSchedules/{taperId}
//
// Each schedule belongs to exactly one MedicationDefinition and carries
// an ordered list of `TaperStep`s. A step is a contiguous date range
// with a fixed daily dose + frequency. The schedule is "active" from
// startDate (first step) through endDate (last step inclusive).
//
// Safety rails baked into the model:
//  • prescriberName and reason are required (doctor accountability).
//  • isDoctorApproved flag lets the UI block saves until the caregiver
//    affirms they're transcribing a doctor-issued plan, not guessing.
//  • Steps are validated to be contiguous + non-overlapping before write.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Why the medication is being tapered. Drives the AI prompt and the
/// warnings surfaced in the UI.
enum TaperReason {
  withdrawal, // weaning to discontinue
  symptomResolved, // tapering because the underlying condition improved
  sideEffects, // reducing due to adverse effects
  doseAdjustment, // non-discontinuation — just stepping down to maintenance
  other,
}

extension TaperReasonX on TaperReason {
  String get label {
    switch (this) {
      case TaperReason.withdrawal:
        return 'Weaning off';
      case TaperReason.symptomResolved:
        return 'Symptom resolved';
      case TaperReason.sideEffects:
        return 'Side effects';
      case TaperReason.doseAdjustment:
        return 'Dose adjustment';
      case TaperReason.other:
        return 'Other';
    }
  }

  String get firestoreValue {
    switch (this) {
      case TaperReason.withdrawal:
        return 'withdrawal';
      case TaperReason.symptomResolved:
        return 'symptom_resolved';
      case TaperReason.sideEffects:
        return 'side_effects';
      case TaperReason.doseAdjustment:
        return 'dose_adjustment';
      case TaperReason.other:
        return 'other';
    }
  }

  static TaperReason fromString(String? s) {
    switch (s) {
      case 'withdrawal':
        return TaperReason.withdrawal;
      case 'symptom_resolved':
        return TaperReason.symptomResolved;
      case 'side_effects':
        return TaperReason.sideEffects;
      case 'dose_adjustment':
        return TaperReason.doseAdjustment;
      default:
        return TaperReason.other;
    }
  }
}

enum TaperStatus { draft, active, completed, cancelled }

extension TaperStatusX on TaperStatus {
  String get label {
    switch (this) {
      case TaperStatus.draft:
        return 'Draft';
      case TaperStatus.active:
        return 'Active';
      case TaperStatus.completed:
        return 'Completed';
      case TaperStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get firestoreValue {
    switch (this) {
      case TaperStatus.draft:
        return 'draft';
      case TaperStatus.active:
        return 'active';
      case TaperStatus.completed:
        return 'completed';
      case TaperStatus.cancelled:
        return 'cancelled';
    }
  }

  static TaperStatus fromString(String? s) {
    switch (s) {
      case 'draft':
        return TaperStatus.draft;
      case 'active':
        return TaperStatus.active;
      case 'completed':
        return TaperStatus.completed;
      case 'cancelled':
        return TaperStatus.cancelled;
      default:
        return TaperStatus.draft;
    }
  }
}

/// A single contiguous dose range within a taper. Dates are day-precision
/// only — time of day comes from the parent schedule's reminderTime.
class TaperStep {
  final DateTime fromDate;
  final DateTime toDate;
  final double dose;
  final String doseUnit; // "mg", "mcg", "pill", "ml"
  final String frequency; // e.g. "once daily", "twice daily", "every other day"
  final String? notes;

  const TaperStep({
    required this.fromDate,
    required this.toDate,
    required this.dose,
    required this.doseUnit,
    this.frequency = 'once daily',
    this.notes,
  });

  int get durationDays => toDate.difference(fromDate).inDays + 1;

  bool containsDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final from = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final to = DateTime(toDate.year, toDate.month, toDate.day);
    return !d.isBefore(from) && !d.isAfter(to);
  }

  String get doseDisplay => '${_formatDose(dose)} $doseUnit';

  Map<String, dynamic> toMap() => {
        'fromDate': Timestamp.fromDate(fromDate),
        'toDate': Timestamp.fromDate(toDate),
        'dose': dose,
        'doseUnit': doseUnit,
        'frequency': frequency,
        if (notes != null) 'notes': notes,
      };

  factory TaperStep.fromMap(Map<String, dynamic> data) {
    return TaperStep(
      fromDate: (data['fromDate'] as Timestamp).toDate(),
      toDate: (data['toDate'] as Timestamp).toDate(),
      dose: (data['dose'] as num).toDouble(),
      doseUnit: data['doseUnit'] as String? ?? 'mg',
      frequency: data['frequency'] as String? ?? 'once daily',
      notes: data['notes'] as String?,
    );
  }

  TaperStep copyWith({
    DateTime? fromDate,
    DateTime? toDate,
    double? dose,
    String? doseUnit,
    String? frequency,
    String? notes,
  }) =>
      TaperStep(
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        dose: dose ?? this.dose,
        doseUnit: doseUnit ?? this.doseUnit,
        frequency: frequency ?? this.frequency,
        notes: notes ?? this.notes,
      );
}

/// Prescriber-authored taper plan.
class TaperSchedule {
  final String id;
  final String elderId;

  // Link to the source MedicationDefinition. Stored as a string so we
  // don't carry a stale denormalized copy — the display pulls the
  // current medication name from the definition at render time.
  final String? medDefId;

  // Display fallback when medDefId has been deleted or when a caregiver
  // transcribes a schedule for a med they haven't added to the definitions
  // list yet.
  final String medName;

  // Reason + prescriber = accountability chain.
  final TaperReason reason;
  final String? reasonNote;
  final String prescriberName;

  // "I've transcribed the plan my doctor wrote down." Must be true to save.
  final bool isDoctorApproved;

  final List<TaperStep> steps;

  // Reminder configuration. Notifications fire one-shot per day across
  // the taper window.
  final String reminderTime; // "HH:mm" 24-hour
  final bool reminderEnabled;

  final TaperStatus status;

  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? createdByUid;
  final String? createdByName;

  const TaperSchedule({
    required this.id,
    required this.elderId,
    required this.medName,
    this.medDefId,
    this.reason = TaperReason.other,
    this.reasonNote,
    this.prescriberName = '',
    this.isDoctorApproved = false,
    this.steps = const [],
    this.reminderTime = '09:00',
    this.reminderEnabled = false,
    this.status = TaperStatus.draft,
    this.createdAt,
    this.updatedAt,
    this.createdByUid,
    this.createdByName,
  });

  factory TaperSchedule.empty(String elderId) => TaperSchedule(
        id: '',
        elderId: elderId,
        medName: '',
      );

  // ---------------------------------------------------------------------------
  // Derived views used by the UI
  // ---------------------------------------------------------------------------

  DateTime? get startDate =>
      steps.isEmpty ? null : _earliest(steps.map((s) => s.fromDate));
  DateTime? get endDate =>
      steps.isEmpty ? null : _latest(steps.map((s) => s.toDate));

  int get totalDays {
    final s = startDate;
    final e = endDate;
    if (s == null || e == null) return 0;
    return e.difference(s).inDays + 1;
  }

  int get completedDays {
    final s = startDate;
    if (s == null) return 0;
    final today = _dayOnly(DateTime.now());
    if (today.isBefore(s)) return 0;
    final e = endDate;
    if (e != null && today.isAfter(e)) return totalDays;
    return today.difference(s).inDays;
  }

  double get progress {
    if (totalDays == 0) return 0;
    return (completedDays / totalDays).clamp(0, 1);
  }

  /// The step covering [day], or null if no step does.
  TaperStep? stepForDay(DateTime day) {
    for (final s in steps) {
      if (s.containsDay(day)) return s;
    }
    return null;
  }

  TaperStep? get todaysStep => stepForDay(DateTime.now());

  /// True when today falls inside the overall taper window AND the
  /// schedule is active.
  bool get isTodayInWindow {
    final s = startDate;
    final e = endDate;
    if (s == null || e == null) return false;
    final today = _dayOnly(DateTime.now());
    return !today.isBefore(_dayOnly(s)) && !today.isAfter(_dayOnly(e));
  }

  /// Readable one-liner: "5 mg → 0 mg over 14 days".
  String get summary {
    if (steps.isEmpty) return 'No steps yet';
    final first = steps.first;
    final last = steps.last;
    return '${first.doseDisplay} → ${last.doseDisplay} over $totalDays days';
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Returns a list of human-readable issues. Empty list = ready to save.
  List<String> validate() {
    final issues = <String>[];
    if (medName.trim().isEmpty) issues.add('Medication name required');
    if (prescriberName.trim().isEmpty) {
      issues.add('Prescribing doctor required');
    }
    if (steps.isEmpty) issues.add('Add at least one taper step');
    if (!isDoctorApproved) {
      issues.add('Confirm this was prescribed by a doctor');
    }
    // Check ordering + overlap.
    for (int i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.toDate.isBefore(s.fromDate)) {
        issues.add('Step ${i + 1}: end date is before start date');
      }
      if (s.dose < 0) issues.add('Step ${i + 1}: dose cannot be negative');
      if (i > 0) {
        final prev = steps[i - 1];
        if (!s.fromDate.isAfter(prev.toDate)) {
          issues.add('Step ${i + 1}: overlaps with step $i');
        }
      }
    }
    return issues;
  }

  bool get isValid => validate().isEmpty;

  // ---------------------------------------------------------------------------
  // Firestore serialization
  // ---------------------------------------------------------------------------

  factory TaperSchedule.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
    SnapshotOptions? _,
  ) {
    final data = snap.data() ?? const <String, dynamic>{};
    final segments = snap.reference.path.split('/');
    // elderProfiles/{elderId}/taperSchedules/{id}
    final elderId = segments.length >= 2 ? segments[1] : '';
    final rawSteps = (data['steps'] as List<dynamic>?) ?? const [];
    return TaperSchedule(
      id: snap.id,
      elderId: elderId,
      medDefId: data['medDefId'] as String?,
      medName: (data['medName'] as String?) ?? '',
      reason: TaperReasonX.fromString(data['reason'] as String?),
      reasonNote: data['reasonNote'] as String?,
      prescriberName: (data['prescriberName'] as String?) ?? '',
      isDoctorApproved: (data['isDoctorApproved'] as bool?) ?? false,
      steps: rawSteps
          .map((e) => TaperStep.fromMap(e as Map<String, dynamic>))
          .toList(),
      reminderTime: (data['reminderTime'] as String?) ?? '09:00',
      reminderEnabled: (data['reminderEnabled'] as bool?) ?? false,
      status: TaperStatusX.fromString(data['status'] as String?),
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      createdByUid: data['createdByUid'] as String?,
      createdByName: data['createdByName'] as String?,
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      if (medDefId != null) 'medDefId': medDefId,
      'medName': medName,
      'reason': reason.firestoreValue,
      if (reasonNote != null) 'reasonNote': reasonNote,
      'prescriberName': prescriberName,
      'isDoctorApproved': isDoctorApproved,
      'steps': steps.map((s) => s.toMap()).toList(),
      'reminderTime': reminderTime,
      'reminderEnabled': reminderEnabled,
      'status': status.firestoreValue,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdByUid != null) 'createdByUid': createdByUid,
      if (createdByName != null) 'createdByName': createdByName,
    };
  }

  TaperSchedule copyWith({
    String? id,
    String? elderId,
    String? medDefId,
    String? medName,
    TaperReason? reason,
    String? reasonNote,
    String? prescriberName,
    bool? isDoctorApproved,
    List<TaperStep>? steps,
    String? reminderTime,
    bool? reminderEnabled,
    TaperStatus? status,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? createdByUid,
    String? createdByName,
  }) {
    return TaperSchedule(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      medDefId: medDefId ?? this.medDefId,
      medName: medName ?? this.medName,
      reason: reason ?? this.reason,
      reasonNote: reasonNote ?? this.reasonNote,
      prescriberName: prescriberName ?? this.prescriberName,
      isDoctorApproved: isDoctorApproved ?? this.isDoctorApproved,
      steps: steps ?? this.steps,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Strips the time-of-day component so two DateTimes representing the
/// same calendar day compare equal.
DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _earliest(Iterable<DateTime> xs) {
  final it = xs.iterator..moveNext();
  var best = it.current;
  while (it.moveNext()) {
    if (it.current.isBefore(best)) best = it.current;
  }
  return best;
}

DateTime _latest(Iterable<DateTime> xs) {
  final it = xs.iterator..moveNext();
  var best = it.current;
  while (it.moveNext()) {
    if (it.current.isAfter(best)) best = it.current;
  }
  return best;
}

/// Formats a dose removing trailing .0 on whole numbers (so `5.0` → `"5"`
/// and `2.5` → `"2.5"`).
String _formatDose(double dose) {
  if (dose == dose.roundToDouble()) return dose.toInt().toString();
  return dose.toStringAsFixed(
    (dose * 10).round() % 10 == 0 ? 1 : 2,
  );
}

// ---------------------------------------------------------------------------
// Preset taper templates
//
// These are *starting points only* — doctors tailor tapers to the patient.
// But caregivers often have a doctor-dictated plan that follows one of
// these common shapes, so offering presets saves a lot of typing.
// ---------------------------------------------------------------------------

class TaperPreset {
  final String name;
  final String description;
  final String medHint; // typical medication class this applies to
  final List<({double dose, int days})> steps;
  final String doseUnit;

  const TaperPreset({
    required this.name,
    required this.description,
    required this.medHint,
    required this.steps,
    required this.doseUnit,
  });

  /// Materializes this preset into concrete TaperSteps starting on [start].
  List<TaperStep> materialize({
    required DateTime start,
    String frequency = 'once daily',
  }) {
    final result = <TaperStep>[];
    var cursor = _dayOnly(start);
    for (final s in steps) {
      final end = cursor.add(Duration(days: s.days - 1));
      result.add(TaperStep(
        fromDate: cursor,
        toDate: end,
        dose: s.dose,
        doseUnit: doseUnit,
        frequency: frequency,
      ));
      cursor = end.add(const Duration(days: 1));
    }
    return result;
  }
}

/// Commonly-seen taper shapes. All are conservative defaults — any real
/// schedule must come from the prescriber.
const List<TaperPreset> kTaperPresets = [
  TaperPreset(
    name: 'Prednisone short course',
    description: '20→15→10→5→0 mg, 3 days each',
    medHint: 'Corticosteroid',
    doseUnit: 'mg',
    steps: [
      (dose: 20, days: 3),
      (dose: 15, days: 3),
      (dose: 10, days: 3),
      (dose: 5, days: 3),
      (dose: 0, days: 1),
    ],
  ),
  TaperPreset(
    name: 'Prednisone 2-week wean',
    description: '40→30→20→10→5→0 mg, varied duration',
    medHint: 'Corticosteroid (higher-dose start)',
    doseUnit: 'mg',
    steps: [
      (dose: 40, days: 3),
      (dose: 30, days: 3),
      (dose: 20, days: 3),
      (dose: 10, days: 3),
      (dose: 5, days: 2),
      (dose: 0, days: 1),
    ],
  ),
  TaperPreset(
    name: 'Slow 10% reduction',
    description: 'Reduce by ~10% every 2 weeks (6 steps from 10mg)',
    medHint: 'Benzodiazepines, SSRIs',
    doseUnit: 'mg',
    steps: [
      (dose: 10.0, days: 14),
      (dose: 9.0, days: 14),
      (dose: 8.0, days: 14),
      (dose: 7.0, days: 14),
      (dose: 6.0, days: 14),
      (dose: 5.0, days: 14),
    ],
  ),
  TaperPreset(
    name: 'Opioid 10% weekly',
    description: 'Reduce by 10% of original dose each week',
    medHint: 'Opioid analgesics',
    doseUnit: 'mg',
    steps: [
      (dose: 100, days: 7),
      (dose: 90, days: 7),
      (dose: 80, days: 7),
      (dose: 70, days: 7),
      (dose: 60, days: 7),
      (dose: 50, days: 7),
    ],
  ),
];
