// lib/widgets/elder_view_toggle.dart
//
// Compact toggle for the AppBar: switch between viewing one elder or all.
// Only visible when the user has 2+ assigned elders.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';

class ElderViewToggle extends StatelessWidget {
  const ElderViewToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ActiveElderProvider>();
    final allElders = provider.allElders;

    // Only show when 2+ elders assigned.
    if (allElders.length < 2) return const SizedBox.shrink();

    final isSingle = provider.viewMode == ElderViewMode.single;
    final elder = provider.activeElder;
    final elderName = elder?.preferredName?.isNotEmpty == true
        ? elder!.preferredName!
        : elder?.profileName ?? '';
    final photoUrl = elder?.photoUrl;
    // Truncate long names for the pill.
    final displayName =
        elderName.length > 12 ? '${elderName.substring(0, 10)}...' : elderName;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Single elder segment
          _Segment(
            label: displayName,
            icon: photoUrl != null && photoUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 10,
                    backgroundImage: NetworkImage(photoUrl),
                  )
                : CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Text(
                      elderName.isNotEmpty ? elderName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
            isSelected: isSingle,
            onTap: () => provider.setViewMode(ElderViewMode.single),
          ),
          // All elders segment
          _Segment(
            label: 'All (${allElders.length})',
            icon: null,
            isSelected: !isSingle,
            onTap: () => provider.setViewMode(ElderViewMode.all),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
