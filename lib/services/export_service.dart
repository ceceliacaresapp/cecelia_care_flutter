import 'dart:typed_data';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/activity_entry.dart';
import 'package:cecelia_care_flutter/models/expense_entry.dart';
import 'package:cecelia_care_flutter/models/meal_entry.dart';
import 'package:cecelia_care_flutter/models/medication_entry.dart';
import 'package:cecelia_care_flutter/models/mood_entry.dart';
import 'package:cecelia_care_flutter/models/pain_entry.dart';
import 'package:cecelia_care_flutter/models/sleep_entry.dart';
import 'package:cecelia_care_flutter/models/vital_entry.dart';
import 'package:cecelia_care_flutter/models/message_entry.dart'; 

class ExportService {
  /// Generates a CSV string from a list of journal entries.
  String generateCsv(List<JournalEntry> entries) {
    if (entries.isEmpty) {
      return '';
    }

    List<List<dynamic>> rows = [];

    // Add CSV headers
    rows.add([
      'Date',
      'Time',
      'Type',
      'Logged By',
      'Primary Info', // e.g., Meal description, Medication name
      'Value/Intensity', // e.g., Pain intensity, Vital value
      'Unit/Secondary Info', // e.g., Vital unit, Medication dose
      'Notes'
    ]);

    // Add data rows
    for (var entry in entries) {
      rows.add(_getFormattedCsvRow(entry));
    }

    return const ListToCsvConverter().convert(rows);
  }

  List<dynamic> _getFormattedCsvRow(JournalEntry entry) {
    String date = DateFormat('yyyy-MM-dd').format(entry.entryTimestamp.toDate());
    String time = DateFormat.Hm().format(entry.entryTimestamp.toDate()); // HH:mm
    
    // FIX 1: Access the Enum name, not the Enum itself
    String type = entry.type.name; 
    
    String loggedBy = entry.loggedByDisplayName ?? entry.loggedByUserId;

    String primaryInfo = '';
    String? valueIntensity = '';
    String? unitSecondaryInfo = '';
    String? notes = '';

    // FIX 2: Switch on the Enum directly (or use type.toLowerCase())
    switch (entry.type) {
      case EntryType.activity:
        final e = entry as ActivityEntry;
        // FIX 3: Updated field names based on common model properties
        primaryInfo = e.activityName ?? 'N/A'; 
        valueIntensity = e.durationMinutes?.toString(); 
        unitSecondaryInfo = e.assistanceLevel;
        notes = e.note;
        break;

      case EntryType.expense:
        final e = entry as ExpenseEntry;
        primaryInfo = e.description ?? e.category ?? 'N/A';
        valueIntensity = e.amount?.toStringAsFixed(2);
        unitSecondaryInfo = e.category;
        notes = e.note;
        break;

      case EntryType.meal:
        final e = entry as MealEntry;
        primaryInfo = e.description ?? 'N/A';
        valueIntensity = e.calories?.toString();
        unitSecondaryInfo = e.mealType;
        notes = e.note;
        break;

      case EntryType.medication:
        final e = entry as MedicationEntry;
        primaryInfo = e.name;
        valueIntensity = e.taken ? 'Taken' : 'Skipped';
        unitSecondaryInfo = e.dose;
        notes = e.schedule;
        break;

      case EntryType.mood:
        final e = entry as MoodEntry;
        primaryInfo = e.mood ?? 'N/A';
        valueIntensity = e.intensity?.toString();
        notes = e.note;
        break;

      case EntryType.pain:
        final e = entry as PainEntry;
        primaryInfo = e.location ?? 'N/A';
        valueIntensity = e.intensity?.toString();
        unitSecondaryInfo = e.description;
        notes = e.note;
        break;

      case EntryType.sleep:
        final e = entry as SleepEntry;
        primaryInfo = 'Sleep Cycle';
        
        // FIX 4: Updated field names for SleepEntry (startTime/endTime)
        if (e.startTime != null) primaryInfo += ' Start: ${DateFormat.Hm().format(e.startTime!)}';
        if (e.endTime != null) primaryInfo += ' End: ${DateFormat.Hm().format(e.endTime!)}';
        
        // Calculate duration in hours if available
        if (e.startTime != null && e.endTime != null) {
           final duration = e.endTime!.difference(e.startTime!);
           valueIntensity = (duration.inMinutes / 60).toStringAsFixed(1);
        }
        
        unitSecondaryInfo = e.quality != null ? 'Quality: ${e.quality}/5' : null;
        notes = e.notes; 
        break;

      case EntryType.vital:
        final e = entry as VitalEntry;
        primaryInfo = e.vitalType;
        valueIntensity = e.value;
        unitSecondaryInfo = e.unit;
        notes = e.note;
        break;

      case EntryType.message:
        if (entry is MessageEntry) {
          primaryInfo = entry.text ?? 'N/A';
        } else {
          primaryInfo = 'Message content N/A';
        }
        break;
        
      default:
        primaryInfo = 'Unknown Entry Type';
    }

    return [
      date,
      time,
      type.substring(0, 1).toUpperCase() + type.substring(1), // Capitalize first letter
      loggedBy,
      primaryInfo,
      valueIntensity ?? '',
      unitSecondaryInfo ?? '',
      notes ?? ''
    ];
  }

  /// Generates a PDF document from a list of journal entries.
  Future<Uint8List> generatePdf(List<JournalEntry> entries) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];
          widgets.add(pw.Header(
            level: 0,
            child: pw.Text('Journal Export', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ));
          widgets.add(pw.SizedBox(height: 20));

          if (entries.isEmpty) {
            widgets.add(pw.Paragraph(text: 'No entries to export.'));
          } else {
            for (var entry in entries) {
              widgets.add(_buildPdfEntry(entry));
              widgets.add(pw.Divider(height: 20));
            }
          }
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfEntry(JournalEntry entry) {
    // Reuse CSV formatting logic for data extraction
    final rowData = _getFormattedCsvRow(entry); 

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${rowData[0]} ${rowData[1]} - ${rowData[2]}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
        pw.SizedBox(height: 4),
        pw.Text('Logged By: ${rowData[3]}'),
        pw.SizedBox(height: 2),
        pw.Text('Details: ${rowData[4]}'),
        if (rowData[5].toString().isNotEmpty) pw.Text('Value/Intensity: ${rowData[5]}'),
        if (rowData[6].toString().isNotEmpty) pw.Text('Unit/Secondary Info: ${rowData[6]}'),
        if (rowData[7].toString().isNotEmpty) pw.Text('Notes: ${rowData[7]}'),
      ],
    );
  }
}