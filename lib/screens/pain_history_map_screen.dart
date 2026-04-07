// lib/screens/pain_history_map_screen.dart
//
// Pain topography history view. Period selector → fetches all pain entries
// for the active elder in the window → renders them as a heatmap on the
// shared body silhouette + a region frequency table + a horizontal
// timeline strip of recent entries.

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

class PainHistoryMapScreen extends StatefulWidget {
  const PainHistoryMapScreen({super.key});

  @override
  State<PainHistoryMapScreen> createState() => _PainHistoryMapScreenState();
}

class _PainHistoryMapScreenState extends State<PainHistoryMapScreen> {
  int _days = 30; // 7 / 30 / 90
  String? _highlightEntryId;

  static const Color _accent = Color(0xFFE53935);

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (elder == null || uid.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pain History')),
        body: const Center(child: Text('No care recipient selected.')),
      );
    }
    final start = DateTime.now().subtract(Duration(days: _days));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pain History'),
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
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7d')),
        ButtonSegment(value: 30, label: Text('30d')),
        ButtonSegment(value: 90, label: Text('90d')),
      ],
      selected: {_days},
      onSelectionChanged: (s) => setState(() {
        _days = s.first;
        _highlightEntryId = null;
      }),
    );
  }

  Widget _summaryRow(int entryCount, int pointCount) {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            label: 'Pain entries',
            value: '$entryCount',
            color: _accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            label: 'Locations marked',
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
        borderRadius: BorderRadius.circular(10),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.healing_outlined, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 8),
          const Text('No pain markers in this window.',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Pain entries logged before the body map was added show only as text and won\'t appear here.',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _legendRow() {
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
        chip(2, 'Mild 1–3'),
        chip(5, 'Moderate 4–6'),
        chip(8, 'Severe 7–8'),
        chip(10, 'Extreme 9–10'),
      ],
    );
  }

  Widget _frequencyTable(List<MapEntry<String, _RegionStat>> data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Region frequency',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Timeline',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (_highlightEntryId != null)
              TextButton(
                onPressed: () => setState(() => _highlightEntryId = null),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Show all',
                    style: TextStyle(fontSize: 11)),
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
                    borderRadius: BorderRadius.circular(10),
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
                              borderRadius: BorderRadius.circular(8),
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
