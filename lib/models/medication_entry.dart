import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationEntry {
  final String firestoreId;
  final String name;
  final String rxCui;
  final String dose;
  final String schedule;
  final String? time;
  final bool taken;
  // NEW: records when the dose was marked taken or skipped.
  // null means the entry hasn't been actioned yet (e.g. scheduled but
  // not yet confirmed). Used by the adherence history strip to show
  // taken (green) / skipped (red) / pending (grey) per dose.
  final Timestamp? takenAt;
  final String loggedByUserId;
  final String loggedByDisplayName;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  MedicationEntry({
    required this.firestoreId,
    required this.name,
    required this.rxCui,
    required this.dose,
    required this.schedule,
    this.time,
    required this.taken,
    this.takenAt,
    required this.loggedByUserId,
    required this.loggedByDisplayName,
    required this.createdAt,
    required this.updatedAt,
  });

  String get id => firestoreId;

  static MedicationEntry fromJson(Map<String, dynamic> data, String id) {
    return MedicationEntry(
      firestoreId: id,
      name: (data['name'] as String?)?.trim().nullIfEmpty ??
          'Unknown Medication',
      rxCui: data['rxCui'] as String? ?? '',
      dose: data['dose'] as String? ?? '',
      schedule: data['schedule'] as String? ?? '',
      time: (data['time'] as String?)?.trim().nullIfEmpty,
      taken: data['taken'] as bool? ?? false,
      takenAt: data['takenAt'] as Timestamp?,
      loggedByUserId: data['loggedByUserId'] as String? ?? '',
      loggedByDisplayName:
          (data['loggedByDisplayName'] as String?)?.trim().nullIfEmpty ??
              (data['loggedByUserId'] as String?)?.trim().nullIfEmpty ??
              'Unknown User',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  factory MedicationEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap, [
    SnapshotOptions? options,
  ]) {
    final data = snap.data();
    if (data == null) {
      throw StateError(
          'Missing data for MedicationEntry from snapshot ${snap.id}');
    }
    return MedicationEntry.fromJson(data, snap.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'rxCui': rxCui,
      'dose': dose,
      'schedule': schedule,
      if (time != null) 'time': time,
      'taken': taken,
      if (takenAt != null) 'takenAt': takenAt,
      'loggedByUserId': loggedByUserId,
      'loggedByDisplayName': loggedByDisplayName,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MedicationEntry copyWith({
    String? firestoreId,
    String? name,
    String? rxCui,
    String? dose,
    String? schedule,
    String? time,
    bool? taken,
    Timestamp? takenAt,
    String? loggedByUserId,
    String? loggedByDisplayName,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return MedicationEntry(
      firestoreId: firestoreId ?? this.firestoreId,
      name: name ?? this.name,
      rxCui: rxCui ?? this.rxCui,
      dose: dose ?? this.dose,
      schedule: schedule ?? this.schedule,
      time: time ?? this.time,
      taken: taken ?? this.taken,
      takenAt: takenAt ?? this.takenAt,
      loggedByUserId: loggedByUserId ?? this.loggedByUserId,
      loggedByDisplayName: loggedByDisplayName ?? this.loggedByDisplayName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

extension StringNullIfEmptyExtension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
