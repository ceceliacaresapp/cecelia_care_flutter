import 'package:flutter/material.dart' hide Badge;
import '../models/badge.dart';

class BadgeTitle extends StatelessWidget {
  final Badge badge;
  const BadgeTitle({super.key, required this.badge});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Opacity(
        opacity: badge.unlocked ? 1.0 : 0.2,
        child: Image.asset(
          badge.imagePath,
          width: 40,
          height: 40,
        ), // Opacity removed from TextStyle
      ),
      Text(badge.label, style: const TextStyle(fontSize: 12)),
    ],
  );
}
