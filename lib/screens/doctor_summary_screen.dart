// lib/screens/doctor_summary_screen.dart
//
// One-tap "Doctor Summary" screen — generates a last-7-days care PDF and
// opens the system share sheet. Preview shows entry counts and key highlights
// (latest vitals, peak pain, meds taken, sleep average) before sharing.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/screens/export_screen.dart' show ExportMeta;
import 'package:cecelia_care_flutter/services/export_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const _kColor = AppTheme.tileIndigo; // indigo — matches export screen

// Entry types meaningful for a doctor review. Excludes expense, message,
// caregiver journal, and image — those are internal caregiver tools.
const _kDoctorTypes = [
  EntryType.medication,
  EntryType.vital,
  EntryType.pain,
  EntryType.sleep,
  EntryType.mood,
  EntryType.meal,
  EntryType.activity,
  EntryType.handoff,
];

class DoctorSummaryScreen extends StatefulWidget {
  const DoctorSummaryScreen({super.key});

  @override
  State<DoctorSummaryScreen> createState() => _DoctorSummaryScreenState();
}

class _DoctorSummaryScreenState extends State<DoctorSummaryScreen> {
  bool _isGenerating = false;

  late final DateTime _endDate;
  late final DateTime _startDate;
  late final DateTime _endOfDay;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 7));
    _endOfDay = DateTime(
        _endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
  }

  Future<void> _generateAndShare(
    List<JournalEntry> entries,
    String elderName,
    String caregiverName,
  ) async {
    if (_isGenerating) return;
    setState(() => _isGenerating = true);
    try {
      final meta = ExportMeta(
        elderName: elderName,
        caregiverName: caregiverName,
        startDate: _startDate,
        endDate: _endDate,
        selectedTypes: _kDoctorTypes,
      );

      final pdfBytes =
          await ExportService().generatePdf(entries, meta: meta);

      final tempDir = await getTemporaryDirectory();
      final slug =
          elderName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final file =
          File('${tempDir.path}/Doctor_Summary_$slug.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Care Summary — $elderName — Last 7 Days',
      );

      HapticUtils.success();
    } catch (e) {
      debugPrint('DoctorSummaryScreen: error generating PDF: $e');
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

  @override
  Widget build(BuildContext context) {
    final activeElder =
        context.select<ActiveElderProvider, ElderProfile?>((p) => p.activeElder);
    final userProfile =
        context.select<UserProfileProvider, UserProfile?>((p) => p.userProfile);
    final currentUserId =
        FirebaseAuth.instance.currentUser?.uid;
    final journalProvider =
        context.read<JournalServiceProvider>();

    if (activeElder == null || currentUserId == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(
            child: Text('No active care recipient selected.')),
      );
    }

    final elderName = activeElder.profileName;
    final caregiverName =
        userProfile?.displayName ?? 'Caregiver';
    final dateFmt = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: _buildAppBar(),
      body: StreamBuilder<List<JournalEntry>>(
        stream: journalProvider.getJournalEntriesStream(
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

          final allEntries = snapshot.data ?? [];
          final entries = allEntries
              .where((e) => _kDoctorTypes.contains(e.type))
              .toList();

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header card ─────────────────────────────────────
                      _HeaderCard(
                        elderName: elderName,
                        startLabel: dateFmt.format(_startDate),
                        endLabel: dateFmt.format(_endDate),
                        preparedBy: caregiverName,
                      ),

                      const SizedBox(height: 20),

                      // ── Entry counts ────────────────────────────────────
                      _SectionHeader('Entry Summary'),
                      const SizedBox(height: 10),
                      _EntryCountChips(entries: entries),

                      const SizedBox(height: 24),

                      // ── Key highlights ──────────────────────────────────
                      if (entries.isNotEmpty) ...[
                        _SectionHeader('Key Highlights'),
                        const SizedBox(height: 10),
                        _KeyHighlights(entries: entries),
                        const SizedBox(height: 24),
                      ],

                      // ── Empty state ─────────────────────────────────────
                      if (entries.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 32),
                          child: Center(
                            child: Text(
                              'No care log entries for the last 7 days.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Share button ─────────────────────────────────────────────
              _ShareBar(
                isGenerating: _isGenerating,
                hasEntries: entries.isNotEmpty,
                onShare: () =>
                    _generateAndShare(entries, elderName, caregiverName),
              ),
            ],
          );
        },
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Doctor Summary'),
      backgroundColor: _kColor,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Header card
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.elderName,
    required this.startLabel,
    required this.endLabel,
    required this.preparedBy,
  });

  final String elderName;
  final String startLabel;
  final String endLabel;
  final String preparedBy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: const Icon(Icons.summarize_outlined,
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
                      'Last 7 Days: $startLabel – $endLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: _kColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetaRow(label: 'Prepared by', value: preparedBy),
          const SizedBox(height: 4),
          _MetaRow(
            label: 'Generated',
            value: DateFormat('MMM d, yyyy — h:mm a').format(DateTime.now()),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            '$label:',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _kColor.withValues(alpha: 0.6)),
          ),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Entry count chips
// ---------------------------------------------------------------------------

class _EntryCountChips extends StatelessWidget {
  const _EntryCountChips({required this.entries});
  final List<JournalEntry> entries;

  static const _typeLabels = {
    EntryType.medication: 'Meds',
    EntryType.vital: 'Vitals',
    EntryType.pain: 'Pain',
    EntryType.sleep: 'Sleep',
    EntryType.mood: 'Mood',
    EntryType.meal: 'Meals',
    EntryType.activity: 'Activity',
    EntryType.handoff: 'Handoffs',
  };

  static const _typeColors = {
    EntryType.medication: AppTheme.tileBlue,
    EntryType.vital: AppTheme.tileOrange,
    EntryType.pain: AppTheme.statusRed,
    EntryType.sleep: AppTheme.tileIndigo,
    EntryType.mood: AppTheme.tilePinkBright,
    EntryType.meal: AppTheme.statusGreen,
    EntryType.activity: AppTheme.tileTeal,
    EntryType.handoff: AppTheme.tileTeal,
  };

  @override
  Widget build(BuildContext context) {
    final counts = <EntryType, int>{};
    for (final e in entries) {
      counts[e.type] = (counts[e.type] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return Text(
        'No entries to summarise.',
        style: TextStyle(
            color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kDoctorTypes
          .where((t) => counts.containsKey(t))
          .map((t) {
        final count = counts[t]!;
        final color = _typeColors[t] ?? AppTheme.textSecondary;
        final label = _typeLabels[t] ?? t.name;
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            '$count $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Key highlights — auto-extracted from entry data
// ---------------------------------------------------------------------------

class _KeyHighlights extends StatelessWidget {
  const _KeyHighlights({required this.entries});
  final List<JournalEntry> entries;

  @override
  Widget build(BuildContext context) {
    final highlights = <_Highlight>[];

    // Latest vital readings
    final vitalEntries = entries.where((e) => e.type == EntryType.vital).toList()
      ..sort((a, b) =>
          b.entryTimestamp.compareTo(a.entryTimestamp));
    final Map<String, JournalEntry> latestVitals = {};
    for (final e in vitalEntries) {
      final vt = e.data?['vitalType'] as String? ?? '';
      if (vt.isNotEmpty) latestVitals.putIfAbsent(vt, () => e);
    }
    for (final entry in latestVitals.values) {
      final vt = entry.data?['vitalType'] as String? ?? 'Vital';
      final value = entry.data?['value'] as String? ?? '';
      final unit = entry.data?['unit'] as String? ?? '';
      if (value.isNotEmpty) {
        highlights.add(_Highlight(
          icon: Icons.monitor_heart_outlined,
          color: AppTheme.tileOrange,
          label: vt,
          value:
              unit.isNotEmpty ? '$value $unit' : value,
        ));
      }
    }

    // Highest pain score
    int? highestPain;
    String? painLocation;
    for (final e in entries.where((e) => e.type == EntryType.pain)) {
      final intensity = e.data?['intensity'];
      final i = intensity is int
          ? intensity
          : int.tryParse(intensity?.toString() ?? '');
      if (i != null && (highestPain == null || i > highestPain)) {
        highestPain = i;
        painLocation = e.data?['location'] as String?;
      }
    }
    if (highestPain != null) {
      highlights.add(_Highlight(
        icon: Icons.healing_outlined,
        color: AppTheme.statusRed,
        label: 'Peak pain${painLocation != null ? ' ($painLocation)' : ''}',
        value: '$highestPain / 10',
      ));
    }

    // Medications taken — unique names
    final medNames = <String>{};
    for (final e in entries.where((e) => e.type == EntryType.medication)) {
      final name = e.data?['name'] as String?;
      if (name != null && name.isNotEmpty) medNames.add(name);
    }
    if (medNames.isNotEmpty) {
      highlights.add(_Highlight(
        icon: Icons.medication_outlined,
        color: AppTheme.tileBlue,
        label: '${medNames.length} medication${medNames.length == 1 ? '' : 's'} logged',
        value: medNames.take(3).join(', ') +
            (medNames.length > 3 ? ' +${medNames.length - 3} more' : ''),
      ));
    }

    // Sleep average
    final sleepValues = entries
        .where((e) => e.type == EntryType.sleep)
        .map((e) => double.tryParse(
            (e.data?['totalDuration'] as String?)?.trim() ?? ''))
        .whereType<double>()
        .toList();
    if (sleepValues.isNotEmpty) {
      final avg =
          sleepValues.reduce((a, b) => a + b) / sleepValues.length;
      highlights.add(_Highlight(
        icon: Icons.bedtime_outlined,
        color: AppTheme.tileIndigo,
        label: 'Avg sleep (${sleepValues.length} night${sleepValues.length == 1 ? '' : 's'})',
        value: '${avg.toStringAsFixed(1)} hrs',
      ));
    }

    // Handoff count
    final handoffCount =
        entries.where((e) => e.type == EntryType.handoff).length;
    if (handoffCount > 0) {
      highlights.add(_Highlight(
        icon: Icons.swap_horiz_outlined,
        color: AppTheme.tileTeal,
        label: 'Shift handoffs',
        value: handoffCount.toString(),
      ));
    }

    if (highlights.isEmpty) {
      return Text(
        'No key data to highlight.',
        style: TextStyle(
            color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
      );
    }

    return Column(
      children: highlights
          .map((h) => _HighlightRow(highlight: h))
          .toList(),
    );
  }
}

class _Highlight {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _Highlight(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({required this.highlight});
  final _Highlight highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: highlight.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Icon(highlight.icon,
                size: 16, color: highlight.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              highlight.label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            highlight.value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
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

// ---------------------------------------------------------------------------
// Share bar — sticky at the bottom
// ---------------------------------------------------------------------------

class _ShareBar extends StatelessWidget {
  const _ShareBar({
    required this.isGenerating,
    required this.hasEntries,
    required this.onShare,
  });

  final bool isGenerating;
  final bool hasEntries;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
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
          isGenerating
              ? 'Generating PDF…'
              : 'Share PDF with Doctor',
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _kColor,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM)),
        ),
        onPressed: (isGenerating || !hasEntries) ? null : onShare,
      ),
    );
  }
}
