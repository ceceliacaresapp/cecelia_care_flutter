// lib/screens/export_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/export_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kExportColor = Color(0xFF5C6BC0); // indigo — matches Settings tile

// Entry types that are meaningful to export. Messages and caregiver journal
// entries are kept out of medical exports by default but the caregiver can
// opt them in by checking the chip.
const _kExportableTypes = [
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

// ---------------------------------------------------------------------------
// Format enum
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
  // Date range — defaults to last 30 days
  DateTime _startDate =
      DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Entry type filter — default: all medical types, exclude messages
  late Set<EntryType> _selectedTypes;

  _ExportFormat _format = _ExportFormat.pdf;
  bool _isExporting = false;
  String? _lastExportPath;

  final _exportService = ExportService();
  final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    // Default selection: everything except messages and caregiver journal
    _selectedTypes = _kExportableTypes
        .where((t) =>
            t != EntryType.message && t != EntryType.caregiverJournal)
        .toSet();
  }

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
    if (_selectedTypes.isEmpty) {
      _showError('Please select at least one entry type to export.');
      return;
    }

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

      // Caregiver display name for the report header
      final caregiverName =
          Provider.of<UserProfileProvider>(context, listen: false)
                  .userProfile
                  ?.displayName ??
              'Caregiver';

      final journalProvider = context.read<JournalServiceProvider>();
      final endOfDay = DateTime(
          _endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      // One-shot fetch
      final List<JournalEntry> allEntries = await journalProvider
          .getJournalEntriesStream(
            elderId: widget.activeElder.id,
            currentUserId: currentUserId,
            startDate: _startDate,
            endDate: endOfDay,
          )
          .first;

      // Apply category filter
      final entries = allEntries
          .where((e) => _selectedTypes.contains(e.type))
          .toList();

      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'No entries found for the selected filters.'),
          ));
        }
        return;
      }

      // Filename
      final rangeLabel =
          '${DateFormat('yyyyMMdd').format(_startDate)}'
          '_${DateFormat('yyyyMMdd').format(_endDate)}';
      final elderSlug = widget.activeElder.profileName
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

      final Directory tempDir = await getTemporaryDirectory();

      // Shared metadata passed to ExportService
      final meta = ExportMeta(
        elderName: widget.activeElder.profileName,
        caregiverName: caregiverName,
        startDate: _startDate,
        endDate: _endDate,
        selectedTypes: _selectedTypes.toList(),
      );

      if (_format == _ExportFormat.csv) {
        final csv = _exportService.generateCsv(entries, meta: meta);
        final file = File(
            '${tempDir.path}/${elderSlug}_care_log_$rangeLabel.csv');
        await file.writeAsString(csv);
        if (mounted) {
          setState(() => _lastExportPath = file.path);
          await _shareFile(file.path, 'text/csv');
        }
      } else {
        final pdfBytes =
            await _exportService.generatePdf(entries, meta: meta);
        final file = File(
            '${tempDir.path}/${elderSlug}_care_report_$rangeLabel.pdf');
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

  void _toggleType(EntryType t) {
    setState(() {
      if (_selectedTypes.contains(t)) {
        _selectedTypes.remove(t);
      } else {
        _selectedTypes.add(t);
      }
      _lastExportPath = null;
    });
  }

  void _selectAll() => setState(() {
        _selectedTypes = Set.from(_kExportableTypes);
        _lastExportPath = null;
      });

  void _selectNone() => setState(() {
        _selectedTypes.clear();
        _lastExportPath = null;
      });

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tt = theme.textTheme;

    // Caregiver name for display in the screen header
    final caregiverName =
        Provider.of<UserProfileProvider>(context).userProfile?.displayName ??
            'Caregiver';

    return Scaffold(
      appBar: AppBar(title: const Text('Export care logs')),
      body: ListView(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // ── Report context card ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kExportColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: _kExportColor.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _ContextRow(
                  icon: Icons.person_outline,
                  label: 'Care recipient',
                  value: widget.activeElder.profileName,
                ),
                const SizedBox(height: 8),
                _ContextRow(
                  icon: Icons.badge_outlined,
                  label: 'Prepared by',
                  value: caregiverName,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: 'Date range'),
          const SizedBox(height: 10),

          // ── Date pickers ─────────────────────────────────────────
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 4,
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

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── Entry type filter ────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _SectionLabel(label: 'Include entry types'),
              Row(
                children: [
                  GestureDetector(
                    onTap: _selectAll,
                    child: Text('All',
                        style: TextStyle(
                            fontSize: 12,
                            color: _kExportColor,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 4),
                  Text('/',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary)),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: _selectNone,
                    child: Text('None',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kExportableTypes.map((type) {
              final isSelected = _selectedTypes.contains(type);
              return _TypeChip(
                label: _labelForType(type),
                icon: _iconForType(type),
                color: _colorForType(type),
                selected: isSelected,
                onTap: () => _toggleType(type),
              );
            }).toList(),
          ),

          // Selection summary
          const SizedBox(height: 8),
          Text(
            _selectedTypes.isEmpty
                ? 'No types selected — select at least one'
                : '${_selectedTypes.length} of ${_kExportableTypes.length} types selected',
            style: tt.bodySmall?.copyWith(
              color: _selectedTypes.isEmpty
                  ? AppTheme.dangerColor
                  : AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // ── Format picker ────────────────────────────────────────
          const _SectionLabel(label: 'Format'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FormatCard(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF Report',
                  description:
                      'Formatted, ready to share with a doctor',
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

          const SizedBox(height: 28),

          // ── Export button ────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (_isExporting || _selectedTypes.isEmpty)
                      ? null
                      : _handleExport,
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.textOnPrimary))
                  : const Icon(Icons.download_outlined),
              label: Text(_isExporting
                  ? 'Generating…'
                  : _format == _ExportFormat.pdf
                      ? 'Generate & share PDF'
                      : 'Generate & share CSV'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: _kExportColor,
                foregroundColor: AppTheme.textOnPrimary,
              ),
            ),
          ),

          // Re-share
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
                  foregroundColor: _kExportColor,
                  side: BorderSide(color: _kExportColor, width: 1.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Info note ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The exported report will include your name, '
                    'the care recipient\'s name, the date range, '
                    'and only the selected entry types.',
                    style: tt.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Type chip metadata helpers
  // ---------------------------------------------------------------------------

  String _labelForType(EntryType t) {
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
      case EntryType.caregiverJournal: return 'Journal';
      default: return t.name;
    }
  }

  IconData _iconForType(EntryType t) {
    switch (t) {
      case EntryType.medication: return Icons.medication_outlined;
      case EntryType.vital: return Icons.monitor_heart_outlined;
      case EntryType.mood: return Icons.sentiment_satisfied_outlined;
      case EntryType.sleep: return Icons.bedtime_outlined;
      case EntryType.meal: return Icons.restaurant_outlined;
      case EntryType.activity: return Icons.directions_walk_outlined;
      case EntryType.pain: return Icons.healing_outlined;
      case EntryType.expense: return Icons.receipt_long_outlined;
      case EntryType.message: return Icons.chat_bubble_outline;
      case EntryType.caregiverJournal: return Icons.menu_book_outlined;
      default: return Icons.note_outlined;
    }
  }

  Color _colorForType(EntryType t) {
    switch (t) {
      case EntryType.medication: return const Color(0xFF1E88E5);
      case EntryType.vital: return const Color(0xFFF57C00);
      case EntryType.mood: return const Color(0xFFE91E63);
      case EntryType.sleep: return const Color(0xFF5C6BC0);
      case EntryType.meal: return const Color(0xFF43A047);
      case EntryType.activity: return const Color(0xFF00897B);
      case EntryType.pain: return const Color(0xFFE53935);
      case EntryType.expense: return const Color(0xFF8E24AA);
      case EntryType.message: return const Color(0xFF546E7A);
      case EntryType.caregiverJournal: return const Color(0xFF546E7A);
      default: return AppTheme.textSecondary;
    }
  }
}

// ---------------------------------------------------------------------------
// ExportMeta — passed to ExportService for header generation
// ---------------------------------------------------------------------------

class ExportMeta {
  final String elderName;
  final String caregiverName;
  final DateTime startDate;
  final DateTime endDate;
  final List<EntryType> selectedTypes;

  const ExportMeta({
    required this.elderName,
    required this.caregiverName,
    required this.startDate,
    required this.endDate,
    required this.selectedTypes,
  });

  String get dateRangeDisplay =>
      '${DateFormat('MMM d, yyyy').format(startDate)} – '
      '${DateFormat('MMM d, yyyy').format(endDate)}';

  String get typesDisplay => selectedTypes
      .map((t) => t.name[0].toUpperCase() + t.name.substring(1))
      .join(', ');
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _kExportColor),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
              fontSize: 13, color: AppTheme.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withOpacity(0.6)
                : AppTheme.textLight.withOpacity(0.5),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? color : AppTheme.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: selected ? color : AppTheme.textSecondary,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

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
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: _kExportColor),
                const SizedBox(width: 6),
                Text(formatter.format(date),
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500)),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
              color: _kExportColor.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: _kExportColor,
                fontWeight: FontWeight.w500)),
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
              ? _kExportColor.withOpacity(0.06)
              : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _kExportColor
                : AppTheme.textLight.withOpacity(0.4),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 24,
                color: selected
                    ? _kExportColor
                    : AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? _kExportColor
                        : AppTheme.textPrimary)),
            const SizedBox(height: 4),
            Text(description,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
