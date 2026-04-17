// lib/screens/music_therapy_screen.dart
//
// Music Therapy Reaction Tracker.
//
// NOT a player — a logging + pattern-detection tool. Caregivers capture
// song + reaction + context; the insights view surfaces which songs
// consistently calm, which agitate, and which decade of music resonates
// most for this person.
//
// Screen layout (top → bottom):
//   1. "What should I play?" suggestion card — shows the top-scoring
//      song for the current context (sundowning hour → sundowning
//      suggestion, otherwise general).
//   2. Quick-log FAB → modal with song / artist / decade / reaction /
//      context / notes.
//   3. Insights section — top helpful, top agitating, decade heatmap.
//   4. History list — every logged reaction, newest first, tap to edit.
//
// PDF export builds a "Music that works for <Name>" handoff sheet so
// visiting family / facility staff get the same intuition you spent
// months building.

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

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/music_reaction.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/ai_suggestion_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tilePurple;
const Color _kAccentDeep = Color(0xFF6A1B9A);

class MusicTherapyScreen extends StatelessWidget {
  const MusicTherapyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final elderProv = context.watch<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    final canLog = elderProv.currentUserRole.canLog;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Music & Reactions'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No care recipient selected.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final displayName = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Music & Reactions'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canLog
          ? FloatingActionButton.extended(
              backgroundColor: _kAccentDeep,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.music_note_outlined),
              label: const Text('Log reaction'),
              onPressed: () => _showLogSheet(context, elder, null),
            )
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context
            .read<FirestoreService>()
            .getMusicReactionsStream(elder.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final raw = snap.data ?? const <Map<String, dynamic>>[];
          final entries = raw
              .map((m) => MusicReactionEntry.fromFirestore(
                  m['id'] as String, m))
              .toList();

          if (entries.isEmpty) {
            return _EmptyState(
              canLog: canLog,
              onStart: () => _showLogSheet(context, elder, null),
            );
          }

          final insights = MusicInsights.compute(entries);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              _SuggestionCard(
                insights: insights,
                displayName: displayName,
              ),
              const SizedBox(height: 14),
              _ResearchNote(),
              const SizedBox(height: 14),
              if (insights.topHelpful.isNotEmpty) ...[
                _InsightsSection(
                  title: 'Top calming / engaging',
                  icon: Icons.favorite_outline,
                  accent: AppTheme.statusGreen,
                  insights: insights.topHelpful,
                ),
                const SizedBox(height: 14),
              ],
              if (insights.topAgitating.isNotEmpty) ...[
                _InsightsSection(
                  title: 'Avoid — triggers agitation',
                  icon: Icons.do_not_disturb_on_outlined,
                  accent: AppTheme.dangerColor,
                  insights: insights.topAgitating,
                ),
                const SizedBox(height: 14),
              ],
              if (insights.decadeBreakdown.isNotEmpty) ...[
                _DecadeHeatmapCard(insights: insights),
                const SizedBox(height: 14),
              ],
              _ContextCard(insights: insights),
              const SizedBox(height: 14),
              _HistorySection(
                entries: entries,
                canLog: canLog,
                onEdit: (e) => _showLogSheet(context, elder, e),
                onDelete: (e) async {
                  if (e.id == null) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete this entry?'),
                      content: Text(
                          'Remove "${e.displayTitle}" from $displayName\'s '
                          'music log. This can\'t be undone.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: TextButton.styleFrom(
                              foregroundColor: AppTheme.dangerColor),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true || !context.mounted) return;
                  try {
                    await context
                        .read<FirestoreService>()
                        .deleteMusicReaction(elder.id, e.id!);
                    if (context.mounted) HapticUtils.warning();
                  } catch (err) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not delete: $err')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    _sharePdf(context, elder, entries, insights),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text('Share "Music that works for $displayName"'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAccentDeep,
                  side: BorderSide(color: _kAccent.withValues(alpha: 0.4)),
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Log sheet launcher
  // ---------------------------------------------------------------------------

  Future<void> _showLogSheet(
    BuildContext context,
    ElderProfile elder,
    MusicReactionEntry? existing,
  ) async {
    HapticUtils.tap();
    final firestore = context.read<FirestoreService>();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final result = await showModalBottomSheet<MusicReactionEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _MusicLogSheet(
        elder: elder,
        uid: user.uid,
        displayName: user.displayName ?? '',
        existing: existing,
      ),
    );
    if (result == null || !context.mounted) return;

    try {
      if (existing?.id != null) {
        await firestore.updateMusicReaction(
          elder.id,
          existing!.id!,
          result.toFirestore(),
        );
      } else {
        await firestore.addMusicReaction(elder.id, result.toFirestore());
      }
      if (context.mounted) {
        HapticUtils.success();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Music reaction logged.'),
          backgroundColor: AppTheme.statusGreen,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  Future<void> _sharePdf(
    BuildContext context,
    ElderProfile elder,
    List<MusicReactionEntry> entries,
    MusicInsights insights,
  ) async {
    try {
      final bytes = await _buildPdf(elder, entries, insights);
      final dir = await getTemporaryDirectory();
      final safeName =
          (elder.preferredName?.isNotEmpty == true ? elder.preferredName! : elder.profileName)
              .replaceAll(RegExp(r'[^\w\s]'), '')
              .trim();
      final file = File(
          '${dir.path}/Music_That_Works_${safeName.isEmpty ? 'report' : safeName}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject:
            'Music that works for ${elder.preferredName ?? elder.profileName}',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('MusicTherapy PDF error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  Future<Uint8List> _buildPdf(
    ElderProfile elder,
    List<MusicReactionEntry> entries,
    MusicInsights insights,
  ) async {
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
              color: PdfColor.fromHex('#F3E5F5'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#7B1FA2'), width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MUSIC THAT WORKS FOR',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#4A148C'),
                    letterSpacing: 2.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  displayName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#6A1B9A'),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Based on ${insights.totalPlays} logged reactions through '
                  '$dateStamp. Share with visiting family or care staff so '
                  'they can reach for the songs that consistently help.',
                  style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          if (insights.topHelpful.isNotEmpty) ...[
            _pdfSectionHeader('CALMING / ENGAGING — PLAY THESE',
                color: PdfColors.green800),
            pw.SizedBox(height: 6),
            _pdfSongTable(insights.topHelpful),
            pw.SizedBox(height: 14),
          ],
          if (insights.topAgitating.isNotEmpty) ...[
            _pdfSectionHeader('AVOID — THESE HAVE AGITATED',
                color: PdfColors.red800),
            pw.SizedBox(height: 6),
            _pdfSongTable(insights.topAgitating),
            pw.SizedBox(height: 14),
          ],
          if (insights.bestDecade != null) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E8F5E9'),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'Strongest-resonating decade: ${insights.bestDecade}s. '
                'When picking new songs, start here.',
                style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.green900,
                    fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 14),
          ],
          _pdfSectionHeader('FULL REACTION HISTORY'),
          pw.SizedBox(height: 6),
          _pdfHistoryTable(entries),
          pw.SizedBox(height: 18),
          pw.Text(
            'Generated by Cecelia Care. Music reactions are a clinical '
            'documentation tool — approach 67% of people with dementia '
            'see reduced agitation with personalized music (Gerdner, 2013). '
            'These recommendations are specific to this person based on '
            'observed responses.',
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

  pw.Widget _pdfSectionHeader(String text,
      {PdfColor color = PdfColors.purple800}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: color,
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

  pw.Widget _pdfSongTable(List<SongInsight> songs) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3.2),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey50),
          children: ['Song', 'Plays', 'Dominant reaction']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        for (final s in songs)
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(s.displayTitle,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text('${s.plays}',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(s.dominant.label,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _pdfHistoryTable(List<MusicReactionEntry> entries) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.8),
        1: pw.FlexColumnWidth(3.2),
        2: pw.FlexColumnWidth(1.4),
        3: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration:
              const pw.BoxDecoration(color: PdfColors.blueGrey50),
          children: ['When', 'Song', 'Context', 'Reaction']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        for (final e in entries.take(60))
          pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(
                    e.createdAt == null
                        ? '—'
                        : DateFormat('MMM d — HH:mm')
                            .format(e.createdAt!.toDate()),
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(e.displayTitle,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(e.context.label,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Text(e.reaction.label,
                    style: const pw.TextStyle(fontSize: 9)),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canLog, required this.onStart});
  final bool canLog;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.music_note_outlined,
              size: 48, color: _kAccent.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(
            'No reactions logged yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kAccentDeep,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'About 67% of people with dementia show reduced agitation when '
            'familiar music is played — usually the songs they knew in '
            'their teens and twenties.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Log what\'s playing and what you see. Over time you\'ll learn '
            'which songs consistently help, which agitate, and which decade '
            'resonates most — knowledge that\'s irreplaceable when handing '
            'off to family or facility staff.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          if (canLog) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.add),
                label: const Text('Log first reaction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResearchNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, size: 15, color: _kAccentDeep),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Personalized music — songs the person knew in their teens '
              'and twenties — reduces agitation in about 67% of people '
              'with dementia. This log helps you find theirs.',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "What should I play right now?" card — computes from the insights
/// and current hour of day (so sundowning windows get sundowning-
/// specific suggestions).
class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.insights,
    required this.displayName,
  });

  final MusicInsights insights;
  final String displayName;

  MusicContext _contextForNow() {
    final hour = DateTime.now().hour;
    if (hour >= 15 && hour < 19) return MusicContext.sundowning;
    if (hour >= 20 || hour < 6) return MusicContext.bedtime;
    if ((hour >= 7 && hour < 9) ||
        (hour >= 12 && hour < 13) ||
        (hour >= 17 && hour < 19)) {
      return MusicContext.mealtime;
    }
    return MusicContext.general;
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = insights.topHelpful.isEmpty
        ? null
        : insights.topHelpful.first;
    final ctx = _contextForNow();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: _kAccentDeep, size: 20),
              const SizedBox(width: 8),
              Text(
                'TRY THIS NOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kAccentDeep,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                ),
                child: Text(
                  ctx.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kAccentDeep,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (suggestion == null)
            Text(
              'Log a few reactions first and $displayName\'s personal '
              'playlist will start to surface here.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                height: 1.45,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.displayTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final r in suggestion.counts.keys)
                      _ReactionChipReadOnly(
                        reaction: r,
                        count: suggestion.counts[r] ?? 0,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${suggestion.plays} times played · '
                  '${suggestion.counts[MusicReaction.calmed] != null ||
                          suggestion.counts[MusicReaction.engaged] != null ||
                          suggestion.counts[MusicReaction.sangAlong] != null
                      ? 'consistently ${suggestion.dominant.label.toLowerCase()}'
                      : 'mixed reactions'}',
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReactionChipReadOnly extends StatelessWidget {
  const _ReactionChipReadOnly(
      {required this.reaction, required this.count});
  final MusicReaction reaction;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: reaction.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(reaction.icon, size: 11, color: reaction.color),
          const SizedBox(width: 4),
          Text(
            '${reaction.label} · $count',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: reaction.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({
    required this.title,
    required this.icon,
    required this.accent,
    required this.insights,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final List<SongInsight> insights;

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
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < insights.length; i++)
            _InsightRow(rank: i + 1, insight: insights[i]),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.rank, required this.insight});
  final int rank;
  final SongInsight insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _kAccentDeep,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.displayTitle,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: [
                    for (final entry in insight.counts.entries)
                      if (entry.value > 0)
                        _ReactionChipReadOnly(
                          reaction: entry.key,
                          count: entry.value,
                        ),
                  ],
                ),
              ],
            ),
          ),
          Text('${insight.plays}×',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _DecadeHeatmapCard extends StatelessWidget {
  const _DecadeHeatmapCard({required this.insights});
  final MusicInsights insights;

  @override
  Widget build(BuildContext context) {
    final decades = insights.decadeBreakdown.keys.toList()..sort();
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
              Icon(Icons.timeline, size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'DECADES THAT RESONATE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kAccentDeep,
                ),
              ),
              const Spacer(),
              if (insights.bestDecade != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.statusGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  ),
                  child: Text(
                    'Best: ${insights.bestDecade}s',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.statusGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final d in decades)
            _DecadeRow(
              decade: d,
              breakdown: insights.decadeBreakdown[d]!,
            ),
        ],
      ),
    );
  }
}

class _DecadeRow extends StatelessWidget {
  const _DecadeRow({required this.decade, required this.breakdown});
  final int decade;
  final Map<MusicReaction, int> breakdown;

  @override
  Widget build(BuildContext context) {
    final total =
        breakdown.values.fold<int>(0, (a, b) => a + b).clamp(1, 9999);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              '${decade}s',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                height: 10,
                color: AppTheme.backgroundGray,
                child: Row(
                  children: [
                    for (final r in MusicReaction.values)
                      if ((breakdown[r] ?? 0) > 0)
                        Expanded(
                          flex: breakdown[r]!,
                          child: Container(color: r.color),
                        ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              '$total',
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.insights});
  final MusicInsights insights;

  @override
  Widget build(BuildContext context) {
    if (insights.contextAverages.length <= 1) return const SizedBox.shrink();

    final sorted = insights.contextAverages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
              Icon(Icons.event_outlined, size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'WHEN MUSIC HELPS MOST',
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
          for (final e in sorted)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      e.key.label,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: _ContextBar(avg: e.value),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      e.value >= 0
                          ? '+${e.value.toStringAsFixed(1)}'
                          : e.value.toStringAsFixed(1),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: e.value >= 0
                            ? AppTheme.statusGreen
                            : AppTheme.dangerColor,
                      ),
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

class _ContextBar extends StatelessWidget {
  const _ContextBar({required this.avg});
  final double avg;

  @override
  Widget build(BuildContext context) {
    // Range: -2 to +2 — the reaction score weights extremes.
    final ratio = (avg / 2).clamp(-1.0, 1.0);
    final absRatio = ratio.abs();
    final color = ratio >= 0
        ? AppTheme.statusGreen
        : AppTheme.dangerColor;
    return LayoutBuilder(builder: (ctx, c) {
      final center = c.maxWidth / 2;
      final barWidth = center * absRatio;
      return Stack(
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Positioned(
            left: ratio < 0 ? center - barWidth : center,
            child: Container(
              width: barWidth,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            left: center - 0.5,
            top: -1,
            child: Container(
              width: 1,
              height: 10,
              color: AppTheme.textLight,
            ),
          ),
        ],
      );
    });
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.entries,
    required this.canLog,
    required this.onEdit,
    required this.onDelete,
  });

  final List<MusicReactionEntry> entries;
  final bool canLog;
  final void Function(MusicReactionEntry) onEdit;
  final void Function(MusicReactionEntry) onDelete;

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
              Icon(Icons.history_outlined, size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'RECENT REACTIONS (${entries.length})',
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
          for (final e in entries.take(50))
            _HistoryRow(
              entry: e,
              canLog: canLog,
              onEdit: () => onEdit(e),
              onDelete: () => onDelete(e),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    required this.canLog,
    required this.onEdit,
    required this.onDelete,
  });

  final MusicReactionEntry entry;
  final bool canLog;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final at = entry.createdAt?.toDate();
    return InkWell(
      onTap: canLog ? onEdit : null,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: entry.reaction.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(entry.reaction.icon,
                  size: 18, color: entry.reaction.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.displayTitle,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (at != null)
                        DateFormat('MMM d, HH:mm').format(at),
                      entry.reaction.label,
                      if (entry.decade != null) '${entry.decade}s',
                      if (entry.context != MusicContext.general)
                        entry.context.label,
                    ].join(' · '),
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary),
                  ),
                  if (entry.notes != null && entry.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        entry.notes!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                            height: 1.35),
                      ),
                    ),
                ],
              ),
            ),
            if (canLog)
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.close,
                    size: 16, color: AppTheme.textLight),
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log sheet
// ---------------------------------------------------------------------------

class _MusicLogSheet extends StatefulWidget {
  const _MusicLogSheet({
    required this.elder,
    required this.uid,
    required this.displayName,
    this.existing,
  });

  final ElderProfile elder;
  final String uid;
  final String displayName;
  final MusicReactionEntry? existing;

  @override
  State<_MusicLogSheet> createState() => _MusicLogSheetState();
}

class _MusicLogSheetState extends State<_MusicLogSheet> {
  late final TextEditingController _songCtrl;
  late final TextEditingController _artistCtrl;
  late final TextEditingController _notesCtrl;
  int? _decade;
  MusicReaction? _reaction;
  MusicContext _context = MusicContext.general;
  bool _submitting = false;
  bool _aiBusy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _songCtrl = TextEditingController(text: e?.song ?? '');
    _artistCtrl = TextEditingController(text: e?.artist ?? '');
    _notesCtrl = TextEditingController(text: e?.notes ?? '');
    _decade = e?.decade ?? _guessDecadeFromElder();
    _reaction = e?.reaction;
    _context = e?.context ?? MusicContext.general;
  }

  int? _guessDecadeFromElder() {
    // Autobiographical peak for personalized-music research is roughly
    // age 15–25. Use the care recipient's DOB (if set) to pre-select
    // the decade that covers their peak.
    final dob = widget.elder.dateOfBirth;
    if (dob.isEmpty) return null;
    final match = RegExp(r'(\d{4})').firstMatch(dob);
    if (match == null) return null;
    final yob = int.tryParse(match.group(1)!);
    if (yob == null) return null;
    final peak = yob + 20; // mid of teen-to-twenties window
    final decadeStart = (peak ~/ 10) * 10;
    // Clamp to known presets.
    if (decadeStart < 1930) return 1930;
    if (decadeStart > 2020) return 2020;
    return decadeStart;
  }

  @override
  void dispose() {
    _songCtrl.dispose();
    _artistCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final song = _songCtrl.text.trim();
    final reaction = _reaction;
    if (song.isEmpty || reaction == null) {
      HapticUtils.warning();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a song name and pick a reaction.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    setState(() => _submitting = true);

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final entry = MusicReactionEntry(
      id: widget.existing?.id,
      elderId: widget.elder.id,
      song: song,
      artist:
          _artistCtrl.text.trim().isEmpty ? null : _artistCtrl.text.trim(),
      decade: _decade,
      reaction: reaction,
      context: _context,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      timeOfDay: widget.existing?.timeOfDay ?? timeStr,
      loggedByUid: widget.uid,
      loggedByName: widget.displayName,
    );

    Navigator.of(context).pop(entry);
  }

  Future<void> _askAi() async {
    if (_aiBusy) return;
    setState(() => _aiBusy = true);
    final displayName = widget.elder.preferredName?.isNotEmpty == true
        ? widget.elder.preferredName!
        : widget.elder.profileName;
    final result = await AiSuggestionService.instance.suggestMusicPattern(
      elderId: widget.elder.id,
      elderDisplayName: displayName,
      context: {
        'song': _songCtrl.text.trim(),
        'artist': _artistCtrl.text.trim(),
        'decade': _decade,
        'dob': widget.elder.dateOfBirth,
      },
    );
    if (!mounted) return;
    setState(() => _aiBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result.errorMessage ??
            (result.suggestion ?? 'No suggestion available yet.'),
      ),
      backgroundColor: result.available
          ? AppTheme.statusGreen
          : AppTheme.tileIndigoDark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                child: Row(
                  children: [
                    Icon(Icons.music_note_outlined,
                        color: _kAccentDeep, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit reaction' : 'Log music reaction',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _AiStubChip(onTap: _askAi, busy: _aiBusy),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _SheetLabel('Song title'),
                    TextField(
                      controller: _songCtrl,
                      autofocus: !isEditing,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g., "Unforgettable"',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    _SheetLabel('Artist (optional)'),
                    TextField(
                      controller: _artistCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        hintText: 'e.g., Nat King Cole',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    _SheetLabel('Decade'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('Not sure',
                              style: TextStyle(fontSize: 12)),
                          selected: _decade == null,
                          onSelected: (_) => setState(() => _decade = null),
                        ),
                        for (final d in MusicDecade.presets)
                          ChoiceChip(
                            label: Text(d.label,
                                style: const TextStyle(fontSize: 12)),
                            selected: _decade == d.startYear,
                            onSelected: (_) =>
                                setState(() => _decade = d.startYear),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SheetLabel('Reaction *'),
                    const SizedBox(height: 4),
                    for (final r in MusicReaction.values)
                      _ReactionOption(
                        reaction: r,
                        selected: _reaction == r,
                        onTap: () => setState(() => _reaction = r),
                      ),
                    const SizedBox(height: 14),
                    _SheetLabel('Context'),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final c in MusicContext.values)
                          ChoiceChip(
                            label: Text(c.label,
                                style: const TextStyle(fontSize: 12)),
                            selected: _context == c,
                            onSelected: (_) =>
                                setState(() => _context = c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SheetLabel('Notes (optional)'),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      minLines: 2,
                      decoration: const InputDecoration(
                        hintText:
                            'What happened? Did they remember anything? How long did the effect last?',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: _submitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: Text(isEditing ? 'Save changes' : 'Save reaction',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccentDeep,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusM)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _ReactionOption extends StatelessWidget {
  const _ReactionOption({
    required this.reaction,
    required this.selected,
    required this.onTap,
  });

  final MusicReaction reaction;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected
              ? reaction.color.withValues(alpha: 0.1)
              : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: selected ? reaction.color : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: reaction.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(reaction.icon, color: reaction.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reaction.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? reaction.color
                          : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    reaction.prompt,
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                        height: 1.35),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: reaction.color, size: 22),
          ],
        ),
      ),
    );
  }
}

class _AiStubChip extends StatelessWidget {
  const _AiStubChip({required this.onTap, required this.busy});
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final available = AiSuggestionService.instance.isAvailable;
    return Tooltip(
      message: available
          ? 'Ask AI for a pattern insight'
          : 'AI pattern insights are coming soon',
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
