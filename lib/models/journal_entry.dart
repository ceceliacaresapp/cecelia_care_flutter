import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';

class JournalEntry {
  final String? id;
  final String? elderId;
  final EntryType type;

  final String loggedByUserId;
  final String? loggedByDisplayName;
  final String? loggedByUserAvatarUrl;

  final Timestamp entryTimestamp;
  final String dateString;

  final String? text;
  final Map<String, dynamic>? data;

  final List<String>? visibleToUserIds;
  final bool? isPublic;

  final bool isCaregiverJournal;

  /// Reactions map: { uid: Timestamp } — caregivers acknowledging this entry.
  final Map<String, dynamic> reactions;

  int get reactionCount => reactions.length;
  List<String> get reactedByUids => reactions.keys.toList();
  bool hasReactedBy(String uid) => reactions.containsKey(uid);

  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  JournalEntry({
    this.id,
    this.elderId,
    required this.type,
    required this.loggedByUserId,
    this.loggedByDisplayName,
    this.loggedByUserAvatarUrl,
    required this.entryTimestamp,
    required this.dateString,
    this.text,
    this.data,
    this.visibleToUserIds,
    this.isPublic,
    this.createdAt,
    this.updatedAt,
    this.isCaregiverJournal = false,
    this.reactions = const {},
  });

  factory JournalEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final map = snapshot.data();
    if (map == null) {
      throw StateError('Missing data for JournalEntry ${snapshot.id}');
    }
    final Map<String, dynamic> jsonData = Map.from(map);
    jsonData['id'] = snapshot.id;
    return JournalEntry.fromJson(jsonData);
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    EntryType parsedType;
    try {
      parsedType = EntryType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EntryType.pain,
      );
    } catch (e) {
      // FIX: was print() — flagged by analyzer as avoid_print.
      // debugPrint is stripped in release builds and is the correct tool here.
      debugPrint(
        'Warning: Invalid or missing EntryType for JournalEntry '
        '${json['id']}. Defaulting to pain. Error: $e',
      );
      parsedType = EntryType.pain;
    }

    return JournalEntry(
      id: json['id'] as String?,
      elderId: json['elderId'] as String?,
      type: parsedType,
      loggedByUserId: json['loggedByUserId'] as String,
      loggedByDisplayName: json['loggedByDisplayName'] as String?,
      loggedByUserAvatarUrl: json['loggedByUserAvatarUrl'] as String?,
      entryTimestamp:
          (json['entryTimestamp'] as Timestamp?) ?? Timestamp.now(),
      dateString: json['dateString'] as String,
      text: json['text'] as String?,
      data: json['data'] as Map<String, dynamic>?,
      visibleToUserIds:
          (json['visibleToUserIds'] as List<dynamic>?)?.cast<String>(),
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
      isCaregiverJournal: json['isCaregiverJournal'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, Object?> toFirestore() {
    return {
      if (elderId != null) 'elderId': elderId,
      'type': type.name,
      'loggedByUserId': loggedByUserId,
      if (loggedByDisplayName != null)
        'loggedByDisplayName': loggedByDisplayName,
      if (loggedByUserAvatarUrl != null)
        'loggedByUserAvatarUrl': loggedByUserAvatarUrl,
      'entryTimestamp': entryTimestamp,
      'dateString': dateString,
      if (text != null) 'text': text,
      if (data != null) 'data': data,
      if (visibleToUserIds != null) 'visibleToUserIds': visibleToUserIds,
      if (isPublic != null) 'isPublic': isPublic,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isCaregiverJournal': isCaregiverJournal,
      if (reactions.isNotEmpty) 'reactions': reactions,
    };
  }

  JournalEntry copyWith({
    String? id,
    String? elderId,
    EntryType? type,
    String? loggedByUserId,
    String? loggedByDisplayName,
    String? loggedByUserAvatarUrl,
    Timestamp? entryTimestamp,
    String? dateString,
    String? text,
    Map<String, dynamic>? data,
    List<String>? visibleToUserIds,
    bool? isPublic,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? isCaregiverJournal,
    Map<String, dynamic>? reactions,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      elderId: elderId ?? this.elderId,
      type: type ?? this.type,
      loggedByUserId: loggedByUserId ?? this.loggedByUserId,
      loggedByDisplayName:
          loggedByDisplayName ?? this.loggedByDisplayName,
      loggedByUserAvatarUrl:
          loggedByUserAvatarUrl ?? this.loggedByUserAvatarUrl,
      entryTimestamp: entryTimestamp ?? this.entryTimestamp,
      dateString: dateString ?? this.dateString,
      text: text ?? this.text,
      data: data ?? this.data,
      visibleToUserIds: visibleToUserIds ?? this.visibleToUserIds,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isCaregiverJournal:
          isCaregiverJournal ?? this.isCaregiverJournal,
      reactions: reactions ?? this.reactions,
    );
  }
}
