// lib/screens/pain_history_map_screen.dart
//
// Pain topography history view. Period selector → fetches all pain entries
// for the active elder in the window → renders them as a heatmap on the
// shared body silhouette + a region frequency table + a horizontal
// timeline strip of recent entries.

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/pain_body_map.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';

class PainHistoryMapScreen extends StatefulWidget {
  const PainHistoryMapScreen({super.key});

  @override
  State<PainHistoryMapScreen> createState() => _PainHistoryMapScreenState();
}

class _PainHistoryMapScreenState extends State<PainHistoryMapScreen> {
  int _days = 30; // 7 / 30 / 90
  String? _highlightEntryId;

  static const Color _accent = AppTheme.statusRed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elder = context.watch<ActiveElderProvider>().activeElder;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (elder == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.painHistoryScreenTitle)),
        body: Center(child: Text(l10n.painHistoryNoCareRecipient)),
      );
    }
    final start = DateTime.now().subtract(Duration(days: _days));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.painHistoryScreenTitle),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: context.read<FirestoreService>().getJournalEntriesStream(
              elderId: elder.id,
              currentUserId: uid,
              startDate: start,
              endDate: DateTime.now(),
              type: EntryType.pain,
            ),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snap.data ?? const <JournalEntry>[];
          // Extract pain points (handles entries that pre-date the body
          // map by gracefully skipping ones with no painPoints field).
          final allPoints = <PainPoint>[];
          final pointsByEntry = <String, List<PainPoint>>{};
          for (final e in entries) {
            final raw = e.data?['painPoints'] as List?;
            if (raw == null) continue;
            final list = raw
                .whereType<Map>()
                .map((m) => PainPoint.fromMap(
                    Map<String, dynamic>.from(m)))
                .toList();
            if (list.isEmpty) continue;
            pointsByEntry[(e.id ?? '')] = list;
            allPoints.addAll(list);
          }

          // Region frequency aggregation
          final freq = <String, _RegionStat>{};
          for (final p in allPoints) {
            final s = freq.putIfAbsent(p.bodyRegion, () => _RegionStat());
            s.count += 1;
            s.totalIntensity += p.intensity;
            if (p.intensity > s.peakIntensity) s.peakIntensity = p.intensity;
          }
          final freqEntries = freq.entries.toList()
            ..sort((a, b) => b.value.count.compareTo(a.value.count));

          // Highlight only the selected entry, otherwise show all.
          final heatmapPoints = _highlightEntryId == null
              ? allPoints
              : (pointsByEntry[_highlightEntryId] ?? const []);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _periodSelector(),
              const SizedBox(height: 14),
              _summaryRow(entries.length, allPoints.length),
              const SizedBox(height: 14),
              if (allPoints.isEmpty)
                _emptyState()
              else ...[
                PainBodyMap(
                  readOnly: true,
                  heatmapPoints: heatmapPoints,
                  height: 420,
                ),
                const SizedBox(height: 14),
                _legendRow(),
                const SizedBox(height: 16),
                _frequencyTable(freqEntries),
                const SizedBox(height: 16),
                _timelineStrip(entries, pointsByEntry),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _periodSelector() {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<int>(
      segments: [
        ButtonSegment(value: 7, label: Text(l10n.painHistoryPeriod7Days)),
        ButtonSegment(value: 30, label: Text(l10n.painHistoryPeriod30Days)),
        ButtonSegment(value: 90, label: Text(l10n.painHistoryPeriod90Days)),
      ],
      selected: {_days},
      onSelectionChanged: (s) => setState(() {
        _days = s.first;
        _highlightEntryId = null;
      }),
    );
  }

  Widget _summaryRow(int entryCount, int pointCount) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _statBox(
            label: l10n.painHistorySummaryPainEntries,
            value: '$entryCount',
            color: _accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            label: l10n.painHistorySummaryLocationsMarked,
            value: '$pointCount',
            color: const Color(0xFFFF9800),
          ),
        ),
      ],
    );
  }

  Widget _statBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final l10n = AppLocalizations.of(context)!;
    return EmptyStateWidget(
      icon: Icons.healing_outlined,
      title: l10n.painHistoryEmptyTitle,
      subtitle: l10n.painHistoryEmptySubtitle,
    );
  }

  Widget _legendRow() {
    final l10n = AppLocalizations.of(context)!;
    Widget chip(int n, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: PainPoint.colorForIntensity(n),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: AppTheme.textSecondary)),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 4,
      children: [
        chip(2, l10n.painIntensityMildRange),
        chip(5, l10n.painIntensityModerateRange),
        chip(8, l10n.painIntensitySevereRange),
        chip(10, l10n.painIntensityExtremeRange),
      ],
    );
  }

  Widget _frequencyTable(List<MapEntry<String, _RegionStat>> data) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
            color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.painHistoryRegionFrequencyLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...data.map((e) {
            final stat = e.value;
            final avg = stat.count == 0
                ? 0
                : (stat.totalIntensity / stat.count).round();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: PainPoint.colorForIntensity(stat.peakIntensity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      PainPoint.labelForRegion(e.key),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('${stat.count} entries · avg $avg/10',
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _timelineStrip(
    List<JournalEntry> entries,
    Map<String, List<PainPoint>> pointsByEntry,
  ) {
    final sorted = [...entries]
      ..sort((a, b) => b.entryTimestamp
          .toDate()
          .compareTo(a.entryTimestamp.toDate()));
    final withPoints =
        sorted.where((e) => pointsByEntry.containsKey((e.id ?? ''))).toList();
    if (withPoints.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.painHistoryTimelineLabel,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (_highlightEntryId != null)
              TextButton(
                onPressed: () => setState(() => _highlightEntryId = null),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(l10n.painHistoryShowAllButton,
                    style: const TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: withPoints.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final entry = withPoints[i];
              final points = pointsByEntry[(entry.id ?? '')]!;
              final peak = points
                  .map((p) => p.intensity)
                  .reduce((a, b) => a > b ? a : b);
              final selected = _highlightEntryId == (entry.id ?? '');
              final color = PainPoint.colorForIntensity(peak);
              return GestureDetector(
                onTap: () => setState(() {
                  _highlightEntryId =
                      selected ? null : (entry.id ?? '');
                }),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.18)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    border: Border.all(
                      color: selected ? color : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMM d')
                            .format(entry.entryTimestamp.toDate()),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        DateFormat('h:mm a')
                            .format(entry.entryTimestamp.toDate()),
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Text(
                              '$peak/10',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${points.length} pt${points.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RegionStat {
  int count = 0;
  int totalIntensity = 0;
  int peakIntensity = 0;
}
