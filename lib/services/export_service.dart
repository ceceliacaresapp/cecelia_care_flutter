import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';

// ---------------------------------------------------------------------------
// FIX: All `entry as XxxEntry` casts removed.
//
// The timeline stream returns List<JournalEntry> — base objects, not typed
// subclasses. Every `as SleepEntry`, `as MoodEntry`, etc. threw a type-cast
// exception at runtime. The type-specific field values live in `entry.data`
// (a Map<String, dynamic>) which is always present on the base class.
// We now read directly from that map, exactly as the timeline summary
// extractor in timeline_screen.dart already does.
// ---------------------------------------------------------------------------

class ExportService {
  /// Generates a CSV string from a list of journal entries.
  String generateCsv(List<JournalEntry> entries) {
    if (entries.isEmpty) return '';

    final List<List<dynamic>> rows = [
      [
        'Date',
        'Time',
        'Type',
        'Logged By',
        'Primary Info',
        'Value / Intensity',
        'Unit / Secondary Info',
        'Notes',
      ],
      for (final entry in entries) _getFormattedCsvRow(entry),
    ];

    return const ListToCsvConverter().convert(rows);
  }

  List<dynamic> _getFormattedCsvRow(JournalEntry entry) {
    final date =
        DateFormat('yyyy-MM-dd').format(entry.entryTimestamp.toDate());
    final time = DateFormat.Hm().format(entry.entryTimestamp.toDate());
    final type = entry.type.name;
    final loggedBy = entry.loggedByDisplayName ?? entry.loggedByUserId;

    // All fields are read from entry.data — no subclass casts needed.
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

      case EntryType.message:
      case EntryType.caregiverJournal:
        primaryInfo = entry.text ?? d['text'] as String? ?? 'N/A';
        notes = d['note'] as String? ?? '';
        break;

      case EntryType.image:
        primaryInfo = d['title'] as String? ?? 'Image';
        notes = d['note'] as String? ?? '';
        break;

      default:
        primaryInfo = entry.text ?? d['text'] as String? ?? 'N/A';
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

  /// Generates a PDF document from a list of journal entries.
  Future<Uint8List> generatePdf(List<JournalEntry> entries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Care Journal Export',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            if (entries.isEmpty)
              pw.Paragraph(text: 'No entries to export.')
            else
              for (final entry in entries) ...[
                _buildPdfEntry(entry),
                pw.Divider(height: 20),
              ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfEntry(JournalEntry entry) {
    final rowData = _getFormattedCsvRow(entry);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '${rowData[0]} ${rowData[1]} — ${rowData[2]}',
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 4),
        pw.Text('Logged by: ${rowData[3]}'),
        pw.SizedBox(height: 2),
        pw.Text('Details: ${rowData[4]}'),
        if (rowData[5].toString().isNotEmpty)
          pw.Text('Value / Intensity: ${rowData[5]}'),
        if (rowData[6].toString().isNotEmpty)
          pw.Text('Unit / Secondary Info: ${rowData[6]}'),
        if (rowData[7].toString().isNotEmpty)
          pw.Text('Notes: ${rowData[7]}'),
      ],
    );
  }
}
