// lib/screens/emergency_card_screen.dart
//
// Lock-screen-style emergency info card for the active care recipient.
// Displays: name, DOB, allergies, dietary restrictions, current medications,
// and emergency contact. "Share as PDF" generates a one-page PDF and opens
// the system share sheet.
//
// Reads from ElderProfile (already has all fields) and
// MedicationDefinitionsProvider (for current med list).

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class EmergencyCardScreen extends StatelessWidget {
  const EmergencyCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeElder = context.watch<ActiveElderProvider>().activeElder;
    final medDefs = context.watch<MedicationDefinitionsProvider>();

    if (activeElder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Card')),
        body: const Center(
          child: Text(
            'No care recipient selected.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final displayName = activeElder.preferredName?.isNotEmpty == true
        ? activeElder.preferredName!
        : activeElder.profileName;
    final meds = medDefs.medDefinitions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Card'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          children: [
            // ── Emergency card ──────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.dangerColor.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.dangerColor.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Red header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_information_outlined,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EMERGENCY INFORMATION',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Date of Birth
                        if (activeElder.dateOfBirth.isNotEmpty)
                          _InfoRow(
                            icon: Icons.cake_outlined,
                            label: 'Date of Birth',
                            value: activeElder.dateOfBirth,
                            color: const Color(0xFF5C6BC0),
                          ),

                        // Allergies
                        _InfoRow(
                          icon: Icons.warning_amber_outlined,
                          label: 'Allergies',
                          value: activeElder.allergies.isNotEmpty
                              ? activeElder.allergies.join(', ')
                              : 'None listed',
                          color: const Color(0xFFF57C00),
                          isWarning: activeElder.allergies.isNotEmpty,
                        ),

                        // Dietary Restrictions
                        if (activeElder.dietaryRestrictions.isNotEmpty)
                          _InfoRow(
                            icon: Icons.restaurant_outlined,
                            label: 'Dietary Restrictions',
                            value: activeElder.dietaryRestrictions,
                            color: const Color(0xFF43A047),
                          ),

                        // Current Medications
                        _InfoRow(
                          icon: Icons.medication_outlined,
                          label: 'Current Medications',
                          value: meds.isNotEmpty
                              ? meds
                                  .map((m) => m.dose != null &&
                                          m.dose!.isNotEmpty
                                      ? '${m.name} (${m.dose})'
                                      : m.name)
                                  .join('\n')
                              : 'None listed',
                          color: const Color(0xFF1E88E5),
                        ),

                        // Divider before emergency contact
                        const Divider(height: 32),

                        // Emergency Contact
                        if (activeElder.emergencyContactName != null &&
                            activeElder
                                .emergencyContactName!.isNotEmpty) ...[
                          _InfoRow(
                            icon: Icons.contact_phone_outlined,
                            label: 'Emergency Contact',
                            value: [
                              activeElder.emergencyContactName!,
                              if (activeElder
                                      .emergencyContactRelationship !=
                                  null)
                                '(${activeElder.emergencyContactRelationship})',
                              if (activeElder.emergencyContactPhone !=
                                  null)
                                activeElder.emergencyContactPhone!,
                            ].join('\n'),
                            color: AppTheme.dangerColor,
                          ),
                        ] else
                          _InfoRow(
                            icon: Icons.contact_phone_outlined,
                            label: 'Emergency Contact',
                            value: 'Not set — add in Settings → Manage Care Recipients',
                            color: AppTheme.textLight,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Disclaimer
            Text(
              'Generated by Cecelia Care on ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 20),

            // ── Share as PDF button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _generateAndSharePdf(
                  context,
                  activeElder,
                  meds.map((m) => m.dose != null && m.dose!.isNotEmpty
                      ? '${m.name} (${m.dose})'
                      : m.name).toList(),
                ),
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text(
                  'Share as PDF',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Share with doctors, nurses, or family members',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF generation + share
  // ---------------------------------------------------------------------------
  Future<void> _generateAndSharePdf(
    BuildContext context,
    ElderProfile elder,
    List<String> medNames,
  ) async {
    try {
      final displayName = elder.preferredName?.isNotEmpty == true
          ? elder.preferredName!
          : elder.profileName;

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E53935'),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EMERGENCY INFORMATION',
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        displayName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Date of Birth
                if (elder.dateOfBirth.isNotEmpty)
                  _pdfInfoRow('Date of Birth', elder.dateOfBirth),

                // Allergies
                _pdfInfoRow(
                  'Allergies',
                  elder.allergies.isNotEmpty
                      ? elder.allergies.join(', ')
                      : 'None listed',
                  isHighlight: elder.allergies.isNotEmpty,
                ),

                // Dietary Restrictions
                if (elder.dietaryRestrictions.isNotEmpty)
                  _pdfInfoRow(
                      'Dietary Restrictions', elder.dietaryRestrictions),

                // Medications
                _pdfInfoRow(
                  'Current Medications',
                  medNames.isNotEmpty
                      ? medNames.join('\n')
                      : 'None listed',
                ),

                pw.SizedBox(height: 10),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 10),

                // Emergency Contact
                if (elder.emergencyContactName != null &&
                    elder.emergencyContactName!.isNotEmpty) ...[
                  _pdfInfoRow(
                    'Emergency Contact',
                    [
                      elder.emergencyContactName!,
                      if (elder.emergencyContactRelationship != null)
                        '(${elder.emergencyContactRelationship})',
                      if (elder.emergencyContactPhone != null)
                        elder.emergencyContactPhone!,
                    ].join('\n'),
                  ),
                ] else
                  _pdfInfoRow('Emergency Contact', 'Not set'),

                pw.Spacer(),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'Generated by Cecelia Care on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey500,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      // Save to temp directory and share
      final Directory tempDir = await getTemporaryDirectory();
      final safeName = displayName.replaceAll(RegExp(r'[^\w\s]'), '');
      final file = File(
          '${tempDir.path}/Emergency_Card_$safeName.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Emergency Card — $displayName',
      );

      if (context.mounted) {
        HapticUtils.success();
      }
    } catch (e) {
      debugPrint('EmergencyCardScreen._generateAndSharePdf error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate PDF: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  // PDF info row helper
  static pw.Widget _pdfInfoRow(String label, String value,
      {bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: isHighlight
                  ? PdfColor.fromHex('#FFF3E0')
                  : PdfColor.fromHex('#F5F5F5'),
              borderRadius: pw.BorderRadius.circular(6),
              border: isHighlight
                  ? pw.Border.all(color: PdfColor.fromHex('#F57C00'), width: 0.5)
                  : null,
            ),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight:
                    isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isHighlight
                    ? PdfColor.fromHex('#E65100')
                    : PdfColors.grey800,
                lineSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InfoRow — on-screen info row with icon, label, and value
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isWarning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: color.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isWarning
                        ? const Color(0xFFFFF3E0)
                        : AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                    border: isWarning
                        ? Border.all(
                            color: const Color(0xFFF57C00).withOpacity(0.3))
                        : null,
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isWarning ? FontWeight.w600 : FontWeight.normal,
                      color: isWarning
                          ? const Color(0xFFE65100)
                          : AppTheme.textPrimary,
                      height: 1.4,
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
