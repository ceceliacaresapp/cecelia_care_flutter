import 'package:flutter/material.dart';
import '../models/daily_mood.dart';

class MoodHistoryStrip extends StatelessWidget {
  final List<DailyMood> days;
  const MoodHistoryStrip({super.key, required this.days});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 80,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final d = days[i];
        final label = '${d.date.month}/${d.date.day}';
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(d.emoji, style: const TextStyle(fontSize: 28)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    ),
  );
}
