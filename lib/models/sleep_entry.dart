import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart'; // Uncomment if you need TimeOfDay helpers

class SleepEntry {
  final String firestoreId; // Document ID from Firestore
  final String? wentToBed; // Stored as "HH:mm"
  final String? wokeUp; // Optional, stored as "HH:mm"
  final String? totalDuration; // Optional, e.g., "7 hours 30 minutes"
  final String? quality; // e.g., "Good", "Fair", or custom
  final String? naps; // Optional, e.g., "1 nap, 45 mins"
  final String? notes; // General notes or notes for "Other" quality
  final String? date; // Formatted date string (e.g., "YYYY-MM-DD")
  final String? elderId;
  final String? loggedByUserId;
  final String loggedBy; // Display name of the user who logged the entry
  final DateTime? stamp; // Actual timestamp of logging this entry
  final String? time; // Formatted log time (e.g., "HH:mm")
  final Timestamp createdAt;
  final Timestamp updatedAt;

  SleepEntry({
    required this.firestoreId,
    this.wentToBed,
    this.wokeUp,
    this.totalDuration,
    this.quality,
    this.naps,
    this.notes,
    this.date,
    this.elderId,
    this.loggedByUserId,
    required this.loggedBy,
    this.stamp,
    this.time,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [SleepEntry] from a JSON map.
  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    return SleepEntry(
      firestoreId: json['firestoreId'] as String,
      wentToBed: json['wentToBed'] as String?,
      wokeUp: json['wokeUp'] as String?,
      totalDuration: json['totalDuration'] as String?,
      quality: json['quality'] as String?,
      naps: json['naps'] as String?,
      notes: json['notes'] as String?,
      date: json['date'] as String?,
      elderId: json['elderId'] as String?,
      loggedByUserId: json['loggedByUserId'] as String?,
      loggedBy: json['loggedBy'] as String,
      stamp: (json['stamp'] as Timestamp?)?.toDate(),
      time: json['time'] as String?,
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  /// Converts this [SleepEntry] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'firestoreId': firestoreId,
      'wentToBed': wentToBed,
      'wokeUp': wokeUp,
      'totalDuration': totalDuration,
      'quality': quality,
      'naps': naps,
      'notes': notes,
      'date': date,
      'elderId': elderId,
      'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null,
      'time': time,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Factory constructor to create a [SleepEntry] from Firestore.
  factory SleepEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Missing data for SleepEntry from snapshot ${snapshot.id}',
      );
    }
    return SleepEntry(
      firestoreId: snapshot.id,
      wentToBed: data['wentToBed'] as String?,
      wokeUp: data['wokeUp'] as String?,
      totalDuration: data['totalDuration'] as String?,
      quality: data['quality'] as String?,
      naps: data['naps'] as String?,
      notes: data['notes'] as String?,
      date: data['date'] as String?,
      elderId: data['elderId'] as String?,
      loggedByUserId: data['loggedByUserId'] as String?,
      loggedBy: data['loggedByDisplayName'] as String? ?? 'Unknown User',
      stamp: (data['stamp'] as Timestamp?)?.toDate(),
      time: data['time'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Converts this [SleepEntry] to a Firestore map.
  Map<String, dynamic> toFirestore() {
    return {
      'wentToBed': wentToBed,
      if (wokeUp != null) 'wokeUp': wokeUp,
      if (totalDuration != null) 'totalDuration': totalDuration,
      'quality': quality,
      if (naps != null) 'naps': naps,
      if (notes != null) 'notes': notes,
      if (date != null) 'date': date,
      if (elderId != null) 'elderId': elderId,
      if (loggedByUserId != null) 'loggedByUserId': loggedByUserId,
      'loggedBy': loggedBy,
      'stamp': stamp != null ? Timestamp.fromDate(stamp!) : null,
      if (time != null) 'time': time,
      'createdAt': createdAt,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Alias for singular 'note' to match form expectations.
  String? get note => notes;
}
