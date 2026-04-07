// lib/screens/appointment_prep_screen.dart
//
// Appointment Prep Checklist — auto-generates a clinically structured
// pre-visit summary from 30 days of care data. Includes a vitals table,
// medication adherence, symptom trends, sleep stats, notable events, and
// an editable "questions for doctor" field. Exports as a custom multi-page
// PDF (not the chronological ExportService format).

import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/utils/string_extensions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/models/adl_assessment.dart';
import 'package:cecelia_care_flutter/models/cognitive_assessment.dart';
import 'package:cecelia_care_flutter/models/fall_risk_assessment.dart';
import 'package:cecelia_care_flutter/models/wandering_assessment.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';

const _kColor = Color(0xFF3949AB); // deep indigo — distinct from DoctorSummary

// ─────────────────────────────────────────────────────────────────────────────
// Aggregated data structures
// ─────────────────────────────────────────────────────────────────────────────

class _VitalSummary {
  final String type;
  final String latestValue;
  final String unit;
  final DateTime latestDate;
  final double? numericAvg;
  final double? numericMin;
  final double? numericMax;
  final int count;
  final bool concerning;

  const _VitalSummary({
    required this.type,
    required this.latestValue,
    required this.unit,
    required this.latestDate,
    this.numericAvg,
    this.numericMin,
    this.numericMax,
    required this.count,
    required this.concerning,
  });
}

class _MedSummary {
  final String name;
  final String? dose;
  final int takenDays;
  final double adherencePct;

  const _MedSummary({
    required this.name,
    this.dose,
    required this.takenDays,
    required this.adherencePct,
  });
}

class _NotableEvent {
  final DateTime date;
  final String description;
  final bool highSeverity;

  const _NotableEvent({
    required this.date,
    required this.description,
    required this.highSeverity,
  });
}

/// All computed prep data — assembled once per stream update.
class _PrepData {
  final Map<String, _VitalSummary> vitals;
  final List<_MedSummary> medications;
  final int painCount;
  final double? painAvg;
  final double? painMax;
  final String? painTopLocation;
  final String painTrend;
  final int moodCount;
  final double? moodAvg;
  final double? moodMin;
  final String moodTrend;
  final int sleepCount;
  final double? sleepAvgDuration;
  final double? sleepAvgQuality;
  final List<_NotableEvent> notableEvents;

  // Hydration aggregation (computed from journal entries of type hydration).
  final int hydrationCount;
  final double hydrationAvgPerDay; // oz per day across the period
  final String? hydrationTopFluid;

  // Visitor pattern aggregation.
  final int visitorCount;
  final Map<String, int> visitorResponseCounts; // 'positive' → 5, etc.
  final String? visitorTopName;

  const _PrepData({
    required this.vitals,
    required this.medications,
    required this.painCount,
    this.painAvg,
    this.painMax,
    this.painTopLocation,
    required this.painTrend,
    required this.moodCount,
    this.moodAvg,
    this.moodMin,
    required this.moodTrend,
    required this.sleepCount,
    this.sleepAvgDuration,
    this.sleepAvgQuality,
    required this.notableEvents,
    this.hydrationCount = 0,
    this.hydrationAvgPerDay = 0,
    this.hydrationTopFluid,
    this.visitorCount = 0,
    this.visitorResponseCounts = const {},
    this.visitorTopName,
  });

  factory _PrepData.from(
    List<JournalEntry> entries,
    List<MedicationDefinition> meds,
    int lookbackDays,
  ) {
    // ── Vitals ─────────────────────────────────────────────────────────────
    final vitalGroups = <String, List<({String value, String unit, DateTime date})>>{};
    for (final e in entries.where((e) => e.type == EntryType.vital)) {
      final vt = e.data?['vitalType'] as String? ?? '';
      final val = e.data?['value'] as String? ?? '';
      if (vt.isEmpty || val.isEmpty) continue;
      final unit = e.data?['unit'] as String? ?? '';
      vitalGroups.putIfAbsent(vt, () => []).add((
        value: val,
        unit: unit,
        date: e.entryTimestamp.toDate(),
      ));
    }

    final vitals = <String, _VitalSummary>{};
    for (final entry in vitalGroups.entries) {
      final readings = entry.value
        ..sort((a, b) => b.date.compareTo(a.date));
      final latest = readings.first;
      final numerics = readings
          .map((r) => _parseNumericValue(r.value))
          .whereType<double>()
          .toList();
      double? avg, min, max;
      if (numerics.isNotEmpty) {
        avg = numerics.reduce((a, b) => a + b) / numerics.length;
        min = numerics.reduce((a, b) => a < b ? a : b);
        max = numerics.reduce((a, b) => a > b ? a : b);
      }
      vitals[entry.key] = _VitalSummary(
        type: entry.key,
        latestValue: latest.value,
        unit: latest.unit,
        latestDate: latest.date,
        numericAvg: avg,
        numericMin: min,
        numericMax: max,
        count: readings.length,
        concerning: _isVitalConcerning(entry.key, latest.value),
      );
    }

    // ── Medications ────────────────────────────────────────────────────────
    final medEntries =
        entries.where((e) => e.type == EntryType.medication).toList();
    final medications = meds.map((med) {
      final takenDates = medEntries
          .where((e) =>
              (e.data?['name'] as String?)
                  ?.toLowerCase() ==
                  med.name.toLowerCase() &&
              e.data?['taken'] == true)
          .map((e) => e.data?['date'] as String? ?? '')
          .where((d) => d.isNotEmpty)
          .toSet();
      return _MedSummary(
        name: med.name,
        dose: med.dose,
        takenDays: takenDates.length,
        adherencePct: (takenDates.length / lookbackDays) * 100,
      );
    }).toList();

    // ── Pain ───────────────────────────────────────────────────────────────
    final painEntries = entries
        .where((e) => e.type == EntryType.pain)
        .toList()
      ..sort((a, b) => a.entryTimestamp.compareTo(b.entryTimestamp));
    final painIntensities = painEntries.map((e) {
      final i = e.data?['intensity'];
      return i is int ? i.toDouble() : double.tryParse(i?.toString() ?? '');
    }).whereType<double>().toList();

    double? painAvg, painMax;
    if (painIntensities.isNotEmpty) {
      painAvg = painIntensities.reduce((a, b) => a + b) / painIntensities.length;
      painMax = painIntensities.reduce((a, b) => a > b ? a : b);
    }

    final locationFreq = <String, int>{};
    for (final e in painEntries) {
      final loc = e.data?['location'] as String?;
      if (loc != null && loc.isNotEmpty) {
        locationFreq[loc] = (locationFreq[loc] ?? 0) + 1;
      }
    }
    final painTopLocation = locationFreq.isEmpty
        ? null
        : locationFreq.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    final painTrend = _computeTrend(painIntensities, higherIsWorse: true);

    // ── Mood ───────────────────────────────────────────────────────────────
    final moodEntries = entries
        .where((e) => e.type == EntryType.mood)
        .toList()
      ..sort((a, b) => a.entryTimestamp.compareTo(b.entryTimestamp));
    final moodLevels = moodEntries.map((e) {
      final m = e.data?['moodLevel'];
      return m is int ? m.toDouble() : double.tryParse(m?.toString() ?? '');
    }).whereType<double>().toList();

    double? moodAvg, moodMin;
    if (moodLevels.isNotEmpty) {
      moodAvg = moodLevels.reduce((a, b) => a + b) / moodLevels.length;
      moodMin = moodLevels.reduce((a, b) => a < b ? a : b);
    }
    final moodTrend = _computeTrend(moodLevels, higherIsWorse: false);

    // ── Sleep ──────────────────────────────────────────────────────────────
    final sleepEntries = entries.where((e) => e.type == EntryType.sleep).toList();
    final sleepDurations = sleepEntries
        .map((e) =>
            double.tryParse((e.data?['totalDuration'] as String?)?.trim() ?? ''))
        .whereType<double>()
        .toList();
    final sleepQualities = sleepEntries.map((e) {
      final q = e.data?['quality'];
      return q is int ? q.toDouble() : double.tryParse(q?.toString() ?? '');
    }).whereType<double>().toList();

    double? sleepAvgDuration, sleepAvgQuality;
    if (sleepDurations.isNotEmpty) {
      sleepAvgDuration =
          sleepDurations.reduce((a, b) => a + b) / sleepDurations.length;
    }
    if (sleepQualities.isNotEmpty) {
      sleepAvgQuality =
          sleepQualities.reduce((a, b) => a + b) / sleepQualities.length;
    }

    // ── Notable events ─────────────────────────────────────────────────────
    const _highPainThreshold = 8.0;
    const _lowMoodThreshold = 2.0;
    const _keywords = [
      'hospital',
      'emergency',
      ' er ',
      'ambulance',
      '911',
      'fell',
      'fall',
      'accident',
    ];
    final notable = <_NotableEvent>[];
    final dateFmt = DateFormat('MMM d');

    for (final e in entries) {
      final date = e.entryTimestamp.toDate();
      if (e.type == EntryType.pain) {
        final i = e.data?['intensity'];
        final intensity =
            i is int ? i.toDouble() : double.tryParse(i?.toString() ?? '');
        if (intensity != null && intensity >= _highPainThreshold) {
          final loc = e.data?['location'] as String?;
          notable.add(_NotableEvent(
            date: date,
            description:
                'Pain ${intensity.toInt()}/10${loc != null ? ' — $loc' : ''}',
            highSeverity: true,
          ));
        }
      } else if (e.type == EntryType.mood) {
        final m = e.data?['moodLevel'];
        final level =
            m is int ? m.toDouble() : double.tryParse(m?.toString() ?? '');
        if (level != null && level <= _lowMoodThreshold) {
          notable.add(_NotableEvent(
            date: date,
            description: 'Low mood (${level.toInt()}/5)',
            highSeverity: level <= 1,
          ));
        }
      } else {
        // Keyword scan on text and notes
        final searchText =
            '${(e.text ?? '').toLowerCase()} ${(e.data?['note'] as String? ?? '').toLowerCase()} ${(e.data?['notes'] as String? ?? '').toLowerCase()}';
        for (final kw in _keywords) {
          if (searchText.contains(kw)) {
            notable.add(_NotableEvent(
              date: date,
              description:
                  '${e.type.name.capitalize()}: ${(e.text ?? e.data?['note'] as String? ?? '').take(60)}',
              highSeverity: true,
            ));
            break;
          }
        }
      }
    }

    notable.sort((a, b) => b.date.compareTo(a.date));
    // Deduplicate by date label to avoid noise
    final seenDates = <String>{};
    final deduped = notable.where((n) {
      final key = '${dateFmt.format(n.date)}-${n.description}';
      return seenDates.add(key);
    }).take(10).toList();

    // ── Hydration aggregation ──────────────────────────────────────────
    final hydrationEntries =
        entries.where((e) => e.type == EntryType.hydration).toList();
    double hydrationOzTotal = 0;
    final fluidTypeCounts = <String, int>{};
    for (final e in hydrationEntries) {
      final vol = (e.data?['volume'] as num?)?.toDouble() ?? 0;
      final unit = e.data?['unit'] as String? ?? 'oz';
      // Normalize ml → oz so the daily average makes sense.
      hydrationOzTotal += unit == 'ml' ? vol / 29.5735 : vol;
      final fluid = (e.data?['fluidType'] as String? ?? '').toLowerCase();
      if (fluid.isNotEmpty) {
        fluidTypeCounts[fluid] = (fluidTypeCounts[fluid] ?? 0) + 1;
      }
    }
    final hydrationAvgPerDay = lookbackDays > 0
        ? hydrationOzTotal / lookbackDays
        : 0.0;
    final hydrationTopFluid = fluidTypeCounts.isEmpty
        ? null
        : (fluidTypeCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    // ── Visitor aggregation ────────────────────────────────────────────
    final visitorEntries =
        entries.where((e) => e.type == EntryType.visitor).toList();
    final visitorResponseCounts = <String, int>{};
    final visitorNameCounts = <String, int>{};
    for (final e in visitorEntries) {
      final response = e.data?['response'] as String? ?? '';
      if (response.isNotEmpty) {
        visitorResponseCounts[response] =
            (visitorResponseCounts[response] ?? 0) + 1;
      }
      final name = e.data?['visitorName'] as String? ?? '';
      if (name.isNotEmpty) {
        visitorNameCounts[name] = (visitorNameCounts[name] ?? 0) + 1;
      }
    }
    final visitorTopName = visitorNameCounts.isEmpty
        ? null
        : (visitorNameCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key;

    return _PrepData(
      vitals: vitals,
      medications: medications,
      painCount: painEntries.length,
      painAvg: painAvg,
      painMax: painMax,
      painTopLocation: painTopLocation,
      painTrend: painTrend,
      moodCount: moodEntries.length,
      moodAvg: moodAvg,
      moodMin: moodMin,
      moodTrend: moodTrend,
      sleepCount: sleepEntries.length,
      sleepAvgDuration: sleepAvgDuration,
      sleepAvgQuality: sleepAvgQuality,
      notableEvents: deduped,
      hydrationCount: hydrationEntries.length,
      hydrationAvgPerDay: hydrationAvgPerDay,
      hydrationTopFluid: hydrationTopFluid,
      visitorCount: visitorEntries.length,
      visitorResponseCounts: visitorResponseCounts,
      visitorTopName: visitorTopName,
    );
  }
}

// Parse a value as double, returning null for compound values like "120/80"
double? _parseNumericValue(String value) {
  if (value.contains('/')) return null;
  return double.tryParse(value.trim());
}

bool _isVitalConcerning(String type, String value) {
  final t = type.toLowerCase();
  if (t.contains('blood pressure') || t.contains(' bp')) {
    final parts = value.split('/');
    if (parts.length == 2) {
      final systolic = double.tryParse(parts[0].trim());
      return systolic != null && systolic > 140;
    }
    return false;
  }
  final numeric = _parseNumericValue(value);
  if (numeric == null) return false;
  if (t.contains('heart rate') || t.contains(' hr') || t.contains('pulse')) {
    return numeric > 100 || numeric < 50;
  }
  if (t.contains('oxygen') || t.contains('o2') || t.contains('spo2')) {
    return numeric < 95;
  }
  if (t.contains('temp')) {
    return numeric > 38.3 || (numeric > 99.5 && numeric < 115);
  }
  return false;
}

String _computeTrend(List<double> values, {required bool higherIsWorse}) {
  if (values.length < 4) return 'stable';
  final mid = values.length ~/ 2;
  final first = values.sublist(0, mid);
  final second = values.sublist(mid);
  final firstAvg = first.reduce((a, b) => a + b) / first.length;
  final secondAvg = second.reduce((a, b) => a + b) / second.length;
  final diff = secondAvg - firstAvg;
  if (diff.abs() < 0.8) return 'stable';
  if (higherIsWorse) {
    return diff > 0 ? 'worsening' : 'improving';
  } else {
    return diff > 0 ? 'improving' : 'worsening';
  }
}

extension _StringX on String {
  String take(int n) => length <= n ? this : '${substring(0, n)}…';
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class AppointmentPrepScreen extends StatefulWidget {
  const AppointmentPrepScreen({super.key});

  @override
  State<AppointmentPrepScreen> createState() =>
      _AppointmentPrepScreenState();
}

class _AppointmentPrepScreenState extends State<AppointmentPrepScreen> {
  static const int _lookbackDays = 30;

  late final TextEditingController _questionsCtrl;
  late final DateTime _startDate;
  late final DateTime _endDate;
  late final DateTime _endOfDay;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _questionsCtrl = TextEditingController();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: _lookbackDays));
    _endOfDay = DateTime(
        _endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
  }

  @override
  void dispose() {
    _questionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateAndShare(
    _PrepData data,
    String elderName,
    String caregiverName,
  ) async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      // Fetch latest assessments for the PDF. We pull the most recent
      // record from each subcollection so doctors get a complete clinical
      // snapshot in one document.
      final elderId =
          context.read<ActiveElderProvider>().activeElder?.id ?? '';
      FallRiskAssessment? fallRisk;
      CognitiveAssessment? cognitive;
      List<CognitiveAssessment> cognitiveHistory = const [];
      WanderingAssessment? wandering;
      AdlAssessment? adl;
      Map<String, dynamic>? skinLatest;
      int turningLogsLast24h = 0;
      if (elderId.isNotEmpty) {
        final fs = context.read<FirestoreService>();
        final fallSnap =
            await fs.getFallRiskAssessmentsStream(elderId).first;
        if (fallSnap.isNotEmpty) {
          fallRisk = FallRiskAssessment.fromFirestore(
              fallSnap.first['id'] as String? ?? '', fallSnap.first);
        }
        final cogSnap =
            await fs.getCognitiveAssessmentsStream(elderId).first;
        cognitiveHistory = cogSnap
            .map((d) => CognitiveAssessment.fromFirestore(
                d['id'] as String? ?? '', d))
            .toList();
        if (cognitiveHistory.isNotEmpty) {
          cognitive = cognitiveHistory.first;
        }
        // Wandering risk (best-effort — this is one of the riskiest fetches
        // because the rules can fail; we swallow per-section errors so a
        // single failed query doesn't kill the whole PDF).
        try {
          final wanderSnap =
              await fs.getWanderingAssessmentsStream(elderId).first;
          if (wanderSnap.isNotEmpty) {
            wandering = WanderingAssessment.fromFirestore(
                wanderSnap.first['id'] as String? ?? '', wanderSnap.first);
          }
        } catch (e) {
          debugPrint('AppointmentPrep: wandering fetch failed: $e');
        }
        // ADL (uses provider, but we want the freshest record from
        // Firestore directly for the PDF).
        try {
          final adlSnap = await FirebaseFirestore.instance
              .collection('elderProfiles')
              .doc(elderId)
              .collection('adlAssessments')
              .orderBy('weekString', descending: true)
              .limit(1)
              .get();
          if (adlSnap.docs.isNotEmpty) {
            adl = AdlAssessment.fromFirestore(
                adlSnap.docs.first.id, adlSnap.docs.first.data());
          }
        } catch (e) {
          debugPrint('AppointmentPrep: ADL fetch failed: $e');
        }
        // Skin integrity — most recent assessment + count of turning logs
        // in the last 24 hours.
        try {
          final skinSnap =
              await fs.getSkinAssessmentsStream(elderId).first;
          if (skinSnap.isNotEmpty) {
            skinLatest = skinSnap.first;
          }
          final since = DateTime.now().subtract(const Duration(hours: 24));
          final turningSnap = await fs
              .getTurningLogsStream(elderId, startDate: since)
              .first;
          turningLogsLast24h = turningSnap.length;
        } catch (e) {
          debugPrint('AppointmentPrep: skin/turning fetch failed: $e');
        }
      }
      final pdfBytes = await _buildPdf(
          data,
          elderName,
          caregiverName,
          fallRisk,
          cognitive,
          cognitiveHistory,
          wandering,
          adl,
          skinLatest,
          turningLogsLast24h);

      final tempDir = await getTemporaryDirectory();
      final slug =
          elderName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final dateSuffix =
          DateFormat('yyyyMMdd').format(_endDate);
      final file = File(
          '${tempDir.path}/Appointment_Prep_${slug}_$dateSuffix.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Appointment Prep — $elderName',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('AppointmentPrepScreen: PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<Uint8List> _buildPdf(
    _PrepData d,
    String elderName,
    String caregiverName,
    FallRiskAssessment? fallRisk,
    CognitiveAssessment? cognitive,
    List<CognitiveAssessment> cognitiveHistory,
    WanderingAssessment? wandering,
    AdlAssessment? adl,
    Map<String, dynamic>? skinLatest,
    int turningLogsLast24h,
  ) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('MMM d, yyyy');
    final shortFmt = DateFormat('MMM d');

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
                    'Appointment Prep — $elderName — ${dateFmt.format(_startDate)} to ${dateFmt.format(_endDate)}',
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

          // Cover header
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#3949AB'),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Cecelia Care — Appointment Prep Checklist',
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white)),
                  pw.SizedBox(height: 10),
                  _pdfMetaRow('Care Recipient', elderName),
                  pw.SizedBox(height: 3),
                  _pdfMetaRow('Prepared By', caregiverName),
                  pw.SizedBox(height: 3),
                  _pdfMetaRow('Date Range',
                      '${dateFmt.format(_startDate)} – ${dateFmt.format(_endDate)}'),
                  pw.SizedBox(height: 3),
                  _pdfMetaRow('Generated',
                      DateFormat('MMM d, yyyy — h:mm a').format(DateTime.now())),
                ],
              ),
            ),
          );
          widgets.add(pw.SizedBox(height: 18));

          // Vitals
          if (d.vitals.isNotEmpty) {
            widgets.add(_pdfSectionHeader('Vitals Summary'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(_pdfVitalsTable(d.vitals, shortFmt));
            widgets.add(pw.SizedBox(height: 16));
          }

          // Medications
          if (d.medications.isNotEmpty) {
            widgets.add(_pdfSectionHeader('Current Medications'));
            widgets.add(pw.SizedBox(height: 6));
            for (final med in d.medications) {
              final adherence = med.adherencePct > 0
                  ? '  (${med.adherencePct.toStringAsFixed(0)}% adherence — ${med.takenDays} of $_lookbackDays days logged)'
                  : '';
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '• ${med.name}${med.dose != null ? ' ${med.dose}' : ''}$adherence',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ));
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // Symptoms
          widgets.add(_pdfSectionHeader('Symptom Patterns'));
          widgets.add(pw.SizedBox(height: 6));
          if (d.painCount > 0) {
            widgets.add(pw.Text(
              'Pain: ${d.painCount} entries, '
              'avg ${d.painAvg?.toStringAsFixed(1) ?? '—'}/10, '
              'peak ${d.painMax?.toInt() ?? '—'}/10'
              '${d.painTopLocation != null ? ', mostly ${d.painTopLocation}' : ''}. '
              'Trend: ${d.painTrend}.',
              style: const pw.TextStyle(fontSize: 10),
            ));
            widgets.add(pw.SizedBox(height: 4));
          } else {
            widgets.add(pw.Text('Pain: No entries in this period.',
                style: const pw.TextStyle(fontSize: 10)));
            widgets.add(pw.SizedBox(height: 4));
          }
          if (d.moodCount > 0) {
            widgets.add(pw.Text(
              'Mood: ${d.moodCount} entries, '
              'avg ${d.moodAvg?.toStringAsFixed(1) ?? '—'}/5, '
              'lowest ${d.moodMin?.toInt() ?? '—'}/5. '
              'Trend: ${d.moodTrend}.',
              style: const pw.TextStyle(fontSize: 10),
            ));
          } else {
            widgets.add(pw.Text('Mood: No entries in this period.',
                style: const pw.TextStyle(fontSize: 10)));
          }
          widgets.add(pw.SizedBox(height: 16));

          // Sleep
          widgets.add(_pdfSectionHeader('Sleep Overview'));
          widgets.add(pw.SizedBox(height: 6));
          if (d.sleepCount > 0) {
            widgets.add(pw.Text(
              '${d.sleepCount} nights logged.  '
              '${d.sleepAvgDuration != null ? 'Avg duration: ${d.sleepAvgDuration!.toStringAsFixed(1)} hrs.  ' : ''}'
              '${d.sleepAvgQuality != null ? 'Avg quality: ${d.sleepAvgQuality!.toStringAsFixed(1)}/5.' : ''}',
              style: const pw.TextStyle(fontSize: 10),
            ));
          } else {
            widgets.add(pw.Text('No sleep entries in this period.',
                style: const pw.TextStyle(fontSize: 10)));
          }
          widgets.add(pw.SizedBox(height: 16));

          // Notable events
          widgets.add(_pdfSectionHeader('Notable Events'));
          widgets.add(pw.SizedBox(height: 6));
          if (d.notableEvents.isEmpty) {
            widgets.add(pw.Text('No concerning events in this period.',
                style: const pw.TextStyle(fontSize: 10)));
          } else {
            for (final ev in d.notableEvents) {
              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  '• ${shortFmt.format(ev.date)} — ${ev.description}',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: ev.highSeverity
                          ? PdfColors.red800
                          : PdfColors.blueGrey700),
                ),
              ));
            }
          }

          // Fall Risk Assessment (CDC STEADI)
          if (fallRisk != null) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader(
                'Fall Risk Assessment (CDC STEADI)'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Text(
              '${fallRisk.riskLevel} Risk — Score: ${fallRisk.rawRiskScore}/20',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: fallRisk.rawRiskScore >= 8
                    ? PdfColors.red800
                    : fallRisk.rawRiskScore >= 4
                        ? PdfColors.orange800
                        : PdfColors.green800,
              ),
            ));
            widgets.add(pw.Text(
              fallRisk.riskSummary,
              style: const pw.TextStyle(fontSize: 10),
            ));
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text(
              fallRisk.steadiRecommendation,
              style: pw.TextStyle(
                  fontSize: 9, fontStyle: pw.FontStyle.italic),
            ));
            if (fallRisk.missingProtections.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text('Missing protections:',
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold)));
              for (final p in fallRisk.missingProtections) {
                widgets.add(pw.Text('  \u2022 $p',
                    style: const pw.TextStyle(fontSize: 9)));
              }
            }
            widgets.add(pw.Text(
              'Assessed ${fallRisk.dateString} by ${fallRisk.assessedByName}',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ));
          }

          // Cognitive Screening Assessment
          if (cognitive != null) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader('Cognitive Screening'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Text(
              'Score: ${cognitive.totalScore}/${cognitive.maxPossibleScore} \u2014 ${cognitive.cognitiveLevel}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: cognitive.scorePercent >= 0.85
                    ? PdfColors.green800
                    : cognitive.scorePercent >= 0.70
                        ? PdfColors.blue800
                        : cognitive.scorePercent >= 0.50
                            ? PdfColors.orange800
                            : PdfColors.red800,
              ),
            ));
            if (cognitive.weakestDomain != null) {
              widgets.add(pw.Text(
                'Weakest domain: ${cognitive.weakestDomain}',
                style: const pw.TextStyle(fontSize: 9),
              ));
            }
            if (cognitive.strongestDomain != null) {
              widgets.add(pw.Text(
                'Strongest domain: ${cognitive.strongestDomain}',
                style: const pw.TextStyle(fontSize: 9),
              ));
            }
            // Per-domain breakdown
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text('Domain breakdown:',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)));
            cognitive.domainScores.forEach((name, pct) {
              final max = CognitiveAssessment.kDomainMax[name] ?? 5;
              final raw = pct == null ? '—' : '${(pct * max).round()}/$max';
              widgets.add(pw.Text('  \u2022 $name: $raw',
                  style: const pw.TextStyle(fontSize: 9)));
            });
            // Trend (compare to oldest in history)
            if (cognitiveHistory.length >= 2) {
              final oldest = cognitiveHistory.last;
              final delta = cognitive.totalScore - oldest.totalScore;
              final trendStr = delta == 0
                  ? 'Stable'
                  : delta > 0
                      ? 'Improved by $delta over ${cognitiveHistory.length} assessments'
                      : 'Declined by ${delta.abs()} over ${cognitiveHistory.length} assessments';
              widgets.add(pw.SizedBox(height: 2));
              widgets.add(pw.Text('Trend: $trendStr',
                  style: pw.TextStyle(
                      fontSize: 9, fontStyle: pw.FontStyle.italic)));
            }
            widgets.add(pw.SizedBox(height: 2));
            widgets.add(pw.Text(
              'Assessed ${cognitive.createdAt != null ? DateFormat('MMM d, yyyy').format(cognitive.createdAt!.toDate()) : cognitive.monthString} by ${cognitive.assessedByName}',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ));
          }

          // Wandering Risk Assessment
          if (wandering != null) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader('Wandering Risk'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Text(
              '${wandering.riskLevel} Risk — Score: ${wandering.rawRiskScore}/13',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: wandering.rawRiskScore >= 9
                    ? PdfColors.red800
                    : wandering.rawRiskScore >= 6
                        ? PdfColors.orange800
                        : PdfColors.green800,
              ),
            ));
            widgets.add(pw.Text(
              wandering.riskSummary,
              style: const pw.TextStyle(fontSize: 10),
            ));
            if (wandering.knownTriggers != null &&
                wandering.knownTriggers!.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text(
                'Known triggers: ${wandering.knownTriggers}',
                style: const pw.TextStyle(fontSize: 9),
              ));
            }
            if (wandering.peakRiskTimes != null &&
                wandering.peakRiskTimes!.isNotEmpty) {
              widgets.add(pw.Text(
                'Peak risk times: ${wandering.peakRiskTimes}',
                style: const pw.TextStyle(fontSize: 9),
              ));
            }
            widgets.add(pw.SizedBox(height: 2));
            widgets.add(pw.Text(
              'Assessed ${wandering.dateString} by ${wandering.assessedByName}',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ));
          }

          // ADL (Activities of Daily Living) Assessment
          if (adl != null) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader('Activities of Daily Living'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Text(
              '${adl.scoreLabel} — Score: ${adl.totalScore}/12',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: adl.totalScore <= 2
                    ? PdfColors.red800
                    : adl.totalScore <= 6
                        ? PdfColors.orange800
                        : adl.totalScore <= 9
                            ? PdfColors.blue800
                            : PdfColors.green800,
              ),
            ));
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text('Per-domain scores (0=dependent, 2=independent):',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold)));
            adl.dimensionMap.forEach((name, score) {
              widgets.add(pw.Text('  \u2022 $name: $score/2',
                  style: const pw.TextStyle(fontSize: 9)));
            });
            widgets.add(pw.SizedBox(height: 2));
            widgets.add(pw.Text(
              'Assessed ${adl.weekString} by ${adl.assessedByName}',
              style: const pw.TextStyle(
                  fontSize: 8, color: PdfColors.grey600),
            ));
          }

          // Skin Integrity + repositioning compliance
          if (skinLatest != null || turningLogsLast24h > 0) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader('Skin Integrity'));
            widgets.add(pw.SizedBox(height: 6));
            if (skinLatest != null) {
              final stages =
                  (skinLatest['stages'] as Map?)?.cast<String, dynamic>();
              final concerningSites = <String>[];
              stages?.forEach((site, stage) {
                if (stage is String &&
                    stage != 'intact' &&
                    stage.isNotEmpty) {
                  concerningSites.add('$site: $stage');
                }
              });
              if (concerningSites.isEmpty) {
                widgets.add(pw.Text(
                  'All assessed skin sites intact.',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800),
                ));
              } else {
                widgets.add(pw.Text(
                  '${concerningSites.length} site(s) showing breakdown:',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800),
                ));
                for (final site in concerningSites) {
                  widgets.add(pw.Text('  \u2022 $site',
                      style: const pw.TextStyle(fontSize: 9)));
                }
              }
              final assessor = skinLatest['assessedByName'] as String?;
              final dateStr = skinLatest['dateString'] as String?;
              if (assessor != null || dateStr != null) {
                widgets.add(pw.SizedBox(height: 2));
                widgets.add(pw.Text(
                  'Assessed ${dateStr ?? ''}${assessor != null ? ' by $assessor' : ''}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600),
                ));
              }
            }
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text(
              'Repositioning: $turningLogsLast24h log${turningLogsLast24h == 1 ? '' : 's'} in the last 24 hours '
              '${turningLogsLast24h >= 12 ? '(meeting 2-hour standard)' : '(below 2-hour standard)'}',
              style: pw.TextStyle(
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
                color: turningLogsLast24h >= 12
                    ? PdfColors.green800
                    : PdfColors.orange800,
              ),
            ));
          }

          // Hydration aggregation
          if (d.hydrationCount > 0) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader('Hydration'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Text(
              '${d.hydrationCount} fluid intake log${d.hydrationCount == 1 ? '' : 's'} '
              '\u2014 avg ${d.hydrationAvgPerDay.toStringAsFixed(0)} oz/day',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
            ));
            if (d.hydrationTopFluid != null) {
              widgets.add(pw.Text(
                'Most logged fluid: ${d.hydrationTopFluid}',
                style: const pw.TextStyle(fontSize: 9),
              ));
            }
            // Flag low hydration (<48 oz/day is concerning for elders)
            if (d.hydrationAvgPerDay > 0 && d.hydrationAvgPerDay < 48) {
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text(
                '\u26A0 Below recommended 48 oz/day baseline',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.orange800,
                ),
              ));
            }
          }

          // Visitor pattern summary
          if (d.visitorCount > 0) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader('Visitor & Stimulus Patterns'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Text(
              '${d.visitorCount} visit${d.visitorCount == 1 ? '' : 's'} logged in this period',
              style: pw.TextStyle(
                  fontSize: 11, fontWeight: pw.FontWeight.bold),
            ));
            if (d.visitorTopName != null) {
              widgets.add(pw.Text(
                'Most frequent visitor: ${d.visitorTopName}',
                style: const pw.TextStyle(fontSize: 9),
              ));
            }
            if (d.visitorResponseCounts.isNotEmpty) {
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text(
                'Recipient response distribution:',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold),
              ));
              final sortedResponses = d.visitorResponseCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));
              for (final r in sortedResponses) {
                widgets.add(pw.Text(
                  '  \u2022 ${r.key[0].toUpperCase()}${r.key.substring(1)}: ${r.value}',
                  style: const pw.TextStyle(fontSize: 9),
                ));
              }
              // Flag if agitation/withdrawal dominates
              final negative = (d.visitorResponseCounts['agitated'] ?? 0) +
                  (d.visitorResponseCounts['withdrawn'] ?? 0) +
                  (d.visitorResponseCounts['confused'] ?? 0);
              if (negative > d.visitorCount / 2) {
                widgets.add(pw.SizedBox(height: 4));
                widgets.add(pw.Text(
                  '\u26A0 More than half of visits triggered agitation, '
                  'withdrawal, or confusion. Consider visitor frequency or '
                  'environmental adjustments.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange800,
                  ),
                ));
              }
            }
          }

          // Weight loss warning (if >5% loss detected in vitals)
          final wtSummary = d.vitals['WT'];
          if (wtSummary != null &&
              wtSummary.numericMax != null &&
              wtSummary.count >= 2) {
            final peakWeight = wtSummary.numericMax!;
            final currentWeight =
                double.tryParse(wtSummary.latestValue) ?? peakWeight;
            if (peakWeight > 0) {
              final pctChange =
                  ((currentWeight - peakWeight) / peakWeight) * 100;
              if (pctChange <= -5) {
                widgets.add(pw.SizedBox(height: 12));
                widgets.add(pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red50,
                    border: pw.Border.all(color: PdfColors.red200),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '\u26A0 WEIGHT ALERT: ${pctChange.abs().toStringAsFixed(1)}% '
                    'loss in this period '
                    '(${peakWeight.toStringAsFixed(1)} \u2192 '
                    '${currentWeight.toStringAsFixed(1)} ${wtSummary.unit})',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800),
                  ),
                ));
              }
            }
          }

          // Questions
          final questions = _questionsCtrl.text.trim();
          if (questions.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 16));
            widgets.add(_pdfSectionHeader('Questions for the Doctor'));
            widgets.add(pw.SizedBox(height: 6));
            widgets.add(pw.Text(questions,
                style: const pw.TextStyle(fontSize: 10)));
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  static pw.Widget _pdfMetaRow(String label, String value) {
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
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.white)),
        ),
      ],
    );
  }

  static pw.Widget _pdfVitalsTable(
    Map<String, _VitalSummary> vitals,
    DateFormat shortFmt,
  ) {
    final headers = ['Vital', 'Latest', 'Avg', 'Min – Max', 'Readings'];
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.2),
        1: pw.FlexColumnWidth(1.8),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.8),
        4: pw.FlexColumnWidth(1.0),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey50),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey700)),
                  ))
              .toList(),
        ),
        // Data rows
        ...vitals.values.map((v) {
          final avgStr = v.numericAvg != null
              ? v.numericAvg!.toStringAsFixed(1)
              : '—';
          final rangeStr =
              v.numericMin != null && v.numericMax != null
                  ? '${v.numericMin!.toStringAsFixed(1)} – ${v.numericMax!.toStringAsFixed(1)}'
                  : '—';
          final latestStr =
              '${v.latestValue}${v.unit.isNotEmpty ? ' ${v.unit}' : ''} (${shortFmt.format(v.latestDate)})';
          return pw.TableRow(
            decoration: v.concerning
                ? const pw.BoxDecoration(color: PdfColors.orange50)
                : null,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                  v.concerning ? '⚠ ${v.type}' : v.type,
                  style: pw.TextStyle(
                      fontSize: 9,
                      color: v.concerning
                          ? PdfColors.orange800
                          : PdfColors.black),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(latestStr,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(avgStr,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(rangeStr,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('${v.count}',
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeElder =
        context.watch<ActiveElderProvider>().activeElder;
    final userProfile =
        context.watch<UserProfileProvider>().userProfile;
    final meds =
        context.watch<MedicationDefinitionsProvider>().medDefinitions;
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid;

    if (activeElder == null || currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Appointment Prep'),
            backgroundColor: _kColor,
            foregroundColor: Colors.white),
        body: const Center(
            child: Text('No active care recipient selected.')),
      );
    }

    final elderName = activeElder.profileName;
    final caregiverName =
        userProfile?.displayName ?? 'Caregiver';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Prep'),
        backgroundColor: _kColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<JournalEntry>>(
        stream: context
            .read<JournalServiceProvider>()
            .getJournalEntriesStream(
              elderId: activeElder.id,
              currentUserId: currentUserId,
              startDate: _startDate,
              endDate: _endOfDay,
            ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          final prepData = _PrepData.from(entries, meds, _lookbackDays);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PrepHeader(
                        elderName: elderName,
                        preparedBy: caregiverName,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                      const SizedBox(height: 20),

                      // Vitals
                      if (prepData.vitals.isNotEmpty) ...[
                        _SectionCard(
                          title: 'Vitals Summary',
                          icon: Icons.monitor_heart_outlined,
                          color: const Color(0xFFF57C00),
                          child: _VitalsSection(vitals: prepData.vitals),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Medications
                      if (prepData.medications.isNotEmpty) ...[
                        _SectionCard(
                          title: 'Current Medications',
                          icon: Icons.medication_outlined,
                          color: const Color(0xFF1E88E5),
                          child:
                              _MedsSection(medications: prepData.medications),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Symptoms
                      _SectionCard(
                        title: 'Symptom Patterns',
                        icon: Icons.healing_outlined,
                        color: const Color(0xFFE53935),
                        child: _SymptomsSection(data: prepData),
                      ),
                      const SizedBox(height: 14),

                      // Sleep
                      _SectionCard(
                        title: 'Sleep Overview',
                        icon: Icons.bedtime_outlined,
                        color: const Color(0xFF5C6BC0),
                        child: _SleepSection(data: prepData),
                      ),
                      const SizedBox(height: 14),

                      // Notable events
                      _SectionCard(
                        title: 'Notable Events',
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFF57C00),
                        child: _NotableEventsSection(
                            events: prepData.notableEvents),
                      ),
                      const SizedBox(height: 14),

                      // Fall Risk Assessment (CDC STEADI)
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: context
                            .read<FirestoreService>()
                            .getFallRiskAssessmentsStream(activeElder.id),
                        builder: (context, fallSnap) {
                          if (!fallSnap.hasData ||
                              fallSnap.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final fallData = fallSnap.data!.first;
                          final fall = FallRiskAssessment.fromFirestore(
                              fallData['id'] as String? ?? '', fallData);
                          return _SectionCard(
                            title: 'Fall Risk (CDC STEADI)',
                            icon: Icons.elderly_outlined,
                            color: fall.riskColor,
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${fall.riskLevel} Risk',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: fall.riskColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Score: ${fall.rawRiskScore}/20',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(fall.riskSummary,
                                    style: const TextStyle(fontSize: 12)),
                                if (fall.missingProtections.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  ...fall.missingProtections.map((p) =>
                                      Text('\u26A0 $p',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: fall.riskColor))),
                                ],
                                const SizedBox(height: 6),
                                Text(fall.steadiRecommendation,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: AppTheme.textSecondary,
                                    )),
                                Text(
                                    'Assessed ${fall.dateString} by ${fall.assessedByName}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.textLight)),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      // Questions
                      _SectionCard(
                        title: 'Questions for the Doctor',
                        icon: Icons.help_outline,
                        color: _kColor,
                        child: TextField(
                          controller: _questionsCtrl,
                          maxLines: 5,
                          minLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Medication side effects?\nDosage changes needed?\nReferrals needed?\nFollow-up on recent test results?',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'Note: Questions are session-only and included in the PDF when shared.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Share bar
              _ShareBar(
                isGenerating: _isGenerating,
                onShare: () => _generateAndShare(
                    prepData, elderName, caregiverName),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PrepHeader extends StatelessWidget {
  const _PrepHeader({
    required this.elderName,
    required this.preparedBy,
    required this.startDate,
    required this.endDate,
  });
  final String elderName;
  final String preparedBy;
  final DateTime startDate;
  final DateTime endDate;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.checklist_outlined,
                    size: 22, color: _kColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      elderName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _kColor,
                      ),
                    ),
                    Text(
                      'Last 30 Days: ${fmt.format(startDate)} – ${fmt.format(endDate)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kColor.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Prepared by $preparedBy',
            style: TextStyle(
                fontSize: 12,
                color: _kColor.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _VitalsSection extends StatelessWidget {
  const _VitalsSection({required this.vitals});
  final Map<String, _VitalSummary> vitals;

  @override
  Widget build(BuildContext context) {
    final shortFmt = DateFormat('MMM d');
    return Column(
      children: vitals.values.map((v) {
        final avgStr = v.numericAvg != null
            ? v.numericAvg!.toStringAsFixed(1)
            : null;
        final rangeStr =
            v.numericMin != null && v.numericMax != null
                ? '${v.numericMin!.toStringAsFixed(1)} – ${v.numericMax!.toStringAsFixed(1)}'
                : null;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (v.concerning)
                const Padding(
                  padding: EdgeInsets.only(right: 4, top: 1),
                  child: Icon(Icons.warning_amber,
                      size: 14, color: Color(0xFFF57C00)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.type,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: v.concerning
                            ? const Color(0xFFF57C00)
                            : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 10,
                      children: [
                        _VitalChip(
                            label: 'Latest',
                            value:
                                '${v.latestValue}${v.unit.isNotEmpty ? ' ${v.unit}' : ''} (${shortFmt.format(v.latestDate)})'),
                        if (avgStr != null)
                          _VitalChip(label: 'Avg', value: avgStr),
                        if (rangeStr != null)
                          _VitalChip(label: 'Range', value: rangeStr),
                        _VitalChip(
                            label: 'Readings',
                            value: '${v.count}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _VitalChip extends StatelessWidget {
  const _VitalChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MedsSection extends StatelessWidget {
  const _MedsSection({required this.medications});
  final List<_MedSummary> medications;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: medications.map((med) {
        final adherenceColor = med.adherencePct >= 80
            ? const Color(0xFF43A047)
            : med.adherencePct >= 50
                ? const Color(0xFFF57C00)
                : AppTheme.dangerColor;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${med.name}${med.dose != null ? '  ${med.dose}' : ''}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    if (med.takenDays > 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        '${med.takenDays} of 30 days logged',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (med.takenDays > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: adherenceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: adherenceColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${med.adherencePct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: adherenceColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SymptomsSection extends StatelessWidget {
  const _SymptomsSection({required this.data});
  final _PrepData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SymptomRow(
          label: 'Pain',
          count: data.painCount,
          detail: data.painCount > 0
              ? 'Avg ${data.painAvg?.toStringAsFixed(1) ?? '—'}/10 · '
                  'Peak ${data.painMax?.toInt() ?? '—'}/10'
                  '${data.painTopLocation != null ? ' · ${data.painTopLocation}' : ''}'
              : null,
          trend: data.painCount >= 4 ? data.painTrend : null,
          higherIsWorse: true,
        ),
        const SizedBox(height: 10),
        _SymptomRow(
          label: 'Mood',
          count: data.moodCount,
          detail: data.moodCount > 0
              ? 'Avg ${data.moodAvg?.toStringAsFixed(1) ?? '—'}/5 · '
                  'Lowest ${data.moodMin?.toInt() ?? '—'}/5'
              : null,
          trend: data.moodCount >= 4 ? data.moodTrend : null,
          higherIsWorse: false,
        ),
      ],
    );
  }
}

class _SymptomRow extends StatelessWidget {
  const _SymptomRow({
    required this.label,
    required this.count,
    this.detail,
    this.trend,
    required this.higherIsWorse,
  });
  final String label;
  final int count;
  final String? detail;
  final String? trend;
  final bool higherIsWorse;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Text(
        '$label: No entries this period.',
        style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic),
      );
    }

    Color trendColor = AppTheme.textSecondary;
    IconData trendIcon = Icons.remove;
    if (trend == 'improving') {
      trendColor = const Color(0xFF43A047);
      trendIcon = higherIsWorse ? Icons.trending_down : Icons.trending_up;
    } else if (trend == 'worsening') {
      trendColor = AppTheme.dangerColor;
      trendIcon = higherIsWorse ? Icons.trending_up : Icons.trending_down;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$label ($count entries)',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (trend != null) ...[
              const SizedBox(width: 8),
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 2),
              Text(
                trend!,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendColor),
              ),
            ],
          ],
        ),
        if (detail != null) ...[
          const SizedBox(height: 2),
          Text(detail!,
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ],
    );
  }
}

class _SleepSection extends StatelessWidget {
  const _SleepSection({required this.data});
  final _PrepData data;

  @override
  Widget build(BuildContext context) {
    if (data.sleepCount == 0) {
      return Text(
        'No sleep entries this period.',
        style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic),
      );
    }
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _VitalChip(label: 'Nights', value: '${data.sleepCount}'),
        if (data.sleepAvgDuration != null)
          _VitalChip(
              label: 'Avg duration',
              value: '${data.sleepAvgDuration!.toStringAsFixed(1)} hrs'),
        if (data.sleepAvgQuality != null)
          _VitalChip(
              label: 'Avg quality',
              value: '${data.sleepAvgQuality!.toStringAsFixed(1)}/5'),
      ],
    );
  }
}

class _NotableEventsSection extends StatelessWidget {
  const _NotableEventsSection({required this.events});
  final List<_NotableEvent> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Text(
        'No concerning events in this period.',
        style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic),
      );
    }
    final shortFmt = DateFormat('MMM d');
    return Column(
      children: events.map((e) {
        final color = e.highSeverity
            ? AppTheme.dangerColor
            : const Color(0xFFF57C00);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                e.highSeverity
                    ? Icons.error_outline
                    : Icons.warning_amber_outlined,
                size: 15,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${shortFmt.format(e.date)} — ${e.description}',
                  style:
                      TextStyle(fontSize: 12, color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.isGenerating,
    required this.onShare,
  });
  final bool isGenerating;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: FilledButton.icon(
        icon: isGenerating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.picture_as_pdf_outlined, size: 20),
        label: Text(
          isGenerating ? 'Generating PDF…' : 'Share PDF with Doctor',
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _kColor,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: isGenerating ? null : onShare,
      ),
    );
  }
}
