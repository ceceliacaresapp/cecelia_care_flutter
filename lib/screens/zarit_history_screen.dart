// lib/screens/zarit_history_screen.dart
//
// Zarit Burden trend view.
//
// Layout:
//   1. Latest-score hero card with burden level + guidance text.
//   2. Sparkline-style trend chart (CustomPainter) showing last 24
//      assessments; bands shaded by burden level so social workers
//      can instantly see the trajectory.
//   3. Per-assessment history list with tap-to-view details + delete.
//   4. "Share for social worker" PDF button.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/zarit_assessment.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/zarit_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/utils/page_transitions.dart';

import 'zarit_assessment_screen.dart';

const Color _kAccent = AppTheme.tilePurple;

class ZaritHistoryScreen extends StatelessWidget {
  const ZaritHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ZaritProvider>();
    final elderProv = context.watch<ActiveElderProvider>();
    final elder = elderProv.activeElder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Burden History'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          if (prov.hasHistory)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Share as PDF',
              onPressed: () => _sharePdf(context, prov, elder),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.favorite_outline),
        label: Text(prov.hasHistory ? 'New check-in' : 'Take assessment'),
        onPressed: () {
          HapticUtils.tap();
          Navigator.of(context).push(
            FadeSlideRoute(page: const ZaritAssessmentScreen()),
          );
        },
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !prov.hasHistory
              ? const _EmptyState()
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    _LatestCard(assessment: prov.latest!),
                    const SizedBox(height: 14),
                    if (prov.history.length >= 2) ...[
                      _TrendChartCard(points: prov.trendPoints),
                      const SizedBox(height: 14),
                    ],
                    _HistorySection(
                      history: prov.history,
                      onDelete: (id) async {
                        final confirm = await _confirmDelete(context);
                        if (confirm != true) return;
                        await prov.deleteAssessment(id);
                      },
                    ),
                    const SizedBox(height: 14),
                    _Footer(),
                  ],
                ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this check-in?'),
        content: const Text(
            'This single assessment will be removed from your history. '
            'This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf(
      BuildContext context, ZaritProvider prov, dynamic elder) async {
    try {
      final bytes = await _buildPdf(prov, elder);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Zarit_Burden_Report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Caregiver Burden Report (ZBI-12)',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('Zarit PDF error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  Future<Uint8List> _buildPdf(ZaritProvider prov, dynamic elder) async {
    final pdf = pw.Document();
    final latest = prov.latest!;
    final dateStamp = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final completed = latest.completedAt?.toDate();
    final completedStamp = completed != null
        ? DateFormat('MMMM d, yyyy').format(completed)
        : dateStamp;
    final elderName = elder == null
        ? null
        : (elder.preferredName?.isNotEmpty == true
            ? elder.preferredName as String
            : elder.profileName as String);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          // Cover
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
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
                  'CAREGIVER BURDEN REPORT',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#4A148C'),
                    letterSpacing: 2.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Zarit Burden Interview — Short Form (ZBI-12)',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#6A1B9A'),
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfMeta('Assessment completed', completedStamp),
                if (elderName != null) _pdfMeta('Care context', elderName),
                _pdfMeta(
                  'Total score',
                  '${latest.total} / 48  —  ${latest.level.label}',
                ),
                _pdfMeta('Personal strain subscale',
                    '${latest.personalStrain} / 24'),
                _pdfMeta(
                    'Role strain subscale', '${latest.roleStrain} / 24'),
                _pdfMeta('Report generated', dateStamp),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFF3E0'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#F57C00'), width: 0.5),
            ),
            child: pw.Text(
              'INTERPRETATION: ${latest.level.label}',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#E65100'),
                letterSpacing: 0.6,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            latest.level.guidance,
            style: const pw.TextStyle(fontSize: 10.5, lineSpacing: 3),
          ),
          pw.SizedBox(height: 18),

          // Item-by-item breakdown
          pw.Text('ITEM RESPONSES',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.4)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.5),
              1: pw.FlexColumnWidth(5.5),
              2: pw.FlexColumnWidth(1.2),
              3: pw.FlexColumnWidth(1.6),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: ['#', 'Item', 'Score', 'Response']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              for (int i = 0; i < kZaritItems.length; i++)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${i + 1}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(kZaritItems[i].prompt,
                          style: const pw.TextStyle(
                              fontSize: 9, lineSpacing: 2)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${latest.itemScores[i]}',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        ZaritResponseX.fromScore(latest.itemScores[i]).label,
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (latest.note != null && latest.note!.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Text('CAREGIVER NOTE',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.4)),
            pw.SizedBox(height: 4),
            pw.Text(latest.note!,
                style: const pw.TextStyle(fontSize: 10, lineSpacing: 3)),
          ],
          if (prov.history.length >= 2) ...[
            pw.SizedBox(height: 16),
            pw.Text('HISTORICAL TRAJECTORY',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.4)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1.2),
                2: pw.FlexColumnWidth(2.5),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: ['Date', 'Total', 'Level']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold)),
                          ))
                      .toList(),
                ),
                for (final a in prov.history)
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                          a.completedAt == null
                              ? '—'
                              : DateFormat('MMM d, yyyy')
                                  .format(a.completedAt!.toDate()),
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${a.total} / 48',
                            style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(a.level.label,
                            style: const pw.TextStyle(fontSize: 9)),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          pw.SizedBox(height: 18),
          pw.Text(
            'Scoring bands (Bédard et al., 2001): 0–10 little or no, '
            '11–20 mild–moderate, 21–40 moderate–severe, 41–48 severe. '
            'This report is self-administered by the caregiver and is '
            'intended to support — not replace — clinical assessment.',
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

  pw.Widget _pdfMeta(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text('$label:',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey700)),
          ),
          pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections / widgets
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.favorite_outline,
              size: 48, color: _kAccent.withValues(alpha: 0.55)),
          const SizedBox(height: 14),
          Text(
            'No burden check-ins yet.',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kAccent),
          ),
          const SizedBox(height: 8),
          const Text(
            'The Zarit Burden Interview (ZBI-12) is the gold-standard '
            'measure of caregiver strain — the one social workers and '
            'insurance companies recognize when approving respite support. '
            'Taking it monthly gives you a real trajectory to advocate with.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            '12 questions. About 3 minutes.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  const _LatestCard({required this.assessment});
  final ZaritAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final lvl = assessment.level;
    final completed = assessment.completedAt?.toDate();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lvl.color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: lvl.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: lvl.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.favorite, color: lvl.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${assessment.total} / 48',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: lvl.color,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lvl.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: lvl.color,
                      ),
                    ),
                    if (completed != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          'Completed ${DateFormat('MMMM d, yyyy').format(completed)}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lvl.guidance,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  const _TrendChartCard({required this.points});
  final List<({DateTime at, int total})> points;

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
              Icon(Icons.show_chart, size: 18, color: _kAccent),
              const SizedBox(width: 8),
              Text(
                'TREND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text('${points.length} check-ins',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _ZaritTrendPainter(points: points),
              child: Container(),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendSwatch(AppTheme.statusGreen, 'Little / none'),
              _legendSwatch(const Color(0xFFF9A825), 'Mild'),
              _legendSwatch(AppTheme.statusAmber, 'Moderate–severe'),
              _legendSwatch(AppTheme.dangerColor, 'Severe'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendSwatch(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _ZaritTrendPainter extends CustomPainter {
  _ZaritTrendPainter({required this.points});
  final List<({DateTime at, int total})> points;

  @override
  void paint(Canvas canvas, Size size) {
    // Paint burden-level bands across the full height.
    final band1 = Paint()
      ..color = AppTheme.statusGreen.withValues(alpha: 0.10);
    final band2 = Paint()
      ..color = const Color(0xFFF9A825).withValues(alpha: 0.10);
    final band3 = Paint()
      ..color = AppTheme.statusAmber.withValues(alpha: 0.10);
    final band4 = Paint()
      ..color = AppTheme.dangerColor.withValues(alpha: 0.10);

    double yFor(int total) => size.height * (1 - (total / 48));

    canvas.drawRect(
        Rect.fromLTRB(0, yFor(10), size.width, size.height), band1);
    canvas.drawRect(Rect.fromLTRB(0, yFor(20), size.width, yFor(10)), band2);
    canvas.drawRect(Rect.fromLTRB(0, yFor(40), size.width, yFor(20)), band3);
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, yFor(40)), band4);

    if (points.isEmpty) return;

    // Scatter x axis by index (equal spacing) — date-exact spacing would
    // compress clusters and stretch gaps unreadably for monthly data.
    final n = points.length;
    double xFor(int i) => n == 1 ? size.width / 2 : size.width * (i / (n - 1));

    // Line path
    final line = Path();
    for (int i = 0; i < n; i++) {
      final x = xFor(i);
      final y = yFor(points[i].total);
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = _kAccent
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Dots
    for (int i = 0; i < n; i++) {
      final p = points[i];
      final cx = xFor(i);
      final cy = yFor(p.total);
      final color = ZaritBurdenLevelX.fromTotal(p.total).color;
      canvas.drawCircle(Offset(cx, cy), 5, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(cx, cy), 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _ZaritTrendPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history, required this.onDelete});
  final List<ZaritAssessment> history;
  final void Function(String id) onDelete;

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
          Text(
            'ALL CHECK-INS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          for (final a in history)
            _HistoryRow(
              assessment: a,
              onDelete: a.id == null ? null : () => onDelete(a.id!),
            ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.assessment, this.onDelete});
  final ZaritAssessment assessment;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final lvl = assessment.level;
    final at = assessment.completedAt?.toDate();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: lvl.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: Text(
              '${assessment.total}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: lvl.color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  at == null
                      ? 'Pending'
                      : DateFormat('MMMM d, yyyy').format(at),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  lvl.label,
                  style: TextStyle(
                      fontSize: 11.5, color: lvl.color),
                ),
                if (assessment.note != null && assessment.note!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      assessment.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline,
                  size: 18, color: AppTheme.dangerColor),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: const Text(
        'Based on the Zarit Burden Interview Short Form (ZBI-12; '
        'Bédard et al., 2001). This is a self-report screening tool, '
        'not a clinical diagnosis. Share the PDF with a social worker, '
        'primary care doctor, or case manager for support conversations.',
        style: TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: AppTheme.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}
