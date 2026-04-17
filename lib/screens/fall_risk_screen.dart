// lib/screens/fall_risk_screen.dart
//
// CDC STEADI-based fall risk assessment. 15 risk factors + 5 protective
// measures. Computes a risk score with level/color. History tracking.
import 'package:cecelia_care_flutter/utils/save_helpers.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/fall_risk_assessment.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';

class FallRiskScreen extends StatefulWidget {
  const FallRiskScreen({super.key});

  @override
  State<FallRiskScreen> createState() => _FallRiskScreenState();
}

class _FallRiskScreenState extends State<FallRiskScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _showForm = false;

  // Form state
  final Map<String, bool> _fallHistory = {
    for (final k in FallRiskAssessment.kFallHistoryLabels.keys) k: false,
  };
  final Map<String, bool> _balance = {
    for (final k in FallRiskAssessment.kBalanceLabels.keys) k: false,
  };
  final Map<String, bool> _medication = {
    for (final k in FallRiskAssessment.kMedicationLabels.keys) k: false,
  };
  final Map<String, bool> _environmental = {
    for (final k in FallRiskAssessment.kEnvironmentalLabels.keys) k: false,
  };
  final Map<String, bool> _protective = {
    for (final k in FallRiskAssessment.kProtectiveLabels.keys) k: false,
  };
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // Live score preview from form state.
  int get _liveScore {
    int score = 0;
    for (final v in _fallHistory.values) { if (v) score += 2; }
    for (final v in _balance.values) { if (v) score++; }
    for (final v in _medication.values) { if (v) score++; }
    for (final v in _environmental.values) { if (v) score++; }
    for (final v in _protective.values) { if (v) score--; }
    return score.clamp(0, 20);
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final elderId =
          context.read<ActiveElderProvider>().activeElder?.id ?? '';
      if (elderId.isEmpty) return;

      final assessment = FallRiskAssessment(
        elderId: elderId,
        assessedBy: user.uid,
        assessedByName: user.displayName ?? user.email ?? 'Unknown',
        dateString: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        hasFallenPastYear: _fallHistory['hasFallenPastYear']!,
        hasFallenMultipleTimes: _fallHistory['hasFallenMultipleTimes']!,
        hasInjuryFromFall: _fallHistory['hasInjuryFromFall']!,
        hasUnsteadyGait: _balance['hasUnsteadyGait']!,
        needsAssistanceWalking: _balance['needsAssistanceWalking']!,
        hasDifficultyRising: _balance['hasDifficultyRising']!,
        hasBalanceProblems: _balance['hasBalanceProblems']!,
        hasFeetOrLegProblems: _balance['hasFeetOrLegProblems']!,
        takesSedatives: _medication['takesSedatives']!,
        takesFourPlusMeds: _medication['takesFourPlusMeds']!,
        hasMedsCausingDizziness: _medication['hasMedsCausingDizziness']!,
        hasLooseRugs: _environmental['hasLooseRugs']!,
        hasPoorLighting: _environmental['hasPoorLighting']!,
        lacksGrabBars: _environmental['lacksGrabBars']!,
        hasClutteredPaths: _environmental['hasClutteredPaths']!,
        usesAssistiveDevice: _protective['usesAssistiveDevice']!,
        hasGrabBarsInstalled: _protective['hasGrabBarsInstalled']!,
        wearsProperFootwear: _protective['wearsProperFootwear']!,
        doesExerciseProgram: _protective['doesExerciseProgram']!,
        hasHomeAssessed: _protective['hasHomeAssessed']!,
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

      final data = assessment.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.addFallRiskAssessment(elderId, data);
      HapticUtils.success();

      if (mounted) {
        setState(() => _showForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Fall risk assessment saved.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Fall risk save error: $e');
      if (mounted) showSaveError(context, e, label: 'Fall risk');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Fall Risk Assessment')),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestore.getFallRiskAssessmentsStream(elderId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const SkeletonCard();
                }

                final assessments = (snapshot.data ?? [])
                    .map((raw) => FallRiskAssessment.fromFirestore(
                        raw['id'] as String? ?? '', raw))
                    .toList();

                final latest =
                    assessments.isNotEmpty ? assessments.first : null;

                if (_showForm || latest == null) return _buildForm();
                return _buildResults(latest, assessments);
              },
            ),
    );
  }

  // ── Results view ────────────────────────────────────────────────

  Widget _buildResults(
      FallRiskAssessment latest, List<FallRiskAssessment> history) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score hero card
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: latest.rawRiskScore / 20,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(latest.riskColor),
                      ),
                      Text('${latest.rawRiskScore}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: latest.riskColor,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text('${latest.riskLevel} FALL RISK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: latest.riskColor,
                      letterSpacing: 0.5,
                    )),
                const SizedBox(height: 4),
                Text(latest.riskSummary,
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 8),
                // STEADI recommendation
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: latest.riskColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Text(latest.steadiRecommendation,
                      style: TextStyle(
                          fontSize: 12, color: latest.riskColor),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(height: 8),
                Text('Assessed ${latest.dateString} by ${latest.assessedByName}',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textLight)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: const Text('Reassess'),
                ),
              ],
            ),
          ),
        ),

        // Missing protections
        if (latest.missingProtections.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.tileOrange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                  color: AppTheme.tileOrange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Missing Protections',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.tileOrange)),
                const SizedBox(height: 6),
                ...latest.missingProtections.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 14, color: AppTheme.tileOrange),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(s,
                                  style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],

        // History
        if (history.length > 1) ...[
          const SizedBox(height: 20),
          Text('HISTORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              )),
          const SizedBox(height: 8),
          ...history.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: a.riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text('${a.rawRiskScore}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: a.riskColor,
                          )),
                    ),
                    const SizedBox(width: 10),
                    Text(a.dateString, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text('\u2014 ${a.riskLevel}',
                        style: TextStyle(fontSize: 13, color: a.riskColor)),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  // ── Assessment form ─────────────────────────────────────────────

  Widget _buildForm() {
    // Live score preview color
    final previewColor = _liveScore <= 3
        ? AppTheme.statusGreen
        : _liveScore <= 7
            ? AppTheme.tileOrange
            : _liveScore <= 12
                ? const Color(0xFFE64A19)
                : AppTheme.statusRed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live score preview
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: previewColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Risk Score: $_liveScore',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: previewColor,
                  )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Fall History
        _sectionHeader('Fall History (weighted \u00D72)',
            color: AppTheme.statusRed),
        ..._buildToggles(_fallHistory, FallRiskAssessment.kFallHistoryLabels,
            AppTheme.statusRed),

        const SizedBox(height: 16),

        // Balance & Mobility
        _sectionHeader('Balance & Mobility'),
        ..._buildToggles(_balance, FallRiskAssessment.kBalanceLabels,
            const Color(0xFFE64A19)),

        const SizedBox(height: 16),

        // Medication Risks
        _sectionHeader('Medication Risks'),
        ..._buildToggles(_medication, FallRiskAssessment.kMedicationLabels,
            AppTheme.tileOrange),

        const SizedBox(height: 16),

        // Environmental Hazards
        _sectionHeader('Environmental Hazards'),
        ..._buildToggles(_environmental,
            FallRiskAssessment.kEnvironmentalLabels, AppTheme.tileBrown),

        const SizedBox(height: 20),

        // Protective Measures
        _sectionHeader('Protective Measures', subtitle: 'Check all in place'),
        ..._buildToggles(_protective, FallRiskAssessment.kProtectiveLabels,
            AppTheme.statusGreen),

        const SizedBox(height: 16),

        // Notes
        TextField(
          controller: _notesCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.tilePink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Complete Assessment',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _sectionHeader(String label, {String? subtitle, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: color ?? AppTheme.textSecondary,
              )),
          if (subtitle != null)
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  List<Widget> _buildToggles(
      Map<String, bool> map, Map<String, String> labels, Color activeColor) {
    return labels.entries.map((e) {
      return SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(e.value, style: const TextStyle(fontSize: 14)),
        value: map[e.key]!,
        onChanged: (v) => setState(() => map[e.key] = v),
        activeThumbColor: activeColor,
      );
    }).toList();
  }
}
