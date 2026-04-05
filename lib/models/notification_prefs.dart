// lib/models/notification_prefs.dart

class NotificationPrefs {
  bool meds;
  bool calendar;
  bool selfCare;
  bool chatMessages;
  bool generalDefault;
  bool healthReminders;
  bool sundowningAlert;
  bool repositioningReminder;
  bool weightAlerts;
  bool burnoutNudges;

  NotificationPrefs({
    required this.meds,
    required this.calendar,
    required this.selfCare,
    required this.chatMessages,
    required this.generalDefault,
    required this.healthReminders,
    required this.sundowningAlert,
    required this.repositioningReminder,
    required this.weightAlerts,
    required this.burnoutNudges,
  });

  factory NotificationPrefs.defaultPrefs() {
    return NotificationPrefs(
      meds: true,
      calendar: true,
      selfCare: true,
      chatMessages: true,
      generalDefault: true,
      healthReminders: true,
      sundowningAlert: false,
      repositioningReminder: false,
      weightAlerts: true,
      burnoutNudges: true,
    );
  }

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      meds: json['meds'] as bool? ?? true,
      calendar: json['calendar'] as bool? ?? true,
      selfCare: json['selfCare'] as bool? ?? true,
      chatMessages: json['chatMessages'] as bool? ?? true,
      generalDefault: json['generalDefault'] as bool? ?? true,
      healthReminders: json['healthReminders'] as bool? ?? true,
      sundowningAlert: json['sundowningAlert'] as bool? ?? false,
      repositioningReminder: json['repositioningReminder'] as bool? ?? false,
      weightAlerts: json['weightAlerts'] as bool? ?? true,
      burnoutNudges: json['burnoutNudges'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'meds': meds,
      'calendar': calendar,
      'selfCare': selfCare,
      'chatMessages': chatMessages,
      'generalDefault': generalDefault,
      'healthReminders': healthReminders,
      'sundowningAlert': sundowningAlert,
      'repositioningReminder': repositioningReminder,
      'weightAlerts': weightAlerts,
      'burnoutNudges': burnoutNudges,
    };
  }

  NotificationPrefs copyWith({
    bool? meds,
    bool? calendar,
    bool? selfCare,
    bool? chatMessages,
    bool? generalDefault,
    bool? healthReminders,
    bool? sundowningAlert,
    bool? repositioningReminder,
    bool? weightAlerts,
    bool? burnoutNudges,
  }) {
    return NotificationPrefs(
      meds: meds ?? this.meds,
      calendar: calendar ?? this.calendar,
      selfCare: selfCare ?? this.selfCare,
      chatMessages: chatMessages ?? this.chatMessages,
      generalDefault: generalDefault ?? this.generalDefault,
      healthReminders: healthReminders ?? this.healthReminders,
      sundowningAlert: sundowningAlert ?? this.sundowningAlert,
      repositioningReminder: repositioningReminder ?? this.repositioningReminder,
      weightAlerts: weightAlerts ?? this.weightAlerts,
      burnoutNudges: burnoutNudges ?? this.burnoutNudges,
    );
  }
}