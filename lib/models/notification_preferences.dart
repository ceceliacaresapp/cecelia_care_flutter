// lib/models/notification_preferences.dart

class NotificationPreferences {
  final bool meds;
  final bool calendar;
  final bool selfCare;
  final bool chatMessages;
  final bool generalDefault;

  NotificationPreferences({
    required this.meds,
    required this.calendar,
    required this.selfCare,
    required this.chatMessages,
    required this.generalDefault,
  });

  factory NotificationPreferences.defaultValues() {
    return NotificationPreferences(
      meds: true,
      calendar: true,
      selfCare: true,
      chatMessages: true,
      generalDefault: true,
    );
  }

  NotificationPreferences copyWith({
    bool? meds,
    bool? calendar,
    bool? selfCare,
    bool? chatMessages,
    bool? generalDefault,
  }) {
    return NotificationPreferences(
      meds: meds ?? this.meds,
      calendar: calendar ?? this.calendar,
      selfCare: selfCare ?? this.selfCare,
      chatMessages: chatMessages ?? this.chatMessages,
      generalDefault: generalDefault ?? this.generalDefault,
    );
  }
}
