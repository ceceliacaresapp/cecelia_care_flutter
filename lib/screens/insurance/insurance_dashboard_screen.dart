// lib/screens/insurance/insurance_dashboard_screen.dart
//
// Insurance & Benefits Tracker — the family's single pane for all
// claims, policies, benefit counters, denial/appeal paperwork, and
// YTD spend analytics. Extends the existing budget screen's
// out-of-pocket math with first-class claim tracking.
//
// This file bundles the dashboard + the three editor bottom sheets
// (policy, claim, benefit counter) since they share styling +
// callbacks. The PDF builder is in here too for the same reason.
//
// Data-ownership model: all three collections are per-user (owner
// scoped via rules) so caregivers don't accidentally expose claim
// data to view-only family members.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cecelia_care_flutter/models/insurance_claim.dart';
import 'package:cecelia_care_flutter/models/insurance_policy.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/ai_suggestion_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tileBlueDark;
const Color _kAccentDeep = Color(0xFF0D3366);
final NumberFormat _money = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
final NumberFormat _moneyRound =
    NumberFormat.currency(symbol: '\$', decimalDigits: 0);

class InsuranceDashboardScreen extends StatefulWidget {
  const InsuranceDashboardScreen({super.key});

  @override
  State<InsuranceDashboardScreen> createState() =>
      _InsuranceDashboardScreenState();
}

class _InsuranceDashboardScreenState extends State<InsuranceDashboardScreen> {
  ClaimStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;
    final user = FirebaseAuth.instance.currentUser;

    if (elder == null || user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Insurance & Benefits'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No care recipient selected.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final firestore = context.watch<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance & Benefits'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Share claims ledger PDF',
            onPressed: () => _sharePdf(firestore, user.uid, elder.id),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccentDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log claim'),
        onPressed: () async {
          final policies = await firestore
              .getInsurancePoliciesStream(
                userId: user.uid,
                careRecipientId: elder.id,
              )
              .first;
          if (!context.mounted) return;
          await _showClaimEditor(
            context,
            uid: user.uid,
            elderId: elder.id,
            policies: policies,
            existing: null,
          );
        },
      ),
      body: StreamBuilder<List<InsurancePolicy>>(
        stream: firestore.getInsurancePoliciesStream(
          userId: user.uid,
          careRecipientId: elder.id,
        ),
        builder: (context, policySnap) {
          return StreamBuilder<List<InsuranceClaim>>(
            stream: firestore.getInsuranceClaimsStream(
              userId: user.uid,
              careRecipientId: elder.id,
            ),
            builder: (context, claimSnap) {
              if (policySnap.connectionState == ConnectionState.waiting &&
                  !policySnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final policies = policySnap.data ?? const <InsurancePolicy>[];
              final claims = claimSnap.data ?? const <InsuranceClaim>[];

              if (policies.isEmpty && claims.isEmpty) {
                return _EmptyState(
                  onAddPolicy: () => _showPolicyEditor(
                    context,
                    uid: user.uid,
                    elderId: elder.id,
                    existing: null,
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _YtdStatsRow(claims: claims),
                  const SizedBox(height: 14),
                  _AlertsCard(claims: claims, policies: policies),
                  const SizedBox(height: 14),
                  _PoliciesSection(
                    policies: policies,
                    uid: user.uid,
                    elderId: elder.id,
                    onAdd: () => _showPolicyEditor(
                      context,
                      uid: user.uid,
                      elderId: elder.id,
                      existing: null,
                    ),
                    onEdit: (p) => _showPolicyEditor(
                      context,
                      uid: user.uid,
                      elderId: elder.id,
                      existing: p,
                    ),
                    onAddCounter: (p) => _showCounterEditor(
                      context,
                      uid: user.uid,
                      policy: p,
                      existing: null,
                    ),
                    onEditCounter: (p, c) => _showCounterEditor(
                      context,
                      uid: user.uid,
                      policy: p,
                      existing: c,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ClaimsSection(
                    claims: claims,
                    policies: policies,
                    filter: _statusFilter,
                    onFilterChange: (f) => setState(() => _statusFilter = f),
                    onTap: (c) => _showClaimEditor(
                      context,
                      uid: user.uid,
                      elderId: elder.id,
                      policies: policies,
                      existing: c,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _CoverageInsightCard(
                    claims: claims,
                    policies: policies,
                    elderName: elder.profileName,
                    elderId: elder.id,
                  ),
                  const SizedBox(height: 14),
                  _DisclaimerFooter(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF
  // ---------------------------------------------------------------------------

  Future<void> _sharePdf(
      FirestoreService firestore, String uid, String elderId) async {
    // Capture the elder BEFORE any awaits — reading from context after
    // an async gap trips the analyzer and risks a torn-down tree.
    final elder = context.read<ActiveElderProvider>().activeElder;
    try {
      final policies = await firestore
          .getInsurancePoliciesStream(
            userId: uid,
            careRecipientId: elderId,
          )
          .first;
      final claims = await firestore
          .getInsuranceClaimsStream(
            userId: uid,
            careRecipientId: elderId,
          )
          .first;
      final bytes = await _buildPdf(
        elderName: elder?.profileName ?? 'Care recipient',
        policies: policies,
        claims: claims,
      );
      final dir = await getTemporaryDirectory();
      final safe = (elder?.profileName ?? 'ledger')
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .trim();
      final file = File(
          '${dir.path}/Insurance_Claims_${safe.isEmpty ? 'ledger' : safe}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Insurance claims ledger',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('Insurance PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  Future<Uint8List> _buildPdf({
    required String elderName,
    required List<InsurancePolicy> policies,
    required List<InsuranceClaim> claims,
  }) async {
    final pdf = pw.Document();
    final dateStamp = DateFormat('MMMM d, yyyy').format(DateTime.now());
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final ytd = claims.where((c) => !c.dateOfService.isBefore(yearStart));
    final totalBilled =
        ytd.fold<double>(0, (a, c) => a + c.billedAmount);
    final totalPaid =
        ytd.fold<double>(0, (a, c) => a + c.insurancePaid);
    final totalOwed =
        ytd.fold<double>(0, (a, c) => a + c.patientResponsibility);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#E3F2FD'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#1565C0'), width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'INSURANCE CLAIMS LEDGER',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0D3366'),
                    letterSpacing: 2.5,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  elderName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#0D3366'),
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfMeta('Generated', dateStamp),
                _pdfMeta('YTD claims', '${ytd.length}'),
                _pdfMeta('YTD billed', _money.format(totalBilled)),
                _pdfMeta('YTD insurance paid', _money.format(totalPaid)),
                _pdfMeta('YTD patient responsibility',
                    _money.format(totalOwed)),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          if (policies.isNotEmpty) ...[
            _pdfSectionHeader('ACTIVE POLICIES'),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.6),
                1: pw.FlexColumnWidth(1.8),
                2: pw.FlexColumnWidth(1.4),
                3: pw.FlexColumnWidth(1.6),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: ['Plan', 'Member', 'Type', 'Active thru']
                      .map((h) => pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(h,
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold)),
                          ))
                      .toList(),
                ),
                for (final p in policies)
                  pw.TableRow(
                    children: [
                      _pdfCell('${p.carrier} — ${p.planName}'),
                      _pdfCell(p.memberId ?? '—'),
                      _pdfCell(p.planType.label),
                      _pdfCell(p.endDate == null
                          ? 'Open-ended'
                          : DateFormat('MMM d, yyyy').format(p.endDate!)),
                    ],
                  ),
              ],
            ),
            pw.SizedBox(height: 14),
          ],
          _pdfSectionHeader('CLAIMS — NEWEST FIRST'),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(1.4),
              1: pw.FlexColumnWidth(2.4),
              2: pw.FlexColumnWidth(1.3),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(1.3),
              5: pw.FlexColumnWidth(1.3),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: [
                  'Date',
                  'Provider / service',
                  'Billed',
                  'Paid',
                  'Owed',
                  'Status',
                ]
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              for (final c in claims.take(100))
                pw.TableRow(
                  children: [
                    _pdfCell(DateFormat('MMM d').format(c.dateOfService)),
                    _pdfCell('${c.provider}\n${c.serviceDescription}'),
                    _pdfCell(_money.format(c.billedAmount)),
                    _pdfCell(_money.format(c.insurancePaid)),
                    _pdfCell(_money.format(c.patientResponsibility)),
                    _pdfCell(c.status.label),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 14),
          if (claims.any((c) =>
              c.status == ClaimStatus.denied ||
              c.status == ClaimStatus.appealed)) ...[
            _pdfSectionHeader('DENIALS & APPEALS'),
            pw.SizedBox(height: 6),
            for (final c in claims.where((c) =>
                c.status == ClaimStatus.denied ||
                c.status == ClaimStatus.appealed))
              pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFEBEE'),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      '${DateFormat('MMM d, yyyy').format(c.dateOfService)}'
                      ' — ${c.provider}',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Denial reason: ${c.appeal.denialReason.isEmpty ? "—" : c.appeal.denialReason}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    if (c.appeal.appealDeadline != null)
                      pw.Text(
                        'Appeal deadline: '
                        '${DateFormat('MMM d, yyyy').format(c.appeal.appealDeadline!)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    pw.Text(
                      'Outcome: ${c.appeal.outcome.label}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
          ],
          pw.SizedBox(height: 14),
          pw.Text(
            'Generated by Cecelia Care. This report is a caregiver-curated '
            'record; it does not replace Explanation-of-Benefits statements '
            'from the carrier. Keep original EOBs for tax deduction '
            'substantiation — only expenses exceeding 7.5% of AGI qualify '
            'under the IRS medical deduction.',
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

  pw.Widget _pdfSectionHeader(String text) => pw.Container(
        width: double.infinity,
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#1565C0'),
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

  pw.Widget _pdfMeta(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 170,
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

  pw.Widget _pdfCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(5),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddPolicy});
  final VoidCallback onAddPolicy;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.health_and_safety_outlined,
              size: 48, color: _kAccent.withValues(alpha: 0.6)),
          const SizedBox(height: 14),
          Text(
            'Stop losing money to untracked claims.',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _kAccentDeep,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add your first insurance policy, then log claims as they come '
            'in. The dashboard automatically tracks what was billed, what '
            'was paid, what\'s still owed, and flags denials that need an '
            'appeal.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddPolicy,
              icon: const Icon(Icons.add),
              label: const Text('Add first policy'),
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
    );
  }
}

// ---------------------------------------------------------------------------
// YTD stats
// ---------------------------------------------------------------------------

class _YtdStatsRow extends StatelessWidget {
  const _YtdStatsRow({required this.claims});
  final List<InsuranceClaim> claims;

  @override
  Widget build(BuildContext context) {
    final yearStart = DateTime(DateTime.now().year, 1, 1);
    final ytd = claims.where((c) => !c.dateOfService.isBefore(yearStart));
    final billed = ytd.fold<double>(0, (a, c) => a + c.billedAmount);
    final paid = ytd.fold<double>(0, (a, c) => a + c.insurancePaid);
    final owed = ytd.fold<double>(0, (a, c) => a + c.patientResponsibility);
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            label: 'YTD billed',
            value: _moneyRound.format(billed),
            color: _kAccentDeep,
            icon: Icons.receipt_long_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Insurance paid',
            value: _moneyRound.format(paid),
            color: AppTheme.statusGreen,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Your cost',
            value: _moneyRound.format(owed),
            color: AppTheme.statusAmber,
            icon: Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alerts
// ---------------------------------------------------------------------------

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.claims, required this.policies});
  final List<InsuranceClaim> claims;
  final List<InsurancePolicy> policies;

  @override
  Widget build(BuildContext context) {
    final alerts = <_Alert>[];
    for (final c in claims) {
      if (c.hasImminentAppealDeadline) {
        alerts.add(_Alert(
          severity: _AlertSeverity.high,
          title:
              'Appeal deadline in ${c.appeal.appealDeadline!.difference(DateTime.now()).inDays} days',
          body:
              '${c.provider} · ${_money.format(c.billedAmount)} · denied for: '
              '${c.appeal.denialReason.isEmpty ? "reason not recorded" : c.appeal.denialReason}',
        ));
      } else if (c.status == ClaimStatus.denied && c.appeal.isEmpty) {
        alerts.add(_Alert(
          severity: _AlertSeverity.medium,
          title: 'Denied — no appeal started',
          body:
              '${c.provider} · ${_money.format(c.billedAmount)} (${DateFormat('MMM d').format(c.dateOfService)})',
        ));
      }
    }
    for (final p in policies) {
      final days = p.daysUntilEnd;
      if (days != null && days >= 0 && days <= 30) {
        alerts.add(_Alert(
          severity: _AlertSeverity.medium,
          title: '${p.planName} ends in $days days',
          body:
              '${p.carrier} · renew or shop alternatives before coverage lapses',
        ));
      }
    }

    if (alerts.isEmpty) return const SizedBox.shrink();
    final worst = alerts.any((a) => a.severity == _AlertSeverity.high)
        ? _AlertSeverity.high
        : _AlertSeverity.medium;
    final color = worst == _AlertSeverity.high
        ? AppTheme.dangerColor
        : AppTheme.statusAmber;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                'ACTION NEEDED (${alerts.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final a in alerts.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    decoration: BoxDecoration(
                      color: a.severity == _AlertSeverity.high
                          ? AppTheme.dangerColor
                          : AppTheme.statusAmber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          a.body,
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary,
                              height: 1.4),
                        ),
                      ],
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

enum _AlertSeverity { high, medium }

class _Alert {
  final _AlertSeverity severity;
  final String title;
  final String body;
  const _Alert({
    required this.severity,
    required this.title,
    required this.body,
  });
}

// ---------------------------------------------------------------------------
// Policies section
// ---------------------------------------------------------------------------

class _PoliciesSection extends StatelessWidget {
  const _PoliciesSection({
    required this.policies,
    required this.uid,
    required this.elderId,
    required this.onAdd,
    required this.onEdit,
    required this.onAddCounter,
    required this.onEditCounter,
  });

  final List<InsurancePolicy> policies;
  final String uid;
  final String elderId;
  final VoidCallback onAdd;
  final void Function(InsurancePolicy) onEdit;
  final void Function(InsurancePolicy) onAddCounter;
  final void Function(InsurancePolicy, BenefitCounter) onEditCounter;

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
              Icon(Icons.health_and_safety_outlined,
                  size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'POLICIES (${policies.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kAccentDeep,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 14),
                label:
                    const Text('Add policy', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: _kAccentDeep,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (policies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No policies yet.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),
          for (final p in policies)
            _PolicyCard(
              policy: p,
              onEdit: () => onEdit(p),
              onAddCounter: () => onAddCounter(p),
              onEditCounter: (c) => onEditCounter(p, c),
            ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.policy,
    required this.onEdit,
    required this.onAddCounter,
    required this.onEditCounter,
  });

  final InsurancePolicy policy;
  final VoidCallback onEdit;
  final VoidCallback onAddCounter;
  final void Function(BenefitCounter) onEditCounter;

  @override
  Widget build(BuildContext context) {
    final active = policy.isCurrentlyActive;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Icon(Icons.shield_outlined,
                    color: _kAccentDeep, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            policy.planName.isEmpty
                                ? '(Unnamed plan)'
                                : policy.planName,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (active
                                    ? AppTheme.statusGreen
                                    : AppTheme.textSecondary)
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusXL),
                          ),
                          child: Text(
                            active ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: active
                                  ? AppTheme.statusGreen
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${policy.carrier} · ${policy.planType.label}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary),
                    ),
                    if (policy.memberId != null &&
                        policy.memberId!.isNotEmpty)
                      Text(
                        'Member ID ${policy.memberId}',
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary),
                      ),
                    if (policy.claimsPhone != null &&
                        policy.claimsPhone!.isNotEmpty)
                      InkWell(
                        onTap: () => launchUrl(
                            Uri.parse('tel:${policy.claimsPhone}')),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            children: [
                              Icon(Icons.call,
                                  size: 12, color: _kAccentDeep),
                              const SizedBox(width: 4),
                              Text(
                                'Claims: ${policy.claimsPhone}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: _kAccentDeep,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: AppTheme.textSecondary),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _BenefitCountersRow(
            policy: policy,
            onAdd: onAddCounter,
            onEdit: onEditCounter,
          ),
        ],
      ),
    );
  }
}

class _BenefitCountersRow extends StatelessWidget {
  const _BenefitCountersRow({
    required this.policy,
    required this.onAdd,
    required this.onEdit,
  });

  final InsurancePolicy policy;
  final VoidCallback onAdd;
  final void Function(BenefitCounter) onEdit;

  @override
  Widget build(BuildContext context) {
    if (policy.id == null) return const SizedBox.shrink();
    final firestore = context.watch<FirestoreService>();
    return StreamBuilder<List<BenefitCounter>>(
      stream: firestore.getBenefitCountersStream(policy.id!),
      builder: (context, snap) {
        final counters = snap.data ?? const <BenefitCounter>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up,
                    size: 13, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'BENEFITS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 12),
                  label:
                      const Text('Add', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: _kAccentDeep,
                    visualDensity: VisualDensity.compact,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
              ],
            ),
            if (counters.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 2, bottom: 2),
                child: Text(
                  'Track PT visits, SNF days, therapy dollars here.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textLight,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              for (final c in counters)
                _BenefitCounterRow(
                  counter: c,
                  onTap: () => onEdit(c),
                ),
          ],
        );
      },
    );
  }
}

class _BenefitCounterRow extends StatelessWidget {
  const _BenefitCounterRow(
      {required this.counter, required this.onTap});
  final BenefitCounter counter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = counter.progress;
    final exhausted = counter.isExhausted;
    final color = exhausted
        ? AppTheme.dangerColor
        : progress > 0.8
            ? AppTheme.statusAmber
            : AppTheme.statusGreen;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                counter.benefitName,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 92,
              child: Text(
                counter.displaySummary,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claims section
// ---------------------------------------------------------------------------

class _ClaimsSection extends StatelessWidget {
  const _ClaimsSection({
    required this.claims,
    required this.policies,
    required this.filter,
    required this.onFilterChange,
    required this.onTap,
  });

  final List<InsuranceClaim> claims;
  final List<InsurancePolicy> policies;
  final ClaimStatus? filter;
  final ValueChanged<ClaimStatus?> onFilterChange;
  final void Function(InsuranceClaim) onTap;

  @override
  Widget build(BuildContext context) {
    final visible = filter == null
        ? claims
        : claims.where((c) => c.status == filter).toList();

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
              Icon(Icons.receipt_long, size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'CLAIMS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kAccentDeep,
                ),
              ),
              const Spacer(),
              Text(
                '${visible.length} of ${claims.length}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All', style: TextStyle(fontSize: 11)),
                  selected: filter == null,
                  onSelected: (_) => onFilterChange(null),
                ),
                const SizedBox(width: 6),
                for (final s in ClaimStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(s.label,
                          style: const TextStyle(fontSize: 11)),
                      selected: filter == s,
                      selectedColor: s.color.withValues(alpha: 0.18),
                      onSelected: (_) => onFilterChange(s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No claims match this filter.',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic),
                ),
              ),
            )
          else
            for (final c in visible.take(50))
              _ClaimRow(
                claim: c,
                policyLabel: _policyShortLabel(c.policyId),
                onTap: () => onTap(c),
              ),
        ],
      ),
    );
  }

  String _policyShortLabel(String? policyId) {
    if (policyId == null) return 'No policy';
    final p = policies.firstWhere(
      (p) => p.id == policyId,
      orElse: () => InsurancePolicy(
        userId: '',
        careRecipientId: '',
        planName: 'Unknown',
        carrier: '',
        startDate: DateTime.now(),
      ),
    );
    return p.planName.isEmpty ? 'No policy' : p.planName;
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({
    required this.claim,
    required this.policyLabel,
    required this.onTap,
  });

  final InsuranceClaim claim;
  final String policyLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final needsAction =
        claim.status == ClaimStatus.denied && claim.appeal.isEmpty;
    final urgent = claim.hasImminentAppealDeadline;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: urgent
              ? Border.all(
                  color: AppTheme.dangerColor.withValues(alpha: 0.5),
                  width: 1.2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: claim.status.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(claim.status.icon,
                  size: 16, color: claim.status.color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    claim.provider.isEmpty ? '(No provider)' : claim.provider,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (claim.serviceDescription.isNotEmpty)
                    Text(
                      claim.serviceDescription,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(claim.dateOfService)}'
                    ' · $policyLabel',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textLight),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: [
                      _Pill(
                        color: claim.status.color,
                        label: claim.status.label,
                      ),
                      if (urgent)
                        const _Pill(
                          color: AppTheme.dangerColor,
                          label: 'URGENT',
                        ),
                      if (needsAction)
                        const _Pill(
                          color: AppTheme.statusAmber,
                          label: 'Start appeal',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money.format(claim.billedAmount),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
                if (claim.patientResponsibility > 0)
                  Text(
                    'You: ${_money.format(claim.patientResponsibility)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.statusAmber,
                      fontWeight: FontWeight.w600,
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

class _Pill extends StatelessWidget {
  const _Pill({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Coverage insight card (AI scaffold)
// ---------------------------------------------------------------------------

class _CoverageInsightCard extends StatefulWidget {
  const _CoverageInsightCard({
    required this.claims,
    required this.policies,
    required this.elderName,
    required this.elderId,
  });

  final List<InsuranceClaim> claims;
  final List<InsurancePolicy> policies;
  final String elderName;
  final String elderId;

  @override
  State<_CoverageInsightCard> createState() => _CoverageInsightCardState();
}

class _CoverageInsightCardState extends State<_CoverageInsightCard> {
  bool _busy = false;
  String? _insightText;

  Future<void> _ask() async {
    if (_busy) return;
    setState(() => _busy = true);
    final res = await AiSuggestionService.instance.suggestCoverageInsight(
      elderId: widget.elderId,
      elderDisplayName: widget.elderName,
      context: {
        'claimCount': widget.claims.length,
        'deniedCount':
            widget.claims.where((c) => c.status == ClaimStatus.denied).length,
        'appealedCount': widget.claims
            .where((c) => c.status == ClaimStatus.appealed)
            .length,
        'policyCount': widget.policies.length,
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _insightText = res.suggestion ?? res.errorMessage;
    });
  }

  String _ruleBasedSummary() {
    final denied =
        widget.claims.where((c) => c.status == ClaimStatus.denied).length;
    final appealed = widget.claims
        .where((c) => c.status == ClaimStatus.appealed)
        .length;
    final pending = widget.claims
        .where((c) =>
            c.status == ClaimStatus.submitted ||
            c.status == ClaimStatus.pending)
        .length;
    final pieces = <String>[];
    if (denied > 0) {
      pieces.add('$denied denied');
    }
    if (appealed > 0) {
      pieces.add('$appealed on appeal');
    }
    if (pending > 0) {
      pieces.add('$pending awaiting response');
    }
    if (pieces.isEmpty) {
      return 'Everything on file is resolved. Nice work keeping up.';
    }
    return '${pieces.join(', ')}. Tap a claim to add details or open an appeal.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kAccent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Text(
                'COVERAGE SNAPSHOT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _kAccentDeep,
                ),
              ),
              const Spacer(),
              _AiStubChip(onTap: _ask, busy: _busy),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _insightText ?? _ruleBasedSummary(),
            style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textPrimary,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AiStubChip extends StatelessWidget {
  const _AiStubChip({required this.onTap, required this.busy});
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final available = AiSuggestionService.instance.isAvailable;
    return Tooltip(
      message: available
          ? 'Ask AI for a coverage insight'
          : 'AI insights are coming soon',
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  available
                      ? Icons.auto_awesome_outlined
                      : Icons.lock_clock_outlined,
                  size: 12,
                  color: available ? _kAccentDeep : AppTheme.textSecondary,
                ),
              const SizedBox(width: 4),
              Text(
                available ? 'AI hint' : 'Soon',
                style: TextStyle(
                  fontSize: 10.5,
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

class _DisclaimerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: const Text(
        'This is a caregiver-curated record — it does not replace '
        'Explanation-of-Benefits statements. Keep the carrier\'s original '
        'EOBs and denial letters for tax deduction substantiation and '
        'appeal proof.',
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

// ---------------------------------------------------------------------------
// Policy editor sheet
// ---------------------------------------------------------------------------

Future<void> _showPolicyEditor(
  BuildContext context, {
  required String uid,
  required String elderId,
  required InsurancePolicy? existing,
}) async {
  final firestore = context.read<FirestoreService>();
  final saved = await showModalBottomSheet<InsurancePolicy>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _PolicyEditorSheet(
      uid: uid,
      elderId: elderId,
      existing: existing,
    ),
  );
  if (saved == null || !context.mounted) return;
  try {
    if (existing?.id == null) {
      await firestore.addInsurancePolicy(saved);
    } else {
      await firestore.updateInsurancePolicy(saved);
    }
    if (context.mounted) {
      HapticUtils.success();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Policy saved.'),
        backgroundColor: AppTheme.statusGreen,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save policy: $e'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }
}

class _PolicyEditorSheet extends StatefulWidget {
  const _PolicyEditorSheet({
    required this.uid,
    required this.elderId,
    required this.existing,
  });

  final String uid;
  final String elderId;
  final InsurancePolicy? existing;

  @override
  State<_PolicyEditorSheet> createState() => _PolicyEditorSheetState();
}

class _PolicyEditorSheetState extends State<_PolicyEditorSheet> {
  late final TextEditingController _planName;
  late final TextEditingController _carrier;
  late final TextEditingController _memberId;
  late final TextEditingController _groupNumber;
  late final TextEditingController _rxBin;
  late final TextEditingController _claimsPhone;
  late final TextEditingController _memberPhone;
  late final TextEditingController _portalUrl;
  late final TextEditingController _deductible;
  late final TextEditingController _oop;
  late final TextEditingController _premium;
  late final TextEditingController _notes;

  InsurancePlanType _planType = InsurancePlanType.other;
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _planName = TextEditingController(text: e?.planName ?? '');
    _carrier = TextEditingController(text: e?.carrier ?? '');
    _memberId = TextEditingController(text: e?.memberId ?? '');
    _groupNumber = TextEditingController(text: e?.groupNumber ?? '');
    _rxBin = TextEditingController(text: e?.rxBin ?? '');
    _claimsPhone = TextEditingController(text: e?.claimsPhone ?? '');
    _memberPhone = TextEditingController(text: e?.memberServicesPhone ?? '');
    _portalUrl = TextEditingController(text: e?.portalUrl ?? '');
    _deductible = TextEditingController(
        text: e?.annualDeductible?.toString() ?? '');
    _oop = TextEditingController(text: e?.outOfPocketMax?.toString() ?? '');
    _premium =
        TextEditingController(text: e?.monthlyPremium?.toString() ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _planType = e?.planType ?? InsurancePlanType.other;
    _startDate = e?.startDate ?? DateTime(DateTime.now().year, 1, 1);
    _endDate = e?.endDate;
  }

  @override
  void dispose() {
    _planName.dispose();
    _carrier.dispose();
    _memberId.dispose();
    _groupNumber.dispose();
    _rxBin.dispose();
    _claimsPhone.dispose();
    _memberPhone.dispose();
    _portalUrl.dispose();
    _deductible.dispose();
    _oop.dispose();
    _premium.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (_planName.text.trim().isEmpty || _carrier.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Plan name and carrier are required.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    final result = InsurancePolicy(
      id: widget.existing?.id,
      userId: widget.uid,
      careRecipientId: widget.elderId,
      planName: _planName.text.trim(),
      carrier: _carrier.text.trim(),
      planType: _planType,
      memberId:
          _memberId.text.trim().isEmpty ? null : _memberId.text.trim(),
      groupNumber:
          _groupNumber.text.trim().isEmpty ? null : _groupNumber.text.trim(),
      rxBin: _rxBin.text.trim().isEmpty ? null : _rxBin.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      annualDeductible: double.tryParse(_deductible.text.trim()),
      outOfPocketMax: double.tryParse(_oop.text.trim()),
      monthlyPremium: double.tryParse(_premium.text.trim()),
      claimsPhone:
          _claimsPhone.text.trim().isEmpty ? null : _claimsPhone.text.trim(),
      memberServicesPhone:
          _memberPhone.text.trim().isEmpty ? null : _memberPhone.text.trim(),
      portalUrl:
          _portalUrl.text.trim().isEmpty ? null : _portalUrl.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.existing?.createdAt,
    );
    Navigator.of(context).pop(result);
  }

  Future<void> _pickDate(
      {required bool isStart, required DateTime initial}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 20),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            _SheetTitle(
                title: widget.existing == null
                    ? 'Add policy'
                    : 'Edit policy'),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  _Label('Plan name *'),
                  _tf(_planName, 'Blue Cross PPO Gold'),
                  const SizedBox(height: 10),
                  _Label('Carrier *'),
                  _tf(_carrier, 'Blue Cross Blue Shield'),
                  const SizedBox(height: 10),
                  _Label('Plan type'),
                  DropdownButtonFormField<InsurancePlanType>(
                    initialValue: _planType,
                    decoration: _decoration(),
                    items: [
                      for (final t in InsurancePlanType.values)
                        DropdownMenuItem(
                          value: t,
                          child: Text(t.label,
                              style: const TextStyle(fontSize: 13)),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _planType = v ?? _planType),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Member ID'),
                            _tf(_memberId, 'ABC123456789'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Group #'),
                            _tf(_groupNumber, '00123'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Label('Rx BIN (Part D / pharmacy plans)'),
                  _tf(_rxBin, '004336'),
                  const SizedBox(height: 14),
                  _Label('Coverage window'),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () =>
                              _pickDate(isStart: true, initial: _startDate),
                          child: InputDecorator(
                            decoration: _decoration(label: 'Starts'),
                            child: Text(
                              DateFormat('MMM d, yyyy').format(_startDate),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _pickDate(
                              isStart: false,
                              initial:
                                  _endDate ?? _startDate.add(const Duration(days: 365))),
                          onLongPress: () =>
                              setState(() => _endDate = null),
                          child: InputDecorator(
                            decoration: _decoration(label: 'Ends'),
                            child: Text(
                              _endDate == null
                                  ? 'Open-ended'
                                  : DateFormat('MMM d, yyyy').format(_endDate!),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_endDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton.icon(
                        onPressed: () => setState(() => _endDate = null),
                        icon: const Icon(Icons.clear, size: 14),
                        label: const Text(
                          'Clear end date (open-ended)',
                          style: TextStyle(fontSize: 11),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.textSecondary,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 24),
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  _Label('Costs'),
                  Row(
                    children: [
                      Expanded(
                        child: _tf(_deductible, 'Deductible \$',
                            number: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _tf(_oop, 'OOP max \$', number: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _tf(_premium, 'Premium \$/mo', number: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Label('Contacts'),
                  _tf(_claimsPhone, 'Claims phone',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 8),
                  _tf(_memberPhone, 'Member services phone',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 8),
                  _tf(_portalUrl, 'Portal URL',
                      keyboardType: TextInputType.url),
                  const SizedBox(height: 14),
                  _Label('Notes'),
                  _tf(_notes, 'Prior-auth phone, pharmacy rider, etc.',
                      maxLines: 3),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccentDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM)),
                      ),
                      child: Text(
                        widget.existing == null
                            ? 'Add policy'
                            : 'Save changes',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (widget.existing?.id != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete this policy?'),
                            content: const Text(
                              'Claims linked to this policy will keep '
                              'their reference but the policy itself '
                              'will be gone. This can\'t be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        AppTheme.dangerColor),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        final firestore = context.read<FirestoreService>();
                        try {
                          await firestore
                              .deleteInsurancePolicy(widget.existing!.id!);
                          if (context.mounted) Navigator.of(context).pop();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('Could not delete: $e'),
                                backgroundColor: AppTheme.dangerColor,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete policy'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.dangerColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(TextEditingController c, String hint,
      {int maxLines = 1,
      bool number = false,
      TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : keyboardType,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
          : null,
      decoration: _decoration(hint: hint),
      style: const TextStyle(fontSize: 13),
    );
  }

  InputDecoration _decoration({String? hint, String? label}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      isDense: true,
      hintStyle: const TextStyle(fontSize: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS)),
    );
  }
}

// ---------------------------------------------------------------------------
// Benefit counter editor
// ---------------------------------------------------------------------------

Future<void> _showCounterEditor(
  BuildContext context, {
  required String uid,
  required InsurancePolicy policy,
  required BenefitCounter? existing,
}) async {
  if (policy.id == null) return;
  final firestore = context.read<FirestoreService>();
  final saved = await showModalBottomSheet<BenefitCounter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _BenefitCounterSheet(
      uid: uid,
      policy: policy,
      existing: existing,
    ),
  );
  if (saved == null || !context.mounted) return;
  try {
    if (existing?.id == null) {
      await firestore.addBenefitCounter(saved);
    } else {
      await firestore.updateBenefitCounter(saved);
    }
    if (context.mounted) HapticUtils.success();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save counter: $e'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }
}

class _BenefitCounterSheet extends StatefulWidget {
  const _BenefitCounterSheet({
    required this.uid,
    required this.policy,
    required this.existing,
  });

  final String uid;
  final InsurancePolicy policy;
  final BenefitCounter? existing;

  @override
  State<_BenefitCounterSheet> createState() => _BenefitCounterSheetState();
}

class _BenefitCounterSheetState extends State<_BenefitCounterSheet> {
  late final TextEditingController _name;
  late final TextEditingController _limit;
  late final TextEditingController _used;
  late final TextEditingController _notes;
  late BenefitUnit _unit;
  late DateTime _start;
  DateTime? _end;

  static const List<String> _presets = [
    'Physical therapy visits',
    'Occupational therapy visits',
    'Speech therapy visits',
    'Skilled nursing facility days',
    'Home health aide hours',
    'Mental health visits',
    'Chiropractic visits',
    'Acupuncture visits',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.benefitName ?? '');
    _limit = TextEditingController(text: e?.limit.toString() ?? '');
    _used = TextEditingController(text: e?.used.toString() ?? '0');
    _notes = TextEditingController(text: e?.notes ?? '');
    _unit = e?.unit ?? BenefitUnit.visit;
    _start =
        e?.periodStart ?? DateTime(DateTime.now().year, 1, 1);
    _end = e?.periodEnd ?? DateTime(DateTime.now().year, 12, 31);
  }

  @override
  void dispose() {
    _name.dispose();
    _limit.dispose();
    _used.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final limit = double.tryParse(_limit.text.trim());
    if (_name.text.trim().isEmpty || limit == null || limit <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a benefit name and positive limit.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    final used = double.tryParse(_used.text.trim()) ?? 0;
    final counter = BenefitCounter(
      id: widget.existing?.id,
      policyId: widget.policy.id!,
      userId: widget.uid,
      benefitName: _name.text.trim(),
      limit: limit,
      used: used.clamp(0, limit * 2).toDouble(),
      unit: _unit,
      periodStart: _start,
      periodEnd: _end,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.existing?.createdAt,
    );
    Navigator.of(context).pop(counter);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            _SheetTitle(
              title: widget.existing == null
                  ? 'Add benefit counter'
                  : 'Edit benefit counter',
              subtitle: '${widget.policy.planName} · ${widget.policy.carrier}',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  _Label('Benefit name *'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final p in _presets)
                        ChoiceChip(
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          selected: _name.text == p,
                          onSelected: (_) {
                            setState(() => _name.text = p);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _name,
                    decoration: InputDecoration(
                      hintText: 'Or type a custom name',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusS)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  _Label('Limit / unit *'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _limit,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Limit (20)',
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusS)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child:
                            DropdownButtonFormField<BenefitUnit>(
                          initialValue: _unit,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusS)),
                          ),
                          items: [
                            for (final u in BenefitUnit.values)
                              DropdownMenuItem(
                                value: u,
                                child: Text(u.label,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _unit = v ?? _unit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Label('Already used (so far)'),
                  TextField(
                    controller: _used,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                      hintText: 'e.g., 7 (default 0)',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusS)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _Label('Period'),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _start,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(
                                  DateTime.now().year + 20),
                            );
                            if (picked != null) {
                              setState(() => _start = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Starts',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusS)),
                            ),
                            child: Text(
                                DateFormat('MMM d, yyyy').format(_start),
                                style: const TextStyle(fontSize: 13)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate:
                                  _end ?? _start.add(const Duration(days: 365)),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(
                                  DateTime.now().year + 20),
                            );
                            if (picked != null) {
                              setState(() => _end = picked);
                            }
                          },
                          onLongPress: () =>
                              setState(() => _end = null),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              isDense: true,
                              labelText: 'Ends',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusS)),
                            ),
                            child: Text(
                              _end == null
                                  ? 'Open-ended'
                                  : DateFormat('MMM d, yyyy').format(_end!),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Label('Notes'),
                  TextField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Lifetime cap, prior-auth required, etc.',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusS)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccentDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM)),
                      ),
                      child: Text(
                        widget.existing == null
                            ? 'Add counter'
                            : 'Save changes',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (widget.existing?.id != null) ...[
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: () async {
                        final firestore = context.read<FirestoreService>();
                        await firestore.deleteBenefitCounter(
                          policyId: widget.policy.id!,
                          counterId: widget.existing!.id!,
                        );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete counter'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.dangerColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claim editor sheet (with appeal fields inline)
// ---------------------------------------------------------------------------

Future<void> _showClaimEditor(
  BuildContext context, {
  required String uid,
  required String elderId,
  required List<InsurancePolicy> policies,
  required InsuranceClaim? existing,
}) async {
  final firestore = context.read<FirestoreService>();
  final saved = await showModalBottomSheet<InsuranceClaim>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => _ClaimEditorSheet(
      uid: uid,
      elderId: elderId,
      policies: policies,
      existing: existing,
    ),
  );
  if (saved == null || !context.mounted) return;
  try {
    if (existing?.id == null) {
      await firestore.addInsuranceClaim(saved);
    } else {
      await firestore.updateInsuranceClaim(saved);
    }
    if (context.mounted) {
      HapticUtils.success();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Claim saved.'),
        backgroundColor: AppTheme.statusGreen,
      ));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save claim: $e'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }
}

class _ClaimEditorSheet extends StatefulWidget {
  const _ClaimEditorSheet({
    required this.uid,
    required this.elderId,
    required this.policies,
    required this.existing,
  });

  final String uid;
  final String elderId;
  final List<InsurancePolicy> policies;
  final InsuranceClaim? existing;

  @override
  State<_ClaimEditorSheet> createState() => _ClaimEditorSheetState();
}

class _ClaimEditorSheetState extends State<_ClaimEditorSheet> {
  late final TextEditingController _provider;
  late final TextEditingController _service;
  late final TextEditingController _cpt;
  late final TextEditingController _claimNumber;
  late final TextEditingController _billed;
  late final TextEditingController _paid;
  late final TextEditingController _owed;
  late final TextEditingController _notes;
  late final TextEditingController _denialReason;
  late final TextEditingController _appealLetter;
  late final TextEditingController _outcomeNotes;

  DateTime _dateOfService = DateTime.now();
  DateTime? _dateSubmitted;
  DateTime? _dateResolved;
  DateTime? _appealDeadline;
  DateTime? _appealSubmittedOn;
  ClaimStatus _status = ClaimStatus.submitted;
  ClaimAppealOutcome _outcome = ClaimAppealOutcome.pending;
  String? _policyId;
  bool _aiBusy = false;

  bool get _isAppealMode =>
      _status == ClaimStatus.denied || _status == ClaimStatus.appealed;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _provider = TextEditingController(text: e?.provider ?? '');
    _service = TextEditingController(text: e?.serviceDescription ?? '');
    _cpt = TextEditingController(text: e?.cptCode ?? '');
    _claimNumber = TextEditingController(text: e?.claimNumber ?? '');
    _billed =
        TextEditingController(text: e?.billedAmount.toString() ?? '');
    _paid =
        TextEditingController(text: e?.insurancePaid.toString() ?? '0');
    _owed = TextEditingController(
        text: e?.patientResponsibility.toString() ?? '0');
    _notes = TextEditingController(text: e?.notes ?? '');
    _denialReason =
        TextEditingController(text: e?.appeal.denialReason ?? '');
    _appealLetter =
        TextEditingController(text: e?.appeal.appealLetterText ?? '');
    _outcomeNotes =
        TextEditingController(text: e?.appeal.outcomeNotes ?? '');
    _dateOfService = e?.dateOfService ?? DateTime.now();
    _dateSubmitted = e?.dateSubmitted;
    _dateResolved = e?.dateResolved;
    _appealDeadline = e?.appeal.appealDeadline;
    _appealSubmittedOn = e?.appeal.appealSubmittedOn;
    _status = e?.status ?? ClaimStatus.submitted;
    _outcome = e?.appeal.outcome ?? ClaimAppealOutcome.pending;
    _policyId = e?.policyId ??
        (widget.policies.isNotEmpty ? widget.policies.first.id : null);
  }

  @override
  void dispose() {
    _provider.dispose();
    _service.dispose();
    _cpt.dispose();
    _claimNumber.dispose();
    _billed.dispose();
    _paid.dispose();
    _owed.dispose();
    _notes.dispose();
    _denialReason.dispose();
    _appealLetter.dispose();
    _outcomeNotes.dispose();
    super.dispose();
  }

  Future<void> _askAppealDraft() async {
    if (_aiBusy) return;
    final carrier = widget.policies
        .firstWhere(
          (p) => p.id == _policyId,
          orElse: () => InsurancePolicy(
            userId: '',
            careRecipientId: '',
            planName: '',
            carrier: 'the insurance carrier',
            startDate: DateTime.now(),
          ),
        )
        .carrier;
    setState(() => _aiBusy = true);
    final res = await AiSuggestionService.instance.suggestAppealDraft(
      elderId: widget.elderId,
      elderDisplayName: '',
      context: {
        'carrier': carrier,
        'claimNumber': _claimNumber.text.trim(),
        'provider': _provider.text.trim(),
        'dateOfService': DateFormat('yyyy-MM-dd').format(_dateOfService),
        'billedAmount': double.tryParse(_billed.text.trim()) ?? 0,
        'denialReason': _denialReason.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _aiBusy = false);
    if (res.available && res.suggestion != null) {
      setState(() => _appealLetter.text = res.suggestion!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.errorMessage ?? 'No draft available yet.'),
        backgroundColor: AppTheme.tileIndigoDark,
      ));
    }
  }

  void _submit() {
    if (_provider.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Provider is required.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    final billed = double.tryParse(_billed.text.trim()) ?? 0;
    final paid = double.tryParse(_paid.text.trim()) ?? 0;
    final owed = double.tryParse(_owed.text.trim()) ?? 0;

    final appeal = ClaimAppeal(
      denialReason: _denialReason.text.trim(),
      appealDeadline: _appealDeadline,
      appealSubmittedOn: _appealSubmittedOn,
      appealLetterText: _appealLetter.text.trim().isEmpty
          ? null
          : _appealLetter.text.trim(),
      outcome: _outcome,
      outcomeNotes: _outcomeNotes.text.trim().isEmpty
          ? null
          : _outcomeNotes.text.trim(),
    );

    final claim = InsuranceClaim(
      id: widget.existing?.id,
      userId: widget.uid,
      careRecipientId: widget.elderId,
      policyId: _policyId,
      dateOfService: _dateOfService,
      provider: _provider.text.trim(),
      serviceDescription: _service.text.trim(),
      cptCode: _cpt.text.trim().isEmpty ? null : _cpt.text.trim(),
      claimNumber: _claimNumber.text.trim().isEmpty
          ? null
          : _claimNumber.text.trim(),
      billedAmount: billed,
      insurancePaid: paid,
      patientResponsibility: owed,
      status: _status,
      dateSubmitted: _dateSubmitted,
      dateResolved: _dateResolved,
      appeal: appeal,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      createdAt: widget.existing?.createdAt,
    );
    Navigator.of(context).pop(claim);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.96,
      minChildSize: 0.6,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            _SheetTitle(
              title: widget.existing == null ? 'Log claim' : 'Edit claim',
              subtitle: widget.existing == null
                  ? null
                  : 'Claim ${widget.existing!.claimNumber ?? "—"}',
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  _Label('Policy'),
                  DropdownButtonFormField<String?>(
                    initialValue: _policyId,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusS)),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No policy',
                            style: TextStyle(fontSize: 13)),
                      ),
                      for (final p in widget.policies)
                        DropdownMenuItem<String?>(
                          value: p.id,
                          child: Text('${p.planName} · ${p.carrier}',
                              style: const TextStyle(fontSize: 13)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _policyId = v),
                  ),
                  const SizedBox(height: 12),
                  _Label('Provider *'),
                  TextField(
                    controller: _provider,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec('Dr. Chen, Memorial Hospital'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  _Label('Service / description'),
                  TextField(
                    controller: _service,
                    decoration: _dec('Cardiology follow-up visit'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Date of service'),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _dateOfService,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(
                                      DateTime.now().year + 5),
                                );
                                if (picked != null) {
                                  setState(
                                      () => _dateOfService = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: _dec(null),
                                child: Text(
                                    DateFormat('MMM d, yyyy')
                                        .format(_dateOfService),
                                    style: const TextStyle(fontSize: 13)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Label('Claim #'),
                            TextField(
                              controller: _claimNumber,
                              decoration: _dec('Carrier claim number'),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Label('CPT / billing code'),
                  TextField(
                    controller: _cpt,
                    decoration: _dec('99213'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  _Label('Amounts'),
                  Row(
                    children: [
                      Expanded(child: _money3(_billed, 'Billed')),
                      const SizedBox(width: 8),
                      Expanded(child: _money3(_paid, 'Insurance paid')),
                      const SizedBox(width: 8),
                      Expanded(child: _money3(_owed, 'Your cost')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _Label('Status'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in ClaimStatus.values)
                        ChoiceChip(
                          label: Text(s.label,
                              style: const TextStyle(fontSize: 12)),
                          selected: _status == s,
                          selectedColor: s.color.withValues(alpha: 0.18),
                          onSelected: (_) =>
                              setState(() => _status = s),
                        ),
                    ],
                  ),
                  if (_isAppealMode) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerColor.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusM),
                        border: Border.all(
                            color: AppTheme.dangerColor
                                .withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel_outlined,
                                  size: 16,
                                  color: AppTheme.dangerColor),
                              const SizedBox(width: 8),
                              const Text(
                                'DENIAL & APPEAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: AppTheme.dangerColor,
                                ),
                              ),
                              const Spacer(),
                              _AiStubChip(
                                  onTap: _askAppealDraft, busy: _aiBusy),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _Label('Denial reason'),
                          TextField(
                            controller: _denialReason,
                            maxLines: 2,
                            decoration: _dec(
                                'Not medically necessary / prior auth missing / …'),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _Label('Appeal deadline'),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: _appealDeadline ??
                                              DateTime.now().add(
                                                  const Duration(
                                                      days: 60)),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(
                                              DateTime.now().year + 5),
                                        );
                                        if (picked != null) {
                                          setState(() =>
                                              _appealDeadline = picked);
                                        }
                                      },
                                      onLongPress: () => setState(
                                          () => _appealDeadline = null),
                                      child: InputDecorator(
                                        decoration: _dec(null),
                                        child: Text(
                                          _appealDeadline == null
                                              ? 'Not set'
                                              : DateFormat(
                                                      'MMM d, yyyy')
                                                  .format(_appealDeadline!),
                                          style: const TextStyle(
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _Label('Appeal submitted'),
                                    InkWell(
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _appealSubmittedOn ??
                                                  DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(
                                              DateTime.now().year + 5),
                                        );
                                        if (picked != null) {
                                          setState(() =>
                                              _appealSubmittedOn =
                                                  picked);
                                        }
                                      },
                                      onLongPress: () => setState(
                                          () => _appealSubmittedOn = null),
                                      child: InputDecorator(
                                        decoration: _dec(null),
                                        child: Text(
                                          _appealSubmittedOn == null
                                              ? 'Not yet'
                                              : DateFormat(
                                                      'MMM d, yyyy')
                                                  .format(
                                                      _appealSubmittedOn!),
                                          style: const TextStyle(
                                              fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _Label('Appeal letter draft'),
                          TextField(
                            controller: _appealLetter,
                            maxLines: 6,
                            minLines: 4,
                            decoration: _dec(
                              'Dear Appeals Dept,\n\nI am writing to appeal the denial of claim #…',
                            ),
                            style: const TextStyle(
                                fontSize: 12.5, height: 1.45),
                          ),
                          const SizedBox(height: 10),
                          _Label('Outcome'),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final o
                                  in ClaimAppealOutcome.values)
                                ChoiceChip(
                                  label: Text(o.label,
                                      style:
                                          const TextStyle(fontSize: 11.5)),
                                  selected: _outcome == o,
                                  onSelected: (_) =>
                                      setState(() => _outcome = o),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _Label('Outcome notes'),
                          TextField(
                            controller: _outcomeNotes,
                            maxLines: 2,
                            decoration: _dec(
                                'Reviewer name, settlement amount, next steps…'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _Label('Notes'),
                  TextField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: _dec(
                        'Any context you might want at tax time or for the next appeal.'),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccentDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusM)),
                      ),
                      child: Text(
                        widget.existing == null
                            ? 'Save claim'
                            : 'Save changes',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (widget.existing?.id != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete this claim?'),
                            content: const Text(
                                'This can\'t be undone.'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
                                style: TextButton.styleFrom(
                                    foregroundColor:
                                        AppTheme.dangerColor),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !context.mounted) return;
                        final firestore = context.read<FirestoreService>();
                        await firestore
                            .deleteInsuranceClaim(widget.existing!.id!);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete claim'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.dangerColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _money3(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixText: '\$ ',
          isDense: true,
          border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(AppTheme.radiusS)),
        ),
        style: const TextStyle(fontSize: 13),
      );

  InputDecoration _dec(String? hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS)),
      );
}

// ---------------------------------------------------------------------------
// Shared sheet bits
// ---------------------------------------------------------------------------

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.textLight,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          Icon(Icons.health_and_safety_outlined,
              size: 22, color: _kAccentDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
