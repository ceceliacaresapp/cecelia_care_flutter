// lib/screens/behavioral_log_screen.dart
//
// Log and review observable dementia-related behaviors with clinical detail:
// type, severity, triggers, de-escalation techniques, and outcomes.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/behavioral_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';

class BehavioralLogScreen extends StatefulWidget {
  const BehavioralLogScreen({super.key});

  @override
  State<BehavioralLogScreen> createState() => _BehavioralLogScreenState();
}

class _BehavioralLogScreenState extends State<BehavioralLogScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _isGeneratingPdf = false;

  void _openLogForm() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _BehavioralLogForm(firestore: _firestore),
      ),
    );
  }

  // ── PDF Report ──────────────────────────────────────────────────

  Future<void> _generateReport(String elderId) async {
    if (_isGeneratingPdf) return;
    setState(() => _isGeneratingPdf = true);

    try {
      final elder = context.read<ActiveElderProvider>().activeElder;
      final elderName = elder?.profileName ?? 'Care Recipient';
      final user = FirebaseAuth.instance.currentUser;
      final caregiverName = user?.displayName ?? user?.email ?? 'Caregiver';

      final rawEntries = await _firestore
          .getBehavioralEntriesStream(elderId)
          .first
          .timeout(const Duration(seconds: 10), onTimeout: () => []);

      final entries = rawEntries
          .map((d) =>
              BehavioralEntry.fromFirestore(d['id'] as String? ?? '', d))
          .toList()
        ..sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
            .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));

      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No behavioral entries to report.')));
        }
        return;
      }

      final pdfBytes = await _buildReportPdf(
        entries: entries,
        elderName: elderName,
        caregiverName: caregiverName,
      );

      final tempDir = await getTemporaryDirectory();
      final slug = elderName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File(
          '${tempDir.path}/Behavioral_Report_${slug}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Behavioral Report — $elderName',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('Behavioral report error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<Uint8List> _buildReportPdf({
    required List<BehavioralEntry> entries,
    required String elderName,
    required String caregiverName,
  }) {
    final pdf = pw.Document();
    final dateFmt = DateFormat('MMM d, yyyy');
    final shortFmt = DateFormat('MMM d');
    final now = DateTime.now();

    // ── Aggregations ──

    // Frequency by behavior type
    final typeCounts = <String, int>{};
    for (final e in entries) {
      typeCounts[e.behaviorType] = (typeCounts[e.behaviorType] ?? 0) + 1;
    }
    final typesSorted = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Trigger frequency
    final triggerCounts = <String, int>{};
    for (final e in entries) {
      if (e.trigger != null && e.trigger!.isNotEmpty) {
        triggerCounts[e.trigger!] = (triggerCounts[e.trigger!] ?? 0) + 1;
      }
    }
    final triggersSorted = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // De-escalation effectiveness
    final techStats = <String, List<bool>>{};
    for (final e in entries) {
      final tech = e.deEscalationTechnique;
      final outcome = e.outcome;
      if (tech == null || tech.isEmpty || outcome == null) continue;
      techStats.putIfAbsent(tech, () => []);
      techStats[tech]!.add(
          outcome.contains('quickly') || outcome.contains('calmed'));
    }
    final techEffectiveness = <MapEntry<String, double>>[];
    techStats.forEach((tech, outcomes) {
      if (outcomes.length >= 2) {
        final rate = outcomes.where((b) => b).length / outcomes.length;
        techEffectiveness.add(MapEntry(tech, rate));
      }
    });
    techEffectiveness.sort((a, b) => b.value.compareTo(a.value));

    // Hour-of-day distribution
    final hourCounts = List.filled(24, 0);
    for (final e in entries) {
      final h = int.tryParse(e.timeOfDay.split(':').first);
      if (h != null) hourCounts[h]++;
    }

    // Severity over time (oldest → newest)
    final chronological = entries.reversed.toList();

    // Severity averages by period
    double periodAvg(int daysBack) {
      final cutoff = now.subtract(Duration(days: daysBack));
      final period = entries.where((e) =>
          e.createdAt != null && e.createdAt!.toDate().isAfter(cutoff));
      if (period.isEmpty) return 0;
      return period.map((e) => e.severity).reduce((a, b) => a + b) /
          period.length;
    }

    // Notable entries (severity >= 4)
    final notable = entries.where((e) => e.severity >= 4).take(10).toList();

    // ── PDF pages ──

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox.shrink()
          : pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 6),
              decoration: const pw.BoxDecoration(
                  border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300))),
              child: pw.Text(
                  'Behavioral Report — $elderName',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.blueGrey400)),
            ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300))),
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.blueGrey400)),
      ),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        // ── Cover header ──
        widgets.add(pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#E65100'),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Cecelia Care — Behavioral Health Report',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white)),
              pw.SizedBox(height: 10),
              _meta('Care Recipient', elderName),
              pw.SizedBox(height: 3),
              _meta('Prepared By', caregiverName),
              pw.SizedBox(height: 3),
              _meta('Total Episodes', '${entries.length}'),
              pw.SizedBox(height: 3),
              _meta('Generated',
                  DateFormat('MMM d, yyyy — h:mm a').format(now)),
            ],
          ),
        ));
        widgets.add(pw.SizedBox(height: 18));

        // ── Frequency by behavior type ──
        widgets.add(_section('Frequency by Behavior Type'));
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(1),
            2: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
              children: ['Behavior', 'Count', 'Frequency']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ))
                  .toList(),
            ),
            ...typesSorted.map((e) {
              final pct = (e.value / entries.length * 100).round();
              final bar = '\u2588' * (pct ~/ 5); // block chars as mini bar
              return pw.TableRow(
                children: [e.key, '${e.value}', '$pct% $bar']
                    .map((v) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(v,
                              style: const pw.TextStyle(fontSize: 9)),
                        ))
                    .toList(),
              );
            }),
          ],
        ));
        widgets.add(pw.SizedBox(height: 16));

        // ── Severity summary ──
        widgets.add(_section('Severity Summary'));
        widgets.add(pw.SizedBox(height: 6));
        final avg30 = periodAvg(30);
        final avg60 = periodAvg(60);
        final avg90 = periodAvg(90);
        widgets.add(pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(1.5),
            2: pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
              children: ['Period', 'Avg Severity', 'Episodes']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(h,
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ))
                  .toList(),
            ),
            ...[
              ['Last 30 days', avg30, 30],
              ['Last 60 days', avg60, 60],
              ['Last 90 days', avg90, 90],
            ].map((row) {
              final cutoff =
                  now.subtract(Duration(days: row[2] as int));
              final count = entries
                  .where((e) =>
                      e.createdAt != null &&
                      e.createdAt!.toDate().isAfter(cutoff))
                  .length;
              return pw.TableRow(
                children: [
                  row[0] as String,
                  '${(row[1] as double).toStringAsFixed(1)} / 5',
                  '$count',
                ]
                    .map((v) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(v,
                              style: const pw.TextStyle(fontSize: 9)),
                        ))
                    .toList(),
              );
            }),
          ],
        ));
        widgets.add(pw.SizedBox(height: 4));
        // Severity trend over time (chronological table)
        if (chronological.length >= 3) {
          widgets.add(pw.Text('Chronological severity:',
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold)));
          widgets.add(pw.SizedBox(height: 3));
          widgets.add(pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(3),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: ['Date', 'Sev.', 'Behavior']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              ...chronological.take(20).map((e) => pw.TableRow(
                    decoration: e.severity >= 4
                        ? const pw.BoxDecoration(color: PdfColors.red50)
                        : null,
                    children: [
                      e.createdAt != null
                          ? shortFmt.format(e.createdAt!.toDate())
                          : '?',
                      '${e.severity}/5',
                      e.behaviorType,
                    ]
                        .map((v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(v,
                                  style: const pw.TextStyle(fontSize: 8)),
                            ))
                        .toList(),
                  )),
            ],
          ));
        }
        widgets.add(pw.SizedBox(height: 16));

        // ── Top triggers ──
        if (triggersSorted.isNotEmpty) {
          widgets.add(_section('Top Triggers'));
          widgets.add(pw.SizedBox(height: 6));
          for (final t in triggersSorted.take(5)) {
            final pct = (t.value / entries.length * 100).round();
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '\u2022 ${t.key}: ${t.value} episodes ($pct%)',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ));
          }
          widgets.add(pw.SizedBox(height: 16));
        }

        // ── De-escalation effectiveness ──
        if (techEffectiveness.isNotEmpty) {
          widgets.add(_section('De-escalation Effectiveness'));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: ['Technique', 'Uses', 'Success Rate']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              ...techEffectiveness.map((e) {
                final uses = techStats[e.key]?.length ?? 0;
                return pw.TableRow(
                  decoration: e.value >= 0.7
                      ? const pw.BoxDecoration(color: PdfColors.green50)
                      : null,
                  children: [
                    e.key,
                    '$uses',
                    '${(e.value * 100).round()}%',
                  ]
                      .map((v) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(v,
                                style: const pw.TextStyle(fontSize: 9)),
                          ))
                      .toList(),
                );
              }),
            ],
          ));
          widgets.add(pw.SizedBox(height: 16));
        }

        // ── Time-of-day distribution ──
        widgets.add(_section('Time-of-Day Distribution'));
        widgets.add(pw.SizedBox(height: 6));
        // Show 4 time blocks: Morning, Afternoon, Evening, Night.
        final morning = hourCounts.sublist(6, 12).reduce((a, b) => a + b);
        final afternoon = hourCounts.sublist(12, 17).reduce((a, b) => a + b);
        final evening = hourCounts.sublist(17, 21).reduce((a, b) => a + b);
        final night = hourCounts.sublist(0, 6).reduce((a, b) => a + b) +
            hourCounts.sublist(21).reduce((a, b) => a + b);
        final blocks = [
          ['Morning (6 AM–12 PM)', morning],
          ['Afternoon (12–5 PM)', afternoon],
          ['Evening (5–9 PM)', evening],
          ['Night (9 PM–6 AM)', night],
        ];
        final maxBlock =
            [morning, afternoon, evening, night].reduce((a, b) => a > b ? a : b);
        for (final b in blocks) {
          final count = b[1] as int;
          final bar = maxBlock > 0
              ? '\u2588' * ((count / maxBlock * 20).round().clamp(0, 20))
              : '';
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              '${b[0]}: $count  $bar',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: count == maxBlock && count > 0
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
                color: count == maxBlock && count > 0
                    ? PdfColors.red800
                    : PdfColors.blueGrey700,
              ),
            ),
          ));
        }
        // Hourly breakdown
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text('Hourly: ${hourCounts.asMap().entries.where((e) => e.value > 0).map((e) => '${e.key}h:${e.value}').join(', ')}',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600)));
        widgets.add(pw.SizedBox(height: 16));

        // ── Notable entries (severity ≥ 4) ──
        if (notable.isNotEmpty) {
          widgets.add(_section('Notable Episodes (Severity \u2265 4)'));
          widgets.add(pw.SizedBox(height: 6));
          for (final e in notable) {
            final dateStr = e.createdAt != null
                ? dateFmt.format(e.createdAt!.toDate())
                : '?';
            widgets.add(pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                border: pw.Border.all(color: PdfColors.red200),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$dateStr at ${e.timeOfDay} — ${e.behaviorType} (${e.severityLabel})',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  if (e.trigger != null && e.trigger!.isNotEmpty)
                    pw.Text('Trigger: ${e.trigger}',
                        style: const pw.TextStyle(fontSize: 9)),
                  if (e.deEscalationTechnique != null)
                    pw.Text('Response: ${e.deEscalationTechnique}',
                        style: const pw.TextStyle(fontSize: 9)),
                  if (e.outcome != null)
                    pw.Text('Outcome: ${e.outcome}',
                        style: const pw.TextStyle(fontSize: 9)),
                  if (e.notes != null && e.notes!.isNotEmpty)
                    pw.Text('Notes: ${e.notes}',
                        style: pw.TextStyle(
                            fontSize: 9, fontStyle: pw.FontStyle.italic)),
                ],
              ),
            ));
          }
          widgets.add(pw.SizedBox(height: 16));
        }

        // ── Disclaimer ──
        widgets.add(pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            'This report is generated from caregiver-logged observations in the '
            'Cecelia Care app. It is intended to support clinical assessment, '
            'not replace it. Discuss patterns with the care recipient\u2019s '
            'neurologist or psychiatrist.',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600),
          ),
        ));

        return widgets;
      },
    ));

    return pdf.save();
  }

  static pw.Widget _section(String title) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: const pw.BoxDecoration(
          color: PdfColors.blueGrey100,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blueGrey800,
            letterSpacing: 0.8,
          ),
        ),
      );

  static pw.Widget _meta(String label, String value) => pw.Row(
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text('$label:',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange100)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.white)),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Behavioral Log'),
        actions: [
          if (elderId.isNotEmpty)
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Generate Report',
              onPressed: _isGeneratingPdf ? null : () => _generateReport(elderId),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openLogForm,
        backgroundColor: AppTheme.tileOrangeDeep,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : _buildHistory(elderId),
    );
  }

  Widget _buildHistory(String elderId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestore.getBehavioralEntriesStream(elderId),
      builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(4, (_) => const SkeletonListTile()),
            ),
          );
        }

        final entries = (snapshot.data ?? [])
            .map((raw) =>
                BehavioralEntry.fromFirestore(raw['id'] as String? ?? '', raw))
            .toList();

        if (entries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.psychology_outlined,
            title: 'No behaviors logged',
            subtitle: 'Tracking patterns helps identify triggers.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (_, i) => _buildEntryCard(entries[i]),
        );
      },
    );
  }

  Widget _buildEntryCard(BehavioralEntry entry) {
    final dateStr = entry.createdAt != null
        ? DateFormat('MMM d, yyyy').format(entry.createdAt!.toDate())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Severity color bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: entry.severityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: type + severity
                    Row(
                      children: [
                        Expanded(
                          child: Text(entry.behaviorType,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: entry.severityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(
                            '${entry.severityLabel} ${entry.severity}/5',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: entry.severityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Time + duration
                    Text(
                      '${entry.timeOfDay}${entry.durationLabel.isNotEmpty ? ' \u00B7 ~${entry.durationLabel}' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    // Trigger
                    if (entry.trigger != null && entry.trigger!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Text('\uD83C\uDFAF ',
                                style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Text(entry.trigger!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    // Technique
                    if (entry.deEscalationTechnique != null &&
                        entry.deEscalationTechnique!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Text('\uD83D\uDEE1\uFE0F ',
                                style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Text(entry.deEscalationTechnique!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    // Outcome
                    if (entry.outcome != null && entry.outcome!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Text(
                              entry.outcome!.contains('crisis') ||
                                      entry.outcome!.contains('not fully')
                                  ? '\u26A0\uFE0F '
                                  : '\u2713 ',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Expanded(
                              child: Text(entry.outcome!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    // Notes
                    if (entry.notes != null && entry.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(entry.notes!,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    const SizedBox(height: 4),
                    Text('$dateStr \u00B7 by ${entry.loggedByName}',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Log Form ──────────────────────────────────────────────────────

class _BehavioralLogForm extends StatefulWidget {
  const _BehavioralLogForm({required this.firestore});
  final FirestoreService firestore;

  @override
  State<_BehavioralLogForm> createState() => _BehavioralLogFormState();
}

class _BehavioralLogFormState extends State<_BehavioralLogForm> {
  String? _selectedType;
  int? _severity;
  int? _durationMinutes;
  String? _selectedTrigger;
  String? _selectedTechnique;
  String? _selectedOutcome;
  DateTime _episodeTime = DateTime.now();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  bool get _canSave => _selectedType != null && _severity != null;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final elderId =
          context.read<ActiveElderProvider>().activeElder?.id ?? '';
      if (elderId.isEmpty) return;

      final data = BehavioralEntry(
        elderId: elderId,
        behaviorType: _selectedType!,
        severity: _severity!,
        durationMinutes: _durationMinutes,
        trigger: _selectedTrigger,
        deEscalationTechnique: _selectedTechnique,
        outcome: _selectedOutcome,
        timeOfDay: DateFormat('HH:mm').format(_episodeTime),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        loggedBy: user.uid,
        loggedByName: user.displayName ?? user.email ?? 'Unknown',
      ).toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await widget.firestore.addBehavioralEntry(elderId, data);
      HapticUtils.success();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Behavioral observation saved.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Behavioral log save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSheetHeader(title: 'Log Behavioral Observation'),
          const SizedBox(height: 16),

          // ── Behavior Type ──────────────────────────────────
          _label('Behavior Type *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kBehaviorTypes
                .map((t) => _selectionChip(
                    t, _selectedType == t, () => setState(() => _selectedType = t),
                    AppTheme.tileOrangeDeep))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Severity ───────────────────────────────────────
          _label('Severity *'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final s = i + 1;
              final isSelected = _severity == s;
              final color = BehavioralEntry(
                elderId: '', behaviorType: '', severity: s,
                timeOfDay: '', loggedBy: '', loggedByName: '',
              ).severityColor;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _severity = s),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('$s',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.grey.shade500,
                        )),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ── Time ───────────────────────────────────────────
          Row(
            children: [
              _label('Time of Episode'),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_episodeTime),
                  );
                  if (picked != null) {
                    setState(() {
                      _episodeTime = DateTime(
                        _episodeTime.year, _episodeTime.month,
                        _episodeTime.day, picked.hour, picked.minute,
                      );
                    });
                  }
                },
                child: Text(DateFormat('h:mm a').format(_episodeTime)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Duration ───────────────────────────────────────
          _label('Duration (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(5, (i) {
              final mins = BehavioralEntry.kDurationOptions[i];
              final label = BehavioralEntry.kDurationLabels[i];
              return _selectionChip(
                  label, _durationMinutes == mins,
                  () => setState(() => _durationMinutes = mins),
                  AppTheme.textSecondary);
            }),
          ),
          const SizedBox(height: 16),

          // ── Trigger ────────────────────────────────────────
          _label('Trigger (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kCommonTriggers
                .map((t) => _selectionChip(
                    t, _selectedTrigger == t,
                    () => setState(() => _selectedTrigger = t),
                    AppTheme.tileBlueDark))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Technique ──────────────────────────────────────
          _label('De-escalation Technique (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kTechniques
                .map((t) => _selectionChip(
                    t, _selectedTechnique == t,
                    () => setState(() => _selectedTechnique = t),
                    AppTheme.tileTeal))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Outcome ────────────────────────────────────────
          _label('Outcome (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kOutcomes
                .map((t) => _selectionChip(
                    t, _selectedOutcome == t,
                    () => setState(() => _selectedOutcome = t),
                    const Color(0xFF5D4037)))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Notes ──────────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Describe what happened...',
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // ── Save ───────────────────────────────────────────
          ElevatedButton(
            onPressed: _canSave && !_isSaving ? _handleSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tileOrangeDeep,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary));

  Widget _selectionChip(String label, bool selected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? color : null,
            )),
      ),
    );
  }
}
