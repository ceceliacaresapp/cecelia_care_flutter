// lib/screens/export_screen.dart
//
// Surfaces the existing ExportService so caregivers can download their care
// logs as CSV or PDF. Reached from Settings → Export & Reports.
//
// Dependencies (add to pubspec.yaml if not already present):
//   share_plus: ^7.0.0   — cross-platform file sharing sheet
//   path_provider: ^2.0.0 — temp directory for writing the PDF file
//
// The screen intentionally does NOT use getJournalEntriesStream() because
// export is a one-shot snapshot, not a live feed. It calls
// FirestoreService.getJournalEntriesStream() via the provider and converts
// the first emission to a Future using .first — this avoids subscribing to
// an open socket for what is fundamentally a "fetch once and export" task.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/export_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Export format
// ---------------------------------------------------------------------------

enum _ExportFormat { csv, pdf }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ExportScreen extends StatefulWidget {
  final ElderProfile activeElder;

  const ExportScreen({super.key, required this.activeElder});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  // Date range — defaults to the last 30 days
  DateTime _startDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  _ExportFormat _format = _ExportFormat.pdf;
  bool _isExporting = false;
  String? _lastExportPath;

  final _exportService = ExportService();
  final _dateFmt = DateFormat('MMM d, yyyy');

  // ---------------------------------------------------------------------------
  // Date pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null && mounted) {
      setState(() {
        _startDate = picked;
        _lastExportPath = null;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() {
        _endDate = picked;
        _lastExportPath = null;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Export logic
  // ---------------------------------------------------------------------------

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
      _lastExportPath = null;
    });

    try {
      final currentUserId = AuthService.currentUserId;
      if (currentUserId == null) {
        _showError('You must be signed in to export.');
        return;
      }

      // Fetch entries for the selected date range as a one-shot snapshot.
      final journalProvider =
          context.read<JournalServiceProvider>();

      // Include the full end date day by advancing endDate to 23:59:59.
      final endOfDay = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        23, 59, 59,
      );

      final List<JournalEntry> entries = await journalProvider
          .getJournalEntriesStream(
            elderId: widget.activeElder.id,
            currentUserId: currentUserId,
            startDate: _startDate,
            endDate: endOfDay,
          )
          .first;

      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No entries found for the selected date range.'),
          ));
        }
        return;
      }

      // Build filename
      final rangeLabel =
          '${DateFormat('yyyyMMdd').format(_startDate)}'
          '_${DateFormat('yyyyMMdd').format(_endDate)}';
      final elderName = widget.activeElder.profileName
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      final Directory tempDir = await getTemporaryDirectory();

      if (_format == _ExportFormat.csv) {
        final csv = _exportService.generateCsv(entries);
        final file = File(
            '${tempDir.path}/${elderName}_care_log_$rangeLabel.csv');
        await file.writeAsString(csv);

        if (mounted) {
          setState(() => _lastExportPath = file.path);
          await _shareFile(file.path, 'text/csv');
        }
      } else {
        final pdfBytes = await _exportService.generatePdf(entries);
        final file = File(
            '${tempDir.path}/${elderName}_care_report_$rangeLabel.pdf');
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          setState(() => _lastExportPath = file.path);
          await _shareFile(file.path, 'application/pdf');
        }
      }
    } catch (e) {
      debugPrint('ExportScreen._handleExport error: $e');
      _showError('Export failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareFile(String path, String mimeType) async {
    await Share.shareXFiles(
      [XFile(path, mimeType: mimeType)],
      subject:
          'Care log for ${widget.activeElder.profileName} — '
          '${_dateFmt.format(_startDate)} to ${_dateFmt.format(_endDate)}',
    );
  }

  // Re-share the last export without regenerating
  Future<void> _reshare() async {
    if (_lastExportPath == null) return;
    final mimeType = _format == _ExportFormat.csv
        ? 'text/csv'
        : 'application/pdf';
    await _shareFile(_lastExportPath!, mimeType);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.dangerColor,
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export care logs'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: 24, vertical: 24),
        children: [

          // ── Elder context ──────────────────────────────────────────────
          Text(
            'Care recipient',
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.activeElder.profileName,
            style: textTheme.titleMedium,
          ),

          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // ── Date range ─────────────────────────────────────────────────
          Text(
            'DATE RANGE',
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  date: _startDate,
                  formatter: _dateFmt,
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateButton(
                  label: 'To',
                  date: _endDate,
                  formatter: _dateFmt,
                  onTap: _pickEndDate,
                ),
              ),
            ],
          ),

          // Quick range chips
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _RangeChip(
                label: 'Last 7 days',
                onTap: () => setState(() {
                  _startDate = DateTime.now()
                      .subtract(const Duration(days: 7));
                  _endDate = DateTime.now();
                  _lastExportPath = null;
                }),
              ),
              _RangeChip(
                label: 'Last 30 days',
                onTap: () => setState(() {
                  _startDate = DateTime.now()
                      .subtract(const Duration(days: 30));
                  _endDate = DateTime.now();
                  _lastExportPath = null;
                }),
              ),
              _RangeChip(
                label: 'Last 90 days',
                onTap: () => setState(() {
                  _startDate = DateTime.now()
                      .subtract(const Duration(days: 90));
                  _endDate = DateTime.now();
                  _lastExportPath = null;
                }),
              ),
              _RangeChip(
                label: 'This year',
                onTap: () => setState(() {
                  _startDate = DateTime(DateTime.now().year, 1, 1);
                  _endDate = DateTime.now();
                  _lastExportPath = null;
                }),
              ),
            ],
          ),

          const SizedBox(height: 28),
          const Divider(height: 1),
          const SizedBox(height: 24),

          // ── Format picker ──────────────────────────────────────────────
          Text(
            'FORMAT',
            style: textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _FormatCard(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF Report',
                  description: 'Formatted, ready to share with a doctor',
                  selected: _format == _ExportFormat.pdf,
                  onTap: () => setState(() {
                    _format = _ExportFormat.pdf;
                    _lastExportPath = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormatCard(
                  icon: Icons.table_chart_outlined,
                  label: 'CSV Spreadsheet',
                  description: 'Raw data for analysis or backup',
                  selected: _format == _ExportFormat.csv,
                  onTap: () => setState(() {
                    _format = _ExportFormat.csv;
                    _lastExportPath = null;
                  }),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Export button ──────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _handleExport,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textOnPrimary,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(
                _isExporting
                    ? 'Generating…'
                    : _format == _ExportFormat.pdf
                        ? 'Generate & share PDF'
                        : 'Generate & share CSV',
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.textOnPrimary,
              ),
            ),
          ),

          // Re-share last export (shown once a file has been generated)
          if (_lastExportPath != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reshare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share again'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(
                      color: AppTheme.primaryColor, width: 1.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Info note ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Exports include all logged care entries '
                    '(medications, vitals, mood, sleep, meals, '
                    'activities, pain, and expenses) for the '
                    'selected date range. Messages are not included.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
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
// Private helper widgets
// ---------------------------------------------------------------------------

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final DateFormat formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppTheme.textLight.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  formatter.format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.06)
              : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : AppTheme.textLight.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
