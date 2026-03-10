// lib/models/notification_prefs.dart

class NotificationPrefs {
  bool meds;
  bool calendar;
  bool selfCare;
  bool chatMessages;
  bool generalDefault;
  // --- FIX ---
  // Added the missing healthReminders field.
  bool healthReminders;

  NotificationPrefs({
    required this.meds,
    required this.calendar,
    required this.selfCare,
    required this.chatMessages,
    required this.generalDefault,
    // --- FIX ---
    // Added to the constructor.
    required this.healthReminders,
  });

  factory NotificationPrefs.defaultPrefs() {
    return NotificationPrefs(
      meds: true,
      calendar: true,
      selfCare: true,
      chatMessages: true,
      generalDefault: true,
      // --- FIX ---
      // Set a default value.
      healthReminders: true,
    );
  }

  // fromJson factory for deserialization
  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      meds: json['meds'] as bool? ?? true,
      calendar: json['calendar'] as bool? ?? true,
      selfCare: json['selfCare'] as bool? ?? true,
      chatMessages: json['chatMessages'] as bool? ?? true,
      generalDefault: json['generalDefault'] as bool? ?? true,
      // --- FIX ---
      // Handled deserialization for the new field.
      healthReminders: json['healthReminders'] as bool? ?? true,
    );
  }

  // toJson method for serialization
  Map<String, dynamic> toJson() {
    return {
      'meds': meds,
      'calendar': calendar,
      'selfCare': selfCare,
      'chatMessages': chatMessages,
      'generalDefault': generalDefault,
      // --- FIX ---
      // Added the new field to serialization.
      'healthReminders': healthReminders,
    };
  }

  // copyWith can still be useful for immutable updates if needed later.
  NotificationPrefs copyWith({
    bool? meds,
    bool? calendar,
    bool? selfCare,
    bool? chatMessages,
    bool? generalDefault,
    // --- FIX ---
    // Added to the copyWith method for completeness.
    bool? healthReminders,
  }) {
    return NotificationPrefs(
      meds: meds ?? this.meds,
      calendar: calendar ?? this.calendar,
      selfCare: selfCare ?? this.selfCare,
      chatMessages: chatMessages ?? this.chatMessages,
      generalDefault: generalDefault ?? this.generalDefault,
      healthReminders: healthReminders ?? this.healthReminders,
    );
  }
}