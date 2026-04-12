// lib/widgets/med_schedule_timeline.dart
//
// A 24-hour visual timeline showing medications at their scheduled times.
// Groups into Morning/Afternoon/Evening/Night bands with a "Now" indicator.
// Reads from MedicationDefinitionsProvider — pure UI, no backend changes.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_provider.dart';
import 'package:cecelia_care_flutter/screens/medications/medication_manager_screen.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/services/rxnav_service.dart';
import 'package:cecelia_care_flutter/locator.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// ── Time-of-day band definitions ──────────────────────────────────
class _TimeBand {
  final String label;
  final IconData icon;
  final Color color;
  final int startHour; // inclusive
  final int endHour;   // exclusive

  const _TimeBand({
    required this.label,
    required this.icon,
    required this.color,
    required this.startHour,
    required this.endHour,
  });

  bool contains(int hour) {
    if (startHour < endHour) {
      return hour >= startHour && hour < endHour;
    }
    // Overnight wrap: 21:00–4:59
    return hour >= startHour || hour < endHour;
  }
}

const _bands = [
  _TimeBand(
    label: 'Morning',
    icon: Icons.wb_sunny_outlined,
    color: AppTheme.tileBlue,
    startHour: 5,
    endHour: 12,
  ),
  _TimeBand(
    label: 'Afternoon',
    icon: Icons.wb_cloudy_outlined,
    color: AppTheme.tileOrange,
    startHour: 12,
    endHour: 17,
  ),
  _TimeBand(
    label: 'Evening',
    icon: Icons.nights_stay_outlined,
    color: AppTheme.tilePurple,
    startHour: 17,
    endHour: 21,
  ),
  _TimeBand(
    label: 'Night',
    icon: Icons.bedtime_outlined,
    color: AppTheme.tileIndigo,
    startHour: 21,
    endHour: 5,
  ),
];

class MedScheduleTimeline extends StatelessWidget {
  const MedScheduleTimeline({super.key});

  @override
  Widget build(BuildContext context) {
    final medProv = context.watch<MedicationDefinitionsProvider>();
    final allMeds = medProv.medDefinitions;

    if (allMeds.isEmpty) {
      return _EmptyState(onTap: () => _openMedManager(context));
    }

    // Separate scheduled vs unscheduled
    final scheduled = allMeds
        .where((m) => m.defaultTime != null && m.defaultTime!.isNotEmpty)
        .toList()
      ..sort((a, b) => (a.defaultTime ?? '').compareTo(b.defaultTime ?? ''));
    final unscheduled = allMeds
        .where((m) => m.defaultTime == null || m.defaultTime!.isEmpty)
        .toList();

    // Group scheduled meds into bands
    final Map<_TimeBand, List<MedicationDefinition>> grouped = {};
    for (final med in scheduled) {
      final hour = _parseHour(med.defaultTime!);
      final band = _bands.firstWhere(
        (b) => b.contains(hour),
        orElse: () => _bands[0], // fallback to morning
      );
      grouped.putIfAbsent(band, () => []).add(med);
    }

    final now = TimeOfDay.now();
    final nowFormatted = DateFormat('h:mm a').format(
      DateTime(2026, 1, 1, now.hour, now.minute),
    );

    return GestureDetector(
      onTap: () => _openMedManager(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.tileBlue.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.tileBlue.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.tileBlue.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.tileBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.schedule_outlined,
                      color: AppTheme.tileBlue, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Med Schedule',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tileBlue,
                    ),
                  ),
                ),
                Text(
                  '${allMeds.length} med${allMeds.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.tileBlue.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.tileBlue.withValues(alpha: 0.4)),
              ],
            ),
            const SizedBox(height: 14),

            // "Now" indicator
            _NowIndicator(label: nowFormatted, nowHour: now.hour),
            const SizedBox(height: 12),

            // Time bands with medications
            ...List.generate(_bands.length, (i) {
              final band = _bands[i];
              final meds = grouped[band];
              if (meds == null || meds.isEmpty) {
                return const SizedBox.shrink();
              }
              return _BandSection(
                band: band,
                meds: meds,
                isActive: band.contains(now.hour),
              );
            }),

            // Unscheduled meds
            if (unscheduled.isNotEmpty) ...[
              const SizedBox(height: 6),
              _UnscheduledSection(meds: unscheduled),
            ],
          ],
        ),
      ),
    );
  }

  void _openMedManager(BuildContext context) {
    final activeElder =
        context.read<ActiveElderProvider>().activeElder;
    if (activeElder == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<MedicationDefinitionsProvider>(
              create: (_) => MedicationDefinitionsProvider()
                ..updateForElder(activeElder),
            ),
            ChangeNotifierProvider<MedicationProvider>(
              create: (ctx) => MedicationProvider(
                elderId: activeElder.id,
                firestoreService: ctx.read<FirestoreService>(),
                rxNavService: locator<RxNavService>(),
                medDefsProvider:
                    ctx.read<MedicationDefinitionsProvider>(),
                elderName: activeElder.profileName,
              ),
            ),
          ],
          child: const MedicationManagerScreen(),
        ),
      ),
    );
  }

  static int _parseHour(String time) {
    try {
      final parts = time.split(':');
      return int.parse(parts[0]);
    } catch (_) {
      return 8; // fallback
    }
  }
}

// ---------------------------------------------------------------------------
// "Now" indicator — red dot + time label with a horizontal line
// ---------------------------------------------------------------------------
class _NowIndicator extends StatelessWidget {
  const _NowIndicator({required this.label, required this.nowHour});
  final String label;
  final int nowHour;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.statusRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.statusRed.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Now — $label',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.statusRed,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Band section — one time-of-day group
// ---------------------------------------------------------------------------
class _BandSection extends StatelessWidget {
  const _BandSection({
    required this.band,
    required this.meds,
    required this.isActive,
  });

  final _TimeBand band;
  final List<MedicationDefinition> meds;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left gutter: band icon + time range
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isActive
                        ? band.color.withValues(alpha: 0.15)
                        : band.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: isActive
                        ? Border.all(
                            color: band.color.withValues(alpha: 0.4),
                            width: 1.5)
                        : null,
                  ),
                  child: Icon(band.icon, size: 16, color: band.color),
                ),
                const SizedBox(height: 3),
                Text(
                  band.label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? band.color
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Vertical connector line
          Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 2,
                height: meds.length * 38.0 + 4,
                decoration: BoxDecoration(
                  color: band.color.withValues(alpha: isActive ? 0.25 : 0.12),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Med chips
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: meds
                  .map((med) => _MedChip(
                        med: med,
                        color: band.color,
                        isActive: isActive,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual medication chip
// ---------------------------------------------------------------------------
class _MedChip extends StatelessWidget {
  const _MedChip({
    required this.med,
    required this.color,
    required this.isActive,
  });

  final MedicationDefinition med;
  final Color color;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final timeLabel = _formatTime(med.defaultTime ?? '');
    final hasLowPills = med.pillCount != null &&
        med.refillThreshold != null &&
        med.pillCount! <= med.refillThreshold!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.25)
                : AppTheme.textLight.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            // Time
            SizedBox(
              width: 52,
              child: Text(
                timeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            // Pill icon
            Icon(Icons.medication_outlined,
                size: 14, color: color.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            // Name + dose
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (med.dose != null && med.dose!.isNotEmpty)
                    Text(
                      med.dose!,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Status icons
            if (med.reminderEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.notifications_active_outlined,
                    size: 13, color: color.withValues(alpha: 0.5)),
              ),
            if (hasLowPills)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.statusRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${med.pillCount}',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.statusRed,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final min = parts.length > 1 ? int.parse(parts[1]) : 0;
      final dt = DateTime(2026, 1, 1, hour, min);
      return DateFormat('h:mm a').format(dt);
    } catch (_) {
      return time;
    }
  }
}

// ---------------------------------------------------------------------------
// Unscheduled meds section
// ---------------------------------------------------------------------------
class _UnscheduledSection extends StatelessWidget {
  const _UnscheduledSection({required this.meds});
  final List<MedicationDefinition> meds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.textLight.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_outlined,
                  size: 13, color: AppTheme.textLight),
              const SizedBox(width: 6),
              Text(
                'No time set',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: meds.map((med) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.medication_outlined,
                        size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      med.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (med.dose != null && med.dose!.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        med.dose!,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.medication_outlined,
                size: 28, color: AppTheme.textLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No medications added yet — tap to get started',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
            Icon(Icons.add_circle_outline,
                size: 20, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
