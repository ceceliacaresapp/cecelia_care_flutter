// lib/screens/sleep_rhythm_screen.dart
//
// Sleep-Wake Rhythm Tracker — chronobiological visualization built from
// the app's existing sleep + night-waking + behavioral data.
//
// Layout:
//   1. Hero radial chart for the selected day.
//   2. 7 / 14 / 30-day range chips.
//   3. Summary stats (avg sleep, avg bedtime, avg wake, fragmentation,
//      fragmented-nights-followed-by-behavior correlation).
//   4. Stacked per-day strip: small radial + text for each day in range.
//   5. Log shortcuts — "Log sleep" and "Log waking" routed to the
//      existing forms; "Log nap" writes directly with isNap=true.
//   6. PDF export for doctor visits.

import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/sleep_rhythm.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/ai_suggestion_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/sleep_rhythm_radial.dart';

const Color _kAccent = AppTheme.tileIndigo;
const Color _kAccentDeep = AppTheme.tileIndigoDeep;

class SleepRhythmScreen extends StatefulWidget {
  const SleepRhythmScreen({super.key});

  @override
  State<SleepRhythmScreen> createState() => _SleepRhythmScreenState();
}

class _SleepRhythmScreenState extends State<SleepRhythmScreen> {
  int _rangeDays = 7;
  DateTime? _selectedAnchor;
  bool _aiBusy = false;

  @override
  Widget build(BuildContext context) {
    final elderProv = context.watch<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    final canLog = elderProv.currentUserRole.canLog;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sleep-Wake Rhythm'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No care recipient selected.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep-Wake Rhythm'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Share as PDF',
            onPressed: () => _sharePdf(elder),
          ),
        ],
      ),
      body: _RhythmBody(
        elder: elder,
        rangeDays: _rangeDays,
        selectedAnchor: _selectedAnchor,
        canLog: canLog,
        onRangeChange: (d) => setState(() {
          _rangeDays = d;
          _selectedAnchor = null;
        }),
        onDaySelected: (a) => setState(() => _selectedAnchor = a),
        onLogNap: canLog ? () => _logNap(elder) : null,
        onAskAi: _aiBusy ? null : () => _askAi(elder),
        aiBusy: _aiBusy,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  Future<void> _sharePdf(ElderProfile elder) async {
    try {
      final rhythm = await _loadRhythmOnce(elder, _rangeDays);
      final bytes = await _buildPdf(elder, rhythm);
      final dir = await getTemporaryDirectory();
      final safeName = (elder.preferredName?.isNotEmpty == true
              ? elder.preferredName!
              : elder.profileName)
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
      final file = File(
          '${dir.path}/Sleep_Rhythm_${safeName.isEmpty ? 'report' : safeName}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Sleep rhythm — ${elder.preferredName ?? elder.profileName}',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('SleepRhythm PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  Future<SleepRhythm> _loadRhythmOnce(ElderProfile elder, int days) async {
    final firestore = context.read<FirestoreService>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SleepRhythm(days: []);
    }
    final start = DateTime.now().subtract(Duration(days: days));
    final sleep = await firestore
        .getJournalEntriesStream(
          elderId: elder.id,
          currentUserId: user.uid,
          startDate: start,
          type: EntryType.sleep,
        )
        .first;
    final wakings = await firestore
        .getJournalEntriesStream(
          elderId: elder.id,
          currentUserId: user.uid,
          startDate: start,
          type: EntryType.nightWaking,
        )
        .first;
    final behavioral =
        await firestore.getBehavioralEntriesStream(elder.id).first;

    return SleepRhythm.compute(
      sleepEntries: sleep,
      nightWakingEntries: wakings,
      behavioralEntries: behavioral,
      daysCount: days,
    );
  }

  Future<Uint8List> _buildPdf(ElderProfile elder, SleepRhythm rhythm) async {
    final pdf = pw.Document();
    final displayName = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;
    final dateStamp = DateFormat('MMMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#EEF1FA'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#3949AB'), width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SLEEP-WAKE RHYTHM REPORT',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1A237E'),
                    letterSpacing: 2.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  displayName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#1A237E'),
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfMeta('Window',
                    'Last ${rhythm.days.length} days through $dateStamp'),
                if (rhythm.averageTotalSleep != null)
                  _pdfMeta('Avg total sleep',
                      _fmtDuration(rhythm.averageTotalSleep!)),
                if (rhythm.averageBedtimeMinutesFromSixPm != null)
                  _pdfMeta(
                      'Avg bedtime',
                      _fmtMinutesFromSixPm(
                          rhythm.averageBedtimeMinutesFromSixPm!)),
                if (rhythm.averageWakeMinutesFromMidnight != null)
                  _pdfMeta(
                      'Avg wake',
                      _fmtMinutesFromMidnight(
                          rhythm.averageWakeMinutesFromMidnight!)),
                if (rhythm.averageFragmentation != null)
                  _pdfMeta('Avg fragmentation score',
                      '${rhythm.averageFragmentation!.toStringAsFixed(0)} / 100'),
                if (rhythm.averageWakings != null)
                  _pdfMeta('Avg wakings / night',
                      rhythm.averageWakings!.toStringAsFixed(1)),
                _pdfMeta(
                    'Fragmented nights followed by a behavioral event',
                    '${rhythm.fragmentedNightsFollowedByBehavior} of ${rhythm.days.length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          _pdfSectionHeader('NIGHT-BY-NIGHT SUMMARY'),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.6),
              1: pw.FlexColumnWidth(1.3),
              2: pw.FlexColumnWidth(1.3),
              3: pw.FlexColumnWidth(1.1),
              4: pw.FlexColumnWidth(1.0),
              5: pw.FlexColumnWidth(1.3),
              6: pw.FlexColumnWidth(1.4),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: [
                  'Date',
                  'Bedtime',
                  'Wake',
                  'Total',
                  'Wakings',
                  'Fragmentation',
                  'Behavior w/in 8h',
                ]
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              for (final d in rhythm.days)
                pw.TableRow(
                  children: [
                    _pdfCell(DateFormat('EEE MMM d').format(d.anchor)),
                    _pdfCell(d.mainSleep == null
                        ? '—'
                        : _fmtClock(d.mainSleep!.start)),
                    _pdfCell(d.mainSleep == null
                        ? '—'
                        : _fmtClock(d.mainSleep!.end)),
                    _pdfCell(_fmtDuration(d.totalSleep)),
                    _pdfCell('${d.wakings.length}'),
                    _pdfCell('${d.fragmentationScore.toStringAsFixed(0)} · '
                        '${d.fragmentationLabel}'),
                    _pdfCell(
                      d.behaviors
                          .where((b) =>
                              b.at.isAfter(d.anchor) &&
                              b.at.difference(d.anchor).inHours <= 8)
                          .map((b) => b.type)
                          .toSet()
                          .join(', '),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            'Generated by Cecelia Care. Fragmentation score combines number '
            'of wakings (up to 60 pts) and cumulative time awake (up to 40 '
            'pts). Consolidated sleep < 20; severely fragmented ≥ 75. This '
            'report is a caregiver-generated observation tool and does not '
            'replace a sleep study or clinical evaluation.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.blueGrey600,
              lineSpacing: 3,
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _pdfSectionHeader(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#3949AB'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  pw.Widget _pdfMeta(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Text('$label:',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey700)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  // ---------------------------------------------------------------------------
  // Log nap
  // ---------------------------------------------------------------------------

  Future<void> _logNap(ElderProfile elder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final pickedStart = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Nap start',
    );
    if (pickedStart == null || !mounted) return;

    final pickedEnd = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: (pickedStart.hour + 1) % 24,
        minute: pickedStart.minute,
      ),
      helpText: 'Nap end',
    );
    if (pickedEnd == null || !mounted) return;

    final now = DateTime.now();
    final startStr =
        '${pickedStart.hour.toString().padLeft(2, '0')}:${pickedStart.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${pickedEnd.hour.toString().padLeft(2, '0')}:${pickedEnd.minute.toString().padLeft(2, '0')}';

    // Write a sleep-type JournalEntry with isNap flag so the rhythm
    // builder picks it up. Using the existing type keeps the data in
    // the timeline and avoids a schema fork.
    try {
      await FirebaseFirestore.instance.collection('journalEntries').add({
        'elderId': elder.id,
        'type': 'sleep',
        'loggedByUserId': user.uid,
        'loggedByDisplayName': user.displayName,
        'entryTimestamp': Timestamp.fromDate(now),
        'dateString': DateFormat('yyyy-MM-dd').format(now),
        'visibleToUserIds': ['all'],
        'isPublic': true,
        'data': {
          'wentToBed': startStr,
          'wokeUp': endStr,
          'isNap': true,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Nap logged.'),
          backgroundColor: AppTheme.statusGreen,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // AI scaffold
  // ---------------------------------------------------------------------------

  Future<void> _askAi(ElderProfile elder) async {
    setState(() => _aiBusy = true);
    final rhythm = await _loadRhythmOnce(elder, _rangeDays);
    final res = await AiSuggestionService.instance.suggestSleepRhythmInsight(
      elderId: elder.id,
      elderDisplayName: elder.preferredName ?? elder.profileName,
      context: {
        'averageFragmentation': rhythm.averageFragmentation,
        'averageTotalSleepMinutes': rhythm.averageTotalSleep?.inMinutes,
        'averageBedtimeMinutesFromSixPm':
            rhythm.averageBedtimeMinutesFromSixPm,
        'averageWakeMinutesFromMidnight':
            rhythm.averageWakeMinutesFromMidnight,
        'fragmentedNightsFollowedByBehavior':
            rhythm.fragmentedNightsFollowedByBehavior,
        'daysCount': rhythm.days.length,
      },
    );
    if (!mounted) return;
    setState(() => _aiBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          res.errorMessage ?? res.suggestion ?? 'No insight available yet.'),
      backgroundColor:
          res.available ? AppTheme.statusGreen : AppTheme.tileIndigoDark,
    ));
  }
}

// ---------------------------------------------------------------------------
// Body / stream plumbing
// ---------------------------------------------------------------------------

class _RhythmBody extends StatelessWidget {
  const _RhythmBody({
    required this.elder,
    required this.rangeDays,
    required this.selectedAnchor,
    required this.canLog,
    required this.onRangeChange,
    required this.onDaySelected,
    required this.onLogNap,
    required this.onAskAi,
    required this.aiBusy,
  });

  final ElderProfile elder;
  final int rangeDays;
  final DateTime? selectedAnchor;
  final bool canLog;
  final ValueChanged<int> onRangeChange;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback? onLogNap;
  final VoidCallback? onAskAi;
  final bool aiBusy;

  @override
  Widget build(BuildContext context) {
    final firestore = context.watch<FirestoreService>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Sign in required.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final start = DateTime.now().subtract(Duration(days: rangeDays));
    return StreamBuilder<List<JournalEntry>>(
      stream: firestore.getJournalEntriesStream(
        elderId: elder.id,
        currentUserId: user.uid,
        startDate: start,
        type: EntryType.sleep,
      ),
      builder: (context, sleepSnap) {
        return StreamBuilder<List<JournalEntry>>(
          stream: firestore.getJournalEntriesStream(
            elderId: elder.id,
            currentUserId: user.uid,
            startDate: start,
            type: EntryType.nightWaking,
          ),
          builder: (context, wakeSnap) {
            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestore.getBehavioralEntriesStream(elder.id),
              builder: (context, behaviorSnap) {
                final loading = sleepSnap.connectionState ==
                        ConnectionState.waiting &&
                    !sleepSnap.hasData;
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final rhythm = SleepRhythm.compute(
                  sleepEntries: sleepSnap.data ?? const [],
                  nightWakingEntries: wakeSnap.data ?? const [],
                  behavioralEntries: behaviorSnap.data ?? const [],
                  daysCount: rangeDays,
                );

                // Default selection = most recent day with data, else last.
                final days = rhythm.days;
                final selected = _findSelected(days, selectedAnchor);

                return ListView(
                  padding:
                      const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    _Header(elder: elder),
                    const SizedBox(height: 12),
                    _HeroCard(
                      day: selected,
                      onAskAi: onAskAi,
                      aiBusy: aiBusy,
                    ),
                    const SizedBox(height: 10),
                    _RangeChips(
                      range: rangeDays,
                      onChange: onRangeChange,
                    ),
                    const SizedBox(height: 14),
                    _AveragesCard(rhythm: rhythm),
                    const SizedBox(height: 14),
                    _CorrelationCard(rhythm: rhythm),
                    const SizedBox(height: 14),
                    _StackHeader(),
                    const SizedBox(height: 6),
                    for (final d in days.reversed)
                      _DayStackRow(
                        day: d,
                        selected: selected.anchor == d.anchor,
                        onTap: () => onDaySelected(d.anchor),
                      ),
                    const SizedBox(height: 16),
                    if (canLog) _LogShortcuts(onLogNap: onLogNap),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  SleepRhythmDay _findSelected(
      List<SleepRhythmDay> days, DateTime? selected) {
    if (selected != null) {
      for (final d in days) {
        if (d.anchor == selected) return d;
      }
    }
    // Pick the most-recent day with data, fall back to the latest.
    for (final d in days.reversed) {
      if (d.hasAnyData) return d;
    }
    return days.isEmpty
        ? SleepRhythmDay(
            anchor: DateTime.now(),
          )
        : days.last;
  }
}

// ---------------------------------------------------------------------------
// Header / hero
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.elder});
  final ElderProfile elder;

  @override
  Widget build(BuildContext context) {
    final name = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kAccent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(Icons.nightlight_round, size: 20, color: _kAccentDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tracking $name\'s 24-hour rhythm. Fragmented nights often '
              'precede sundowning — watch the dots outside the ring.',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard(
      {required this.day, required this.onAskAi, required this.aiBusy});
  final SleepRhythmDay day;
  final VoidCallback? onAskAi;
  final bool aiBusy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE, MMM d').format(day.anchor),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              _AiStubChip(onTap: onAskAi, busy: aiBusy),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: SleepRhythmRadialChart(
              day: day,
              size: 260,
            ),
          ),
          const SizedBox(height: 8),
          _FragmentationBadge(day: day),
          const SizedBox(height: 8),
          _Legend(),
        ],
      ),
    );
  }
}

class _FragmentationBadge extends StatelessWidget {
  const _FragmentationBadge({required this.day});
  final SleepRhythmDay day;

  @override
  Widget build(BuildContext context) {
    final s = day.fragmentationScore;
    final color = s < 20
        ? AppTheme.statusGreen
        : s < 50
            ? AppTheme.statusAmber
            : AppTheme.dangerColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        '${day.fragmentationLabel} · ${s.toStringAsFixed(0)} / 100',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: const [
        _LegendItem(color: AppTheme.tileIndigoDeep, label: 'Main sleep'),
        _LegendItem(color: AppTheme.tileTeal, label: 'Nap'),
        _LegendItem(color: AppTheme.statusAmber, label: 'Waking'),
        _LegendItem(color: AppTheme.dangerColor, label: 'Behavior event'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style:
                const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Range chips + averages
// ---------------------------------------------------------------------------

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.range, required this.onChange});
  final int range;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in const [7, 14, 30])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label:
                  Text('$r days', style: const TextStyle(fontSize: 12)),
              selected: range == r,
              onSelected: (_) => onChange(r),
            ),
          ),
      ],
    );
  }
}

class _AveragesCard extends StatelessWidget {
  const _AveragesCard({required this.rhythm});
  final SleepRhythm rhythm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'WINDOW AVERAGES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kAccentDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Total',
                  value: rhythm.averageTotalSleep == null
                      ? '—'
                      : _fmtDuration(rhythm.averageTotalSleep!),
                  icon: Icons.bedtime_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Bedtime',
                  value: rhythm.averageBedtimeMinutesFromSixPm == null
                      ? '—'
                      : _fmtMinutesFromSixPm(
                          rhythm.averageBedtimeMinutesFromSixPm!),
                  icon: Icons.dark_mode_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Wake',
                  value: rhythm.averageWakeMinutesFromMidnight == null
                      ? '—'
                      : _fmtMinutesFromMidnight(
                          rhythm.averageWakeMinutesFromMidnight!),
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Wakings/night',
                  value: rhythm.averageWakings == null
                      ? '—'
                      : rhythm.averageWakings!.toStringAsFixed(1),
                  icon: Icons.notifications_active_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Fragmentation',
                  value: rhythm.averageFragmentation == null
                      ? '—'
                      : rhythm.averageFragmentation!.toStringAsFixed(0),
                  icon: Icons.broken_image_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Nights logged',
                  value: '${rhythm.days.where((d) => d.hasAnyData).length}'
                      '/${rhythm.days.length}',
                  icon: Icons.calendar_view_week_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: _kAccentDeep),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CorrelationCard extends StatelessWidget {
  const _CorrelationCard({required this.rhythm});
  final SleepRhythm rhythm;

  @override
  Widget build(BuildContext context) {
    final count = rhythm.fragmentedNightsFollowedByBehavior;
    final total = rhythm.days.where((d) => d.fragmentationScore >= 50).length;
    final color = total == 0
        ? AppTheme.statusGreen
        : (count >= total * 0.6
            ? AppTheme.dangerColor
            : AppTheme.statusAmber);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_graph, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FRAGMENTATION → BEHAVIOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'No fragmented nights in the window — good news.'
                      : '$count of $total fragmented nights were followed '
                          'by a behavioral event within 8 hours. '
                          'Watch for this pattern — poor sleep is a known '
                          'sundowning predictor.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textPrimary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7-day stack
// ---------------------------------------------------------------------------

class _StackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.stacked_bar_chart, size: 16, color: _kAccentDeep),
        const SizedBox(width: 8),
        Text(
          'DAY-BY-DAY RHYTHM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _kAccentDeep,
          ),
        ),
      ],
    );
  }
}

class _DayStackRow extends StatelessWidget {
  const _DayStackRow({
    required this.day,
    required this.selected,
    required this.onTap,
  });

  final SleepRhythmDay day;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? _kAccent.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: selected
                ? _kAccentDeep
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            SleepRhythmRadialChart(
              day: day,
              size: 90,
              options: const SleepRhythmRadialOptions.compact(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE').format(day.anchor),
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    DateFormat('MMM d').format(day.anchor),
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  if (!day.hasAnyData)
                    const Text(
                      'No sleep logged',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textLight,
                          fontStyle: FontStyle.italic),
                    )
                  else ...[
                    Text(
                      day.mainSleep == null
                          ? 'Naps only · ${_fmtDuration(day.totalSleep)}'
                          : '${_fmtClock(day.mainSleep!.start)} → '
                              '${_fmtClock(day.mainSleep!.end)} · '
                              '${_fmtDuration(day.totalSleep)}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (day.wakings.isNotEmpty)
                          _MiniPill(
                            color: AppTheme.statusAmber,
                            label: '${day.wakings.length}w',
                          ),
                        if (day.naps.isNotEmpty)
                          _MiniPill(
                            color: AppTheme.tileTeal,
                            label: '${day.naps.length}n',
                          ),
                        if (day.behaviors.isNotEmpty)
                          _MiniPill(
                            color: AppTheme.dangerColor,
                            label: '${day.behaviors.length}b',
                          ),
                        _MiniPill(
                          color: day.fragmentationScore < 20
                              ? AppTheme.statusGreen
                              : day.fragmentationScore < 50
                                  ? AppTheme.statusAmber
                                  : AppTheme.dangerColor,
                          label: 'frag ${day.fragmentationScore.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log shortcuts
// ---------------------------------------------------------------------------

class _LogShortcuts extends StatelessWidget {
  const _LogShortcuts({required this.onLogNap});
  final VoidCallback? onLogNap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.add_circle_outline,
                  size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'LOG TO THIS RHYTHM',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kAccentDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Main sleep and night wakings use the dashboard sleep and '
            'night-waking forms — their entries automatically appear here.',
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onLogNap,
            icon: const Icon(Icons.snooze_outlined, size: 16),
            label: const Text('Log a nap'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kAccentDeep,
              side: BorderSide(color: _kAccent.withValues(alpha: 0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStubChip extends StatelessWidget {
  const _AiStubChip({required this.onTap, required this.busy});
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final available = AiSuggestionService.instance.isAvailable;
    return Tooltip(
      message: available
          ? 'Ask AI for a rhythm insight'
          : 'AI rhythm insights are coming soon',
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: available
                ? _kAccentDeep.withValues(alpha: 0.1)
                : AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(
                color: available
                    ? _kAccentDeep.withValues(alpha: 0.3)
                    : AppTheme.textLight.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (busy)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  available
                      ? Icons.auto_awesome_outlined
                      : Icons.lock_clock_outlined,
                  size: 13,
                  color: available ? _kAccentDeep : AppTheme.textSecondary,
                ),
              const SizedBox(width: 5),
              Text(
                available ? 'AI hint' : 'Soon',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: available ? _kAccentDeep : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Format helpers (also used by PDF builder above)
// ---------------------------------------------------------------------------

String _fmtDuration(Duration d) {
  if (d.inMinutes <= 0) return '—';
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String _fmtClock(DateTime t) {
  final h24 = t.hour;
  final m = t.minute.toString().padLeft(2, '0');
  final period = h24 >= 12 ? 'PM' : 'AM';
  final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
  return '$h12:$m $period';
}

String _fmtMinutesFromMidnight(double minutes) {
  final m = minutes.round();
  final h = (m ~/ 60) % 24;
  final mm = m % 60;
  return _fmtClock(DateTime(2000, 1, 1, h, mm));
}

String _fmtMinutesFromSixPm(double minutes) {
  // 0 = 6 PM, +360 = midnight, +720 = 6 AM etc.
  final shifted = (minutes + 18 * 60).round() % (24 * 60);
  final h = (shifted ~/ 60) % 24;
  final mm = shifted % 60;
  return _fmtClock(DateTime(2000, 1, 1, h, mm));
}
