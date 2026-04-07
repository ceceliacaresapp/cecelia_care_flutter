// lib/services/export_service.dart
//
// Generates CSV and PDF exports from a filtered list of JournalEntry objects.
//
// Both generateCsv() and generatePdf() now accept an optional ExportMeta
// parameter (defined in export_screen.dart). When supplied it adds:
//
//   CSV  — 4 metadata rows before the column header row:
//            Report Title, Care Recipient, Prepared By, Date Range
//
//   PDF  — a styled cover header block with the same fields, then entries
//            grouped by type with a type section header before each group.

import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/wellness_checkin.dart';
import 'package:cecelia_care_flutter/screens/export_screen.dart'
    show ExportMeta;

class ExportService {
  // ---------------------------------------------------------------------------
  // CSV
  // ---------------------------------------------------------------------------

  /// Generates a CSV string.
  ///
  /// When [meta] is provided the file opens with 4 context rows followed by
  /// a blank row, then the standard column headers and data rows.
  ///
  /// When [wellnessCheckins] is provided, a wellness section is appended
  /// after the care log entries.
  String generateCsv(
    List<JournalEntry> entries, {
    ExportMeta? meta,
    List<WellnessCheckin>? wellnessCheckins,
  }) {
    if (entries.isEmpty) return '';

    final rows = <List<dynamic>>[];

    // ── Metadata header block ──────────────────────────────────────────────
    if (meta != null) {
      rows.addAll([
        ['Cecelia Care — Care Log Export'],
        ['Care Recipient', meta.elderName],
        ['Prepared By', meta.caregiverName],
        ['Date Range', meta.dateRangeDisplay],
        ['Categories', meta.typesDisplay],
        [], // blank spacer row
      ]);
    }

    // ── Column headers ─────────────────────────────────────────────────────
    rows.add([
      'Date',
      'Time',
      'Type',
      'Logged By',
      'Primary Info',
      'Value / Intensity',
      'Unit / Secondary Info',
      'Notes',
    ]);

    // ── Data rows ──────────────────────────────────────────────────────────
    for (final entry in entries) {
      rows.add(_getFormattedCsvRow(entry));
    }

    // ── Wellness check-in section (optional) ────────────────────────────
    if (wellnessCheckins != null && wellnessCheckins.isNotEmpty) {
      rows.addAll([
        [], // blank spacer
        ['CAREGIVER WELLNESS CHECK-INS'],
        [
          'Date',
          'Mood (1-5)',
          'Sleep (1-5)',
          'Exercise (1-5)',
          'Social (1-5)',
          'Me-Time (1-5)',
          'Wellbeing Score',
          'Burnout Risk',
          'Note',
        ],
      ]);
      for (final c in wellnessCheckins) {
        rows.add([
          c.dateString,
          c.mood,
          c.sleepQuality,
          c.exercise,
          c.socialConnection,
          c.meTime,
          c.wellbeingScore.toStringAsFixed(1),
          c.burnoutRisk.toStringAsFixed(1),
          c.note ?? '',
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  /// Generates a PDF document.
  ///
  /// When [meta] is provided the document opens with a styled cover-header
  /// block, then entries are grouped by entry type with a bold section
  /// header before each group.
  ///
  /// When [wellnessCheckins] is provided, a wellness section is appended
  /// after the care log entries.
  Future<Uint8List> generatePdf(
    List<JournalEntry> entries, {
    ExportMeta? meta,
    List<WellnessCheckin>? wellnessCheckins,
  }) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('yyyy-MM-dd');

    // Group entries by type (preserving natural order within each group)
    final Map<EntryType, List<JournalEntry>> grouped = {};
    for (final e in entries) {
      grouped.putIfAbsent(e.type, () => []).add(e);
    }

    // Sort groups so medical types come before admin types
    final typeOrder = [
      EntryType.medication,
      EntryType.vital,
      EntryType.mood,
      EntryType.sleep,
      EntryType.meal,
      EntryType.activity,
      EntryType.pain,
      EntryType.expense,
      EntryType.message,
      EntryType.caregiverJournal,
    ];
    final sortedTypes = grouped.keys.toList()
      ..sort((a, b) {
        final ai = typeOrder.indexOf(a);
        final bi = typeOrder.indexOf(b);
        final aIdx = ai == -1 ? 999 : ai;
        final bIdx = bi == -1 ? 999 : bi;
        return aIdx.compareTo(bIdx);
      });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context ctx) => _buildPageHeader(meta, ctx),
        footer: (pw.Context ctx) => _buildPageFooter(ctx),
        build: (pw.Context context) {
          final widgets = <pw.Widget>[];

          // ── Cover header ─────────────────────────────────────────────────
          if (meta != null) {
            widgets.add(_buildCoverHeader(meta));
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(pw.Divider(thickness: 1.5));
            widgets.add(pw.SizedBox(height: 16));
          } else {
            widgets.add(pw.Text(
              'Care Journal Export',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold),
            ));
            widgets.add(pw.SizedBox(height: 20));
          }

          if (entries.isEmpty) {
            widgets.add(pw.Text('No entries to export.'));
            return widgets;
          }

          // ── Grouped entry sections ────────────────────────────────────────
          for (final type in sortedTypes) {
            final group = grouped[type]!;

            // Section header
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey100,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  _typeLabel(type).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));

            // Entries in this group
            for (int i = 0; i < group.length; i++) {
              widgets.add(_buildPdfEntry(group[i], dateFmt));
              if (i < group.length - 1) {
                widgets.add(pw.Divider(
                    height: 12, thickness: 0.5, color: PdfColors.grey300));
              }
            }
            widgets.add(pw.SizedBox(height: 16));
          }

          // ── Wellness check-in section (optional) ──────────────────────
          if (wellnessCheckins != null && wellnessCheckins.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.purple100,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'CAREGIVER WELLNESS CHECK-INS',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.purple800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: 10));

            // Table header
            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColors.grey300, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.0),
                  1: pw.FlexColumnWidth(1.0),
                  2: pw.FlexColumnWidth(1.0),
                  3: pw.FlexColumnWidth(1.0),
                  4: pw.FlexColumnWidth(1.0),
                  5: pw.FlexColumnWidth(1.0),
                  6: pw.FlexColumnWidth(1.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColors.purple50),
                    children: [
                      'Date', 'Mood', 'Sleep', 'Exercise',
                      'Social', 'Me-Time', 'Wellbeing',
                    ]
                        .map((h) => pw.Padding(
                              padding: const pw.EdgeInsets.all(4),
                              child: pw.Text(h,
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight:
                                          pw.FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                  ...wellnessCheckins.map((c) => pw.TableRow(
                        children: [
                          c.dateString,
                          '${c.mood} ${c.moodLabel}',
                          '${c.sleepQuality}',
                          '${c.exercise}',
                          '${c.socialConnection}',
                          '${c.meTime}',
                          c.wellbeingScore.toStringAsFixed(0),
                        ]
                            .map((v) => pw.Padding(
                                  padding:
                                      const pw.EdgeInsets.all(4),
                                  child: pw.Text(v,
                                      style: const pw.TextStyle(
                                          fontSize: 8)),
                                ))
                            .toList(),
                      )),
                ],
              ),
            );

            // Summary line
            if (wellnessCheckins.length >= 2) {
              final avgScore = wellnessCheckins.fold<double>(
                      0, (sum, c) => sum + c.wellbeingScore) /
                  wellnessCheckins.length;
              widgets.add(pw.SizedBox(height: 6));
              widgets.add(pw.Text(
                'Average wellbeing: ${avgScore.toStringAsFixed(1)} / 100  '
                '(${wellnessCheckins.length} check-ins)',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontStyle: pw.FontStyle.italic,
                  color: PdfColors.blueGrey500,
                ),
              ));
            }
          }

          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // PDF sub-builders
  // ---------------------------------------------------------------------------

  pw.Widget _buildCoverHeader(ExportMeta meta) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColors.indigo200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Cecelia Care — Care Log Report',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.SizedBox(height: 12),
          _metaRow('Care Recipient', meta.elderName),
          pw.SizedBox(height: 4),
          _metaRow('Prepared By', meta.caregiverName),
          pw.SizedBox(height: 4),
          _metaRow('Date Range', meta.dateRangeDisplay),
          pw.SizedBox(height: 4),
          _metaRow('Categories', meta.typesDisplay),
          pw.SizedBox(height: 4),
          _metaRow(
            'Generated',
            DateFormat('MMM d, yyyy — h:mm a').format(DateTime.now()),
          ),
        ],
      ),
    );
  }

  pw.Widget _metaRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 100,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.blueGrey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPageHeader(ExportMeta? meta, pw.Context ctx) {
    if (ctx.pageNumber == 1) return pw.SizedBox.shrink();
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        meta != null
            ? 'Care Log — ${meta.elderName} — ${meta.dateRangeDisplay}'
            : 'Care Log Export',
        style: const pw.TextStyle(
            fontSize: 9, color: PdfColors.blueGrey400),
      ),
    );
  }

  pw.Widget _buildPageFooter(pw.Context ctx) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Text(
        'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
        style:
            const pw.TextStyle(fontSize: 9, color: PdfColors.blueGrey400),
      ),
    );
  }

  pw.Widget _buildPdfEntry(JournalEntry entry, DateFormat dateFmt) {
    final rowData = _getFormattedCsvRow(entry);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Date / time / logged-by line
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '${rowData[0]}  ${rowData[1]}',
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 11),
            ),
            pw.Text(
              'By: ${rowData[3]}',
              style: const pw.TextStyle(
                  fontSize: 10, color: PdfColors.blueGrey500),
            ),
          ],
        ),
        pw.SizedBox(height: 3),
        // Primary info
        pw.Text(rowData[4].toString(),
            style: const pw.TextStyle(fontSize: 11)),
        // Optional fields
        if (rowData[5].toString().isNotEmpty)
          _detailLine('Value', rowData[5].toString()),
        if (rowData[6].toString().isNotEmpty)
          _detailLine('Info', rowData[6].toString()),
        if (rowData[7].toString().isNotEmpty)
          _detailLine('Notes', rowData[7].toString()),
      ],
    );
  }

  pw.Widget _detailLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 48,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blueGrey500,
                  fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared row formatter — used by both CSV and PDF
  // ---------------------------------------------------------------------------

  List<dynamic> _getFormattedCsvRow(JournalEntry entry) {
    final date =
        DateFormat('yyyy-MM-dd').format(entry.entryTimestamp.toDate());
    final time = DateFormat.Hm().format(entry.entryTimestamp.toDate());
    final type = entry.type.name;
    final loggedBy =
        entry.loggedByDisplayName ?? entry.loggedByUserId;

    final d = entry.data ?? {};

    String primaryInfo = '';
    String valueIntensity = '';
    String unitSecondaryInfo = '';
    String notes = '';

    switch (entry.type) {
      case EntryType.activity:
        primaryInfo = d['activityType'] as String? ?? 'N/A';
        valueIntensity = d['duration'] as String? ?? '';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.expense:
        primaryInfo =
            (d['description'] as String?)?.isNotEmpty == true
                ? d['description'] as String
                : d['category'] as String? ?? 'N/A';
        valueIntensity =
            (d['amount'] as num?)?.toStringAsFixed(2) ?? '';
        unitSecondaryInfo = d['category'] as String? ?? '';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.meal:
        primaryInfo = d['description'] as String? ?? 'N/A';
        valueIntensity = d['calories']?.toString() ?? '';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.medication:
        primaryInfo = d['name'] as String? ?? 'N/A';
        final taken = d['taken'] as bool?;
        valueIntensity = taken == true
            ? 'Taken'
            : taken == false
                ? 'Skipped'
                : '';
        unitSecondaryInfo = d['dose'] as String? ?? '';
        notes = d['time'] as String? ?? '';
        break;

      case EntryType.mood:
        primaryInfo = d['moodLevel']?.toString() ?? 'N/A';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.pain:
        primaryInfo = d['location'] as String? ?? 'N/A';
        valueIntensity = d['intensity']?.toString() ?? '';
        unitSecondaryInfo = d['description'] as String? ?? '';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.sleep:
        primaryInfo = d['totalDuration'] as String? ?? 'N/A';
        final quality = d['quality'];
        valueIntensity = quality?.toString() ?? '';
        unitSecondaryInfo =
            quality != null ? 'Quality: $quality/5' : '';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.vital:
        primaryInfo = d['vitalType'] as String? ?? 'N/A';
        valueIntensity = d['value'] as String? ?? '';
        unitSecondaryInfo = d['unit'] as String? ?? '';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.handoff:
        final shift = d['shift'] as String?;
        primaryInfo = (shift != null && shift.isNotEmpty)
            ? '$shift Shift Handoff'
            : 'Shift Handoff';
        valueIntensity = d['completed'] as String? ?? '';
        unitSecondaryInfo = d['pending'] as String? ?? '';
        notes = d['concerns'] as String? ?? '';
        break;

      case EntryType.incontinence:
        final iType = d['incontinenceType'] as String? ?? 'N/A';
        primaryInfo = iType.isNotEmpty
            ? '${iType[0].toUpperCase()}${iType.substring(1)}'
            : 'N/A';
        valueIntensity = d['severity'] as String? ?? '';
        final bristol = d['bristolType']?.toString();
        final urine = d['urineColor'] as String?;
        final skin = d['skinCondition'] as String? ?? '';
        unitSecondaryInfo = [
          if (bristol != null && bristol.isNotEmpty) 'Bristol $bristol',
          if (urine != null && urine.isNotEmpty) 'Urine: $urine',
          if (skin == 'irritated' || skin == 'broken') 'Skin: $skin',
        ].join(' · ');
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.nightWaking:
        final cause = d['cause'] as String? ?? 'Unknown';
        primaryInfo = cause.isNotEmpty
            ? '${cause[0].toUpperCase()}${cause.substring(1)}'
            : 'Unknown';
        valueIntensity = d['duration'] as String? ?? '';
        final returned = d['returnedToSleep'] as bool?;
        unitSecondaryInfo = returned == true
            ? 'Returned to sleep'
            : returned == false
                ? 'Did not return'
                : '';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.hydration:
        final fluidType = d['fluidType'] as String? ?? 'Fluid';
        primaryInfo = fluidType.isNotEmpty
            ? '${fluidType[0].toUpperCase()}${fluidType.substring(1)}'
            : 'Fluid';
        valueIntensity = d['volume']?.toString() ?? '';
        unitSecondaryInfo = d['unit'] as String? ?? 'oz';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.visitor:
        primaryInfo = d['visitorName'] as String? ?? 'Unknown';
        final relationship = d['relationship'] as String? ?? '';
        valueIntensity = d['duration'] as String? ?? '';
        final response = d['response'] as String? ?? '';
        unitSecondaryInfo = [
          if (relationship.isNotEmpty) relationship,
          if (response.isNotEmpty)
            '${response[0].toUpperCase()}${response.substring(1)}',
        ].join(' · ');
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.message:
      case EntryType.caregiverJournal:
        primaryInfo =
            entry.text ?? d['text'] as String? ?? 'N/A';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.image:
        primaryInfo = d['title'] as String? ?? 'Image';
        notes = d['note'] as String? ?? '';
        break;

      default:
        primaryInfo =
            entry.text ?? d['text'] as String? ?? 'N/A';
    }

    final typeDisplay = type.isNotEmpty
        ? type[0].toUpperCase() + type.substring(1)
        : type;

    return [
      date,
      time,
      typeDisplay,
      loggedBy,
      primaryInfo,
      valueIntensity,
      unitSecondaryInfo,
      notes,
    ];
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _typeLabel(EntryType t) {
    switch (t) {
      case EntryType.medication: return 'Medications';
      case EntryType.vital: return 'Vitals';
      case EntryType.mood: return 'Mood';
      case EntryType.sleep: return 'Sleep';
      case EntryType.meal: return 'Meals';
      case EntryType.activity: return 'Activity';
      case EntryType.pain: return 'Pain';
      case EntryType.expense: return 'Expenses';
      case EntryType.message: return 'Messages';
      case EntryType.caregiverJournal: return 'Caregiver Journal';
      case EntryType.image: return 'Images';
      case EntryType.handoff: return 'Shift Handoffs';
      case EntryType.incontinence: return 'Continence';
      case EntryType.nightWaking: return 'Night Waking';
      case EntryType.hydration: return 'Hydration';
      case EntryType.visitor: return 'Visitors';
      default: return t.name[0].toUpperCase() + t.name.substring(1);
    }
  }
}
