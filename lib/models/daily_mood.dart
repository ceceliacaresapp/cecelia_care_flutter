class DailyMood {
  final DateTime date;
  final String emoji;

  DailyMood({required this.date, required this.emoji});

  factory DailyMood.fromDoc(String docId, Map<String, dynamic> json) =>
      DailyMood(
        date: DateTime.parse(docId),
        emoji: json['moodEmoji'] as String,
      );
}
