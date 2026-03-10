import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart'; // Import the base class

class MessageEntry extends JournalEntry {
  // Specific fields for MessageEntry
  @override
  final String? text; // The content of the message

  // Common fields from JournalEntry are inherited:
  // id, elderId, type, loggedByUserId, loggedByDisplayName,
  // loggedByUserAvatarUrl, entryTimestamp, dateString,
  // visibleToUserIds, isPublic, createdAt, updatedAt

  MessageEntry({
    // Message-specific fields
    this.text,

    // Common JournalEntry fields passed to super constructor
    super.id,
    required String super.elderId,
    required super.loggedByUserId,
    super.loggedByDisplayName,
    super.loggedByUserAvatarUrl,
    required super.entryTimestamp,
    required super.dateString,
    super.visibleToUserIds,
    super.isPublic,
    super.createdAt,
    super.updatedAt,
  }) : super(
          type: EntryType.message,
        );

  /// Creates a [MessageEntry] from a standard JSON map.
  factory MessageEntry.fromJson(Map<String, dynamic> json) {
    return MessageEntry(
      // Message-specific fields
      text: json['text'] as String?,

      // Common JournalEntry fields
      id: json['id'] as String? ?? json['firestoreId'] as String?,
      elderId: json['elderId'] as String,
      loggedByUserId: json['loggedByUserId'] as String,
      loggedByDisplayName: json['loggedByDisplayName'] as String?,
      loggedByUserAvatarUrl: json['loggedByUserAvatarUrl'] as String?,
      entryTimestamp: (json['entryTimestamp'] as Timestamp?) ?? Timestamp.now(),
      dateString: json['dateString'] as String? ?? '',
      visibleToUserIds: (json['visibleToUserIds'] as List<dynamic>?)?.cast<String>(),
      isPublic: json['isPublic'] as bool? ?? true, // Default to public if not specified
      createdAt: json['createdAt'] as Timestamp?,
      updatedAt: json['updatedAt'] as Timestamp?,
    );
  }

  /// Converts this [MessageEntry] instance to a JSON map for generic use.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'elderId': elderId,
      'type': type.name,
      'loggedByUserId': loggedByUserId,
      'loggedByDisplayName': loggedByDisplayName,
      'loggedByUserAvatarUrl': loggedByUserAvatarUrl,
      'entryTimestamp': entryTimestamp.toDate().toIso8601String(),
      'dateString': dateString,
      'visibleToUserIds': visibleToUserIds,
      'isPublic': isPublic,
      'createdAt': createdAt?.toDate().toIso8601String(),
      'updatedAt': updatedAt?.toDate().toIso8601String(),
      // Message-specific fields
      'text': text,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }

  // Factory constructor to create a MessageEntry from a Firestore document
  factory MessageEntry.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? _,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Missing data for MessageEntry from snapshot ${snapshot.id}');
    }
    final Map<String, dynamic> jsonDataWithId = Map.from(data);
    jsonDataWithId['id'] = snapshot.id;
    return MessageEntry.fromJson(jsonDataWithId);
  }

  @override
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
  }) {
    return MessageEntry(
      text: text ?? this.text,
      id: id ?? this.id,
      elderId: elderId ?? this.elderId!,
      loggedByUserId: loggedByUserId ?? this.loggedByUserId,
      loggedByDisplayName: loggedByDisplayName ?? this.loggedByDisplayName,
      loggedByUserAvatarUrl: loggedByUserAvatarUrl ?? this.loggedByUserAvatarUrl,
      entryTimestamp: entryTimestamp ?? this.entryTimestamp,
      dateString: dateString ?? this.dateString,
      visibleToUserIds: visibleToUserIds ?? this.visibleToUserIds,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}