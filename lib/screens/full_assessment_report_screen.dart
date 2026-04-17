// lib/screens/full_assessment_report_screen.dart
//
// "Download Full Assessment Report" — generates a multi-page PDF combining
// ADL scores, Fall Risk history, Cognitive Assessment, Skin Integrity,
// Weight trend, and Medication adherence into one clinician-ready document.

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

import 'package:cecelia_care_flutter/models/adl_assessment.dart';
import 'package:cecelia_care_flutter/models/cognitive_assessment.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/fall_risk_assessment.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const _kColor = AppTheme.tileIndigo;

class FullAssessmentReportScreen extends StatefulWidget {
  const FullAssessmentReportScreen({super.key});

  @override
  State<FullAssessmentReportScreen> createState() =>
      _FullAssessmentReportScreenState();
}

class _FullAssessmentReportScreenState
    extends State<FullAssessmentReportScreen> {
  bool _isGenerating = false;

  Future<void> _generate() async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);

    try {
      final elderProvider = context.read<ActiveElderProvider>();
      final elder = elderProvider.activeElder;
      final userProfile = context.read<UserProfileProvider>().userProfile;
      final meds = context.read<MedicationDefinitionsProvider>().medDefinitions;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (elder == null || currentUserId == null) return;

      final elderId = elder.id;
      final elderName = elder.profileName;
      final caregiverName = userProfile?.displayName ?? 'Caregiver';
      final fs = context.read<FirestoreService>();
      final journalProvider = context.read<JournalServiceProvider>();

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 90));
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Fetch all data in parallel.
      final results = await Future.wait([
        // 0: ADL history (last 12)
        FirebaseFirestore.instance
            .collection('elderProfiles')
            .doc(elderId)
            .collection('adlAssessments')
            .orderBy('weekString', descending: true)
            .limit(12)
            .get(),
        // 1: Fall risk history (last 6)
        fs.getFallRiskAssessmentsStream(elderId).first,
        // 2: Cognitive history (last 12)
        fs.getCognitiveAssessmentsStream(elderId).first,
        // 3: Skin assessments (last 6)
        fs.getSkinAssessmentsStream(elderId).first,
        // 4: Journal entries (90 days for vitals + meds)
        journalProvider
            .getJournalEntriesStream(
              elderId: elderId,
              currentUserId: currentUserId,
              startDate: start,
              endDate: endOfDay,
            )
            .first,
      ]);

      final adlSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
      final adlHistory = adlSnap.docs
          .map((d) => AdlAssessment.fromFirestore(d.id, d.data()))
          .toList();

      final fallMaps = results[1] as List<Map<String, dynamic>>;
      final fallHistory = fallMaps
          .map((d) =>
              FallRiskAssessment.fromFirestore(d['id'] as String? ?? '', d))
          .toList();

      final cogMaps = results[2] as List<Map<String, dynamic>>;
      final cogHistory = cogMaps
          .map((d) =>
              CognitiveAssessment.fromFirestore(d['id'] as String? ?? '', d))
          .toList();

      final skinMaps = results[3] as List<Map<String, dynamic>>;

      final entries = results[4] as List<JournalEntry>;

      // Weight entries
      final weightEntries = entries
          .where((e) =>
              e.type == EntryType.vital &&
              (e.data?['vitalType'] as String? ?? '')
                  .toUpperCase()
                  .contains('WT'))
          .toList()
        ..sort(
            (a, b) => a.entryTimestamp.compareTo(b.entryTimestamp));

      // Medication adherence
      final medEntries =
          entries.where((e) => e.type == EntryType.medication).toList();

      final pdfBytes = await _buildPdf(
        elderName: elderName,
        caregiverName: caregiverName,
        start: start,
        end: now,
        adlHistory: adlHistory,
        fallHistory: fallHistory,
        cogHistory: cogHistory,
        skinMaps: skinMaps,
        weightEntries: weightEntries,
        medEntries: medEntries,
        meds: meds,
      );

      final tempDir = await getTemporaryDirectory();
      final slug = elderName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file = File(
          '${tempDir.path}/Full_Assessment_${slug}_${DateFormat('yyyyMMdd').format(now)}.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Full Assessment Report — $elderName',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('FullAssessmentReport: error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate report: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // PDF builder
  // ─────────────────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf({
    required String elderName,
    required String caregiverName,
    required DateTime start,
    required DateTime end,
    required List<AdlAssessment> adlHistory,
    required List<FallRiskAssessment> fallHistory,
    required List<CognitiveAssessment> cogHistory,
    required List<Map<String, dynamic>> skinMaps,
    required List<JournalEntry> weightEntries,
    required List<JournalEntry> medEntries,
    required List<MedicationDefinition> meds,
  }) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('MMM d, yyyy');
    const lookbackDays = 90;

    pdf.addPage(
      pw.MultiPage(
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
                    'Full Assessment Report — $elderName',
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

          // ── Cover Header ──
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#3949AB'),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Cecelia Care — Full Assessment Report',
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                pw.SizedBox(height: 10),
                _meta('Care Recipient', elderName),
                pw.SizedBox(height: 3),
                _meta('Prepared By', caregiverName),
                pw.SizedBox(height: 3),
                _meta('Period',
                    '${dateFmt.format(start)} – ${dateFmt.format(end)}'),
                pw.SizedBox(height: 3),
                _meta('Generated',
                    DateFormat('MMM d, yyyy — h:mm a').format(DateTime.now())),
              ],
            ),
          ));
          widgets.add(pw.SizedBox(height: 18));

          // ── ADL Scores Over Time ──
          if (adlHistory.isNotEmpty) {
            widgets.add(_header('Activities of Daily Living (ADL)'));
            widgets.add(pw.SizedBox(height: 6));
            final latest = adlHistory.first;
            widgets.add(pw.Text(
              'Latest: ${latest.scoreLabel} — ${latest.totalScore}/12 (${latest.weekString})',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
            ));
            widgets.add(pw.SizedBox(height: 4));
            // Per-domain
            widgets.add(pw.Text('Per-domain (0=dependent, 2=independent):',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)));
            latest.dimensionMap.forEach((name, score) {
              widgets.add(pw.Text('  \u2022 $name: $score/2',
                  style: const pw.TextStyle(fontSize: 9)));
            });
            // History table
            if (adlHistory.length >= 2) {
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(pw.Text('Score History:',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)));
              widgets.add(pw.SizedBox(height: 3));
              widgets.add(pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: ['Week', 'Score', 'Level']
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                  ...adlHistory.take(8).map((a) => pw.TableRow(
                        children: [
                          a.weekString,
                          '${a.totalScore}/12',
                          a.scoreLabel,
                        ]
                            .map((v) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(v,
                                      style:
                                          const pw.TextStyle(fontSize: 8)),
                                ))
                            .toList(),
                      )),
                ],
              ));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // ── Fall Risk Assessment History ──
          if (fallHistory.isNotEmpty) {
            widgets.add(_header('Fall Risk Assessment (CDC STEADI)'));
            widgets.add(pw.SizedBox(height: 6));
            final latest = fallHistory.first;
            widgets.add(pw.Text(
              '${latest.riskLevel} Risk — Score: ${latest.rawRiskScore}/20',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: latest.rawRiskScore >= 8
                    ? PdfColors.red800
                    : latest.rawRiskScore >= 4
                        ? PdfColors.orange800
                        : PdfColors.green800,
              ),
            ));
            widgets.add(pw.Text(latest.steadiRecommendation,
                style: pw.TextStyle(
                    fontSize: 9, fontStyle: pw.FontStyle.italic)));
            if (latest.missingProtections.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text('Missing protections:',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)));
              for (final p in latest.missingProtections) {
                widgets.add(pw.Text('  \u2022 $p',
                    style: const pw.TextStyle(fontSize: 9)));
              }
            }
            // History table
            if (fallHistory.length >= 2) {
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: ['Date', 'Score', 'Level', 'Assessed By']
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                  ...fallHistory.take(6).map((f) => pw.TableRow(
                        children: [
                          f.dateString,
                          '${f.rawRiskScore}/20',
                          f.riskLevel,
                          f.assessedByName,
                        ]
                            .map((v) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(v,
                                      style:
                                          const pw.TextStyle(fontSize: 8)),
                                ))
                            .toList(),
                      )),
                ],
              ));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // ── Cognitive Assessment ──
          if (cogHistory.isNotEmpty) {
            widgets.add(_header('Cognitive Assessment'));
            widgets.add(pw.SizedBox(height: 6));
            final latest = cogHistory.first;
            widgets.add(pw.Text(
              '${latest.cognitiveLevel} — ${latest.totalScore}/${latest.maxPossibleScore}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: latest.scorePercent >= 0.85
                    ? PdfColors.green800
                    : latest.scorePercent >= 0.70
                        ? PdfColors.blue800
                        : latest.scorePercent >= 0.50
                            ? PdfColors.orange800
                            : PdfColors.red800,
              ),
            ));
            if (latest.weakestDomain != null) {
              widgets.add(pw.Text(
                  'Weakest: ${latest.weakestDomain}  |  Strongest: ${latest.strongestDomain ?? '—'}',
                  style: const pw.TextStyle(fontSize: 9)));
            }
            // Domain breakdown
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text('Domain breakdown:',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)));
            latest.domainScores.forEach((name, pct) {
              final max = CognitiveAssessment.kDomainMax[name] ?? 5;
              final raw =
                  pct == null ? '—' : '${(pct * max).round()}/$max';
              widgets.add(pw.Text('  \u2022 $name: $raw',
                  style: const pw.TextStyle(fontSize: 9)));
            });
            // Trend
            if (cogHistory.length >= 2) {
              final oldest = cogHistory.last;
              final delta = latest.totalScore - oldest.totalScore;
              final trendStr = delta == 0
                  ? 'Stable'
                  : delta > 0
                      ? 'Improved by $delta over ${cogHistory.length} assessments'
                      : 'Declined by ${delta.abs()} over ${cogHistory.length} assessments';
              widgets.add(pw.SizedBox(height: 2));
              widgets.add(pw.Text('Trend: $trendStr',
                  style: pw.TextStyle(
                      fontSize: 9, fontStyle: pw.FontStyle.italic)));
            }
            // Score history table
            if (cogHistory.length >= 2) {
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(pw.Table(
                border:
                    pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.blueGrey50),
                    children: ['Month', 'Score', 'Level', 'Weakest']
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                  ...cogHistory.take(8).map((c) => pw.TableRow(
                        children: [
                          c.monthString,
                          '${c.totalScore}/${c.maxPossibleScore}',
                          c.cognitiveLevel,
                          c.weakestDomain ?? '—',
                        ]
                            .map((v) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(4),
                                  child: pw.Text(v,
                                      style:
                                          const pw.TextStyle(fontSize: 8)),
                                ))
                            .toList(),
                      )),
                ],
              ));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // ── Skin Integrity ──
          if (skinMaps.isNotEmpty) {
            widgets.add(_header('Skin Integrity'));
            widgets.add(pw.SizedBox(height: 6));
            for (final skin in skinMaps.take(3)) {
              final dateStr = skin['dateString'] as String? ?? '';
              final assessor = skin['assessedByName'] as String? ?? '';
              final stages =
                  (skin['stages'] as Map?)?.cast<String, dynamic>();
              final concerning = <String>[];
              stages?.forEach((site, stage) {
                if (stage is String &&
                    stage != 'intact' &&
                    stage.isNotEmpty) {
                  concerning.add('$site: $stage');
                }
              });
              if (concerning.isEmpty) {
                widgets.add(pw.Text(
                  '$dateStr — All sites intact (by $assessor)',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.green800),
                ));
              } else {
                widgets.add(pw.Text(
                  '$dateStr — ${concerning.length} site(s) with breakdown (by $assessor):',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800),
                ));
                for (final s in concerning) {
                  widgets.add(pw.Text('  \u2022 $s',
                      style: const pw.TextStyle(fontSize: 9)));
                }
              }
              widgets.add(pw.SizedBox(height: 4));
            }
            widgets.add(pw.SizedBox(height: 12));
          }

          // ── Weight Trend ──
          if (weightEntries.length >= 2) {
            widgets.add(_header('Weight Trend (Last 90 Days)'));
            widgets.add(pw.SizedBox(height: 6));
            final shortFmt = DateFormat('MMM d');
            widgets.add(pw.Table(
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: ['Date', 'Weight']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold)),
                          ))
                      .toList(),
                ),
                ...weightEntries.map((e) {
                  final val = e.data?['value'] as String? ?? '';
                  final unit = e.data?['unit'] as String? ?? 'lbs';
                  final date = e.entryTimestamp.toDate();
                  return pw.TableRow(
                    children: [
                      shortFmt.format(date),
                      '$val $unit',
                    ]
                        .map((v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(v,
                                  style: const pw.TextStyle(fontSize: 8)),
                            ))
                        .toList(),
                  );
                }),
              ],
            ));
            // Percentage change
            final firstWt = double.tryParse(
                weightEntries.first.data?['value']?.toString() ?? '');
            final lastWt = double.tryParse(
                weightEntries.last.data?['value']?.toString() ?? '');
            if (firstWt != null && lastWt != null && firstWt > 0) {
              final pct = ((lastWt - firstWt) / firstWt * 100);
              final changeStr = pct >= 0
                  ? '+${pct.toStringAsFixed(1)}%'
                  : '${pct.toStringAsFixed(1)}%';
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text(
                'Change over period: $changeStr '
                '(${firstWt.toStringAsFixed(1)} \u2192 ${lastWt.toStringAsFixed(1)})',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: pct <= -5 ? PdfColors.red800 : PdfColors.blueGrey700,
                ),
              ));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // ── Medication Adherence ──
          if (meds.isNotEmpty) {
            widgets.add(_header('Medication Adherence (90 Days)'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Table(
              border:
                  pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children:
                      ['Medication', 'Dose', 'Days Taken', 'Adherence']
                          .map((h) => pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(h,
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold)),
                              ))
                          .toList(),
                ),
                ...meds.map((med) {
                  final takenDates = medEntries
                      .where((e) =>
                          (e.data?['name'] as String?)?.toLowerCase() ==
                              med.name.toLowerCase() &&
                          e.data?['taken'] == true)
                      .map((e) => e.data?['date'] as String? ?? '')
                      .where((d) => d.isNotEmpty)
                      .toSet();
                  final pct =
                      (takenDates.length / lookbackDays * 100).clamp(0, 100);
                  return pw.TableRow(
                    decoration: pct < 70
                        ? const pw.BoxDecoration(color: PdfColors.red50)
                        : null,
                    children: [
                      med.name,
                      med.dose ?? '—',
                      '${takenDates.length}/$lookbackDays',
                      '${pct.toStringAsFixed(0)}%',
                    ]
                        .map((v) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(v,
                                  style: const pw.TextStyle(fontSize: 8)),
                            ))
                        .toList(),
                  );
                }),
              ],
            ));
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
              'This report is generated from caregiver-logged data in the '
              'Cecelia Care app and is intended to support — not replace — '
              'clinical assessment. Please verify all data with the care '
              'recipient\u2019s medical records.',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ),
          ));

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ── PDF helpers ──

  static pw.Widget _header(String title) {
    return pw.Container(
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
  }

  static pw.Widget _meta(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text('$label:',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo100)),
        ),
        pw.Expanded(
          child: pw.Text(value,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.white)),
        ),
      ],
    );
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Full Assessment Report'),
        backgroundColor: _kColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: elder == null
          ? const Center(child: Text('No active care recipient selected.'))
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border:
                          Border.all(color: _kColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _kColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: const Icon(Icons.assessment_outlined,
                              size: 22, color: _kColor),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                elder.profileName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: _kColor,
                                ),
                              ),
                              Text(
                                'Comprehensive 90-day assessment summary',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        _kColor.withValues(alpha: 0.7)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'This report combines:',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ...[
                    'ADL scores over time with per-domain breakdown',
                    'Fall Risk assessment history & risk level changes',
                    'Cognitive Assessment scores & domain analysis',
                    'Skin Integrity assessment history',
                    'Weight trend with % change calculation',
                    'Medication adherence rates per medication',
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 16, color: _kColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(item,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary)),
                            ),
                          ],
                        ),
                      )),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGenerating ? null : _generate,
                      icon: _isGenerating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: Text(_isGenerating
                          ? 'Generating...'
                          : 'Download Full Assessment Report'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                        backgroundColor: _kColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
