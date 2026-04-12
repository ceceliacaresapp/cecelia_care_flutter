// lib/widgets/multi_elder_timeline_badge.dart
//
// Small colored chip showing which elder a timeline entry belongs to.
// Only displayed in multi-elder view mode.

import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';

class MultiElderTimelineBadge extends StatelessWidget {
  const MultiElderTimelineBadge({
    super.key,
    required this.elder,
    required this.elderIndex,
  });

  final ElderProfile elder;
  final int elderIndex;

  static const List<Color> _palette = [
    AppTheme.tileBlue,
    AppTheme.statusRed,
    AppTheme.statusGreen,
    AppTheme.tileOrange,
    AppTheme.tilePurple,
    AppTheme.tileTeal,
    AppTheme.tileIndigo,
    AppTheme.tileRedDeep,
  ];

  @override
  Widget build(BuildContext context) {
    final color = _palette[elderIndex % _palette.length];
    final name = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;
    final shortName = name.length > 10 ? '${name.substring(0, 8)}..' : name;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(shortName,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
