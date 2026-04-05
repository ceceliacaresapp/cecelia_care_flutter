// lib/models/turning_log.dart
//
// Lightweight model for repositioning events. Immutable clinical records.
// Stored in elderProfiles/{elderId}/turningLogs.

import 'package:cloud_firestore/cloud_firestore.dart';

class TurningLog {
  final String? id;
  final String elderId;
  final String loggedBy;
  final String loggedByName;
  final Timestamp timestamp;
  final String position;
  final bool skinCheckDone;
  final String? skinNotes;
  final String? linkedWoundEntryId;

  const TurningLog({
    this.id,
    required this.elderId,
    required this.loggedBy,
    required this.loggedByName,
    required this.timestamp,
    required this.position,
    this.skinCheckDone = false,
    this.skinNotes,
    this.linkedWoundEntryId,
  });

  static const Map<String, String> kPositionLabels = {
    'leftSide': 'Left Side',
    'rightSide': 'Right Side',
    'back': 'Back (Supine)',
    'prone': 'Prone (Face Down)',
    'seated': 'Seated / Chair',
    'elevated30': 'Elevated 30\u00B0',
    'elevated45': 'Elevated 45\u00B0',
  };

  static const Map<String, String> kPositionIcons = {
    'leftSide': '\u2B05',
    'rightSide': '\u27A1',
    'back': '\u2B07',
    'prone': '\u2B06',
    'seated': '\uD83E\uDE91',
    'elevated30': '\u2197',
    'elevated45': '\u2197',
  };

  String get positionLabel =>
      kPositionLabels[position] ?? position;

  String get positionIcon =>
      kPositionIcons[position] ?? '\uD83D\uDD04';

  factory TurningLog.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return TurningLog(
      id: docId,
      elderId: data['elderId'] as String? ?? '',
      loggedBy: data['loggedBy'] as String? ?? '',
      loggedByName: data['loggedByName'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?) ?? Timestamp.now(),
      position: data['position'] as String? ?? 'back',
      skinCheckDone: data['skinCheckDone'] as bool? ?? false,
      skinNotes: data['skinNotes'] as String?,
      linkedWoundEntryId: data['linkedWoundEntryId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'elderId': elderId,
        'loggedBy': loggedBy,
        'loggedByName': loggedByName,
        'timestamp': timestamp,
        'position': position,
        'skinCheckDone': skinCheckDone,
        if (skinNotes != null && skinNotes!.isNotEmpty) 'skinNotes': skinNotes,
        if (linkedWoundEntryId != null)
          'linkedWoundEntryId': linkedWoundEntryId,
      };
}
