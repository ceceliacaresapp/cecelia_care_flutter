class SelfCareReminder {
  final String id; // hydrate | stretch | walk
  final String? timeOfDay; // "HH:mm", null = off

  SelfCareReminder({required this.id, this.timeOfDay});

  factory SelfCareReminder.fromJson(Map<String, dynamic> json) =>
      SelfCareReminder(
        id: json['id'] as String,
        timeOfDay: json['timeOfDay'] as String?,
      );

  Map<String, dynamic> toJson() => {'id': id, 'timeOfDay': timeOfDay};
}
