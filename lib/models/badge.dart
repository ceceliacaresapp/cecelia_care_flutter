class Badge {
  final String id; // e.g., "first_mood_log", "medication_maestro_10"
  final String label; // User-facing name, e.g., "Mood Monitor"
  final String imagePath; // Path to the PNG asset, e.g., "assets/images/badges/mood_monitor.png"
  final String description; // Explanation of how the badge is earned
  final bool unlocked;

  const Badge({
    required this.id,
    required this.label,
    required this.imagePath,
    required this.description,
    this.unlocked = false,
  });

  Badge copyWith({
    String? id,
    String? label,
    String? imagePath,
    String? description,
    bool? unlocked,
  }) {
    return Badge(
      id: id ?? this.id,
      label: label ?? this.label,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      unlocked: unlocked ?? this.unlocked,
    );
  }
}
