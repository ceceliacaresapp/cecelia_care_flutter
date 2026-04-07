// lib/screens/wandering_risk_screen.dart
//
// Structured wandering risk assessment with risk score display, safeguard
// gaps, and history tracking.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/wandering_assessment.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/timed_loading_indicator.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class WanderingRiskScreen extends StatefulWidget {
  const WanderingRiskScreen({super.key});

  @override
  State<WanderingRiskScreen> createState() => _WanderingRiskScreenState();
}

class _WanderingRiskScreenState extends State<WanderingRiskScreen> {
  final FirestoreService _firestore = FirestoreService();
  bool _showForm = false;

  // Form state
  final Map<String, bool> _riskFactors = {
    for (final k in WanderingAssessment.kRiskFactorLabels.keys) k: false,
  };
  final Map<String, bool> _safeguards = {
    for (final k in WanderingAssessment.kSafeguardLabels.keys) k: false,
  };
  final _triggersCtrl = TextEditingController();
  final _timesCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _triggersCtrl.dispose();
    _timesCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final elderId =
          context.read<ActiveElderProvider>().activeElder?.id ?? '';
      if (elderId.isEmpty) return;

      final assessment = WanderingAssessment(
        elderId: elderId,
        assessedBy: user.uid,
        assessedByName: user.displayName ?? user.email ?? 'Unknown',
        dateString: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        hasWanderedBefore: _riskFactors['hasWanderedBefore']!,
        isNewToEnvironment: _riskFactors['isNewToEnvironment']!,
        hasSundowningPattern: _riskFactors['hasSundowningPattern']!,
        hasExitSeekingBehavior: _riskFactors['hasExitSeekingBehavior']!,
        hasImpairedJudgment: _riskFactors['hasImpairedJudgment']!,
        hasMobilityToWander: _riskFactors['hasMobilityToWander']!,
        isOnNewMedication: _riskFactors['isOnNewMedication']!,
        hasRecentDecline: _riskFactors['hasRecentDecline']!,
        hasIdBracelet: _safeguards['hasIdBracelet']!,
        hasSecuredExits: _safeguards['hasSecuredExits']!,
        hasNeighborAlert: _safeguards['hasNeighborAlert']!,
        hasSafeReturnEnrolled: _safeguards['hasSafeReturnEnrolled']!,
        hasRecentPhoto: _safeguards['hasRecentPhoto']!,
        knownTriggers: _triggersCtrl.text.trim().isEmpty
            ? null
            : _triggersCtrl.text.trim(),
        peakRiskTimes: _timesCtrl.text.trim().isEmpty
            ? null
            : _timesCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty
            ? null
            : _notesCtrl.text.trim(),
      );

      final data = assessment.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.addWanderingAssessment(elderId, data);
      HapticUtils.success();

      if (mounted) {
        setState(() => _showForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Assessment saved.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Wandering assessment save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Wandering Risk Assessment')),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestore.getWanderingAssessmentsStream(elderId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return TimedLoadingIndicator(
                    onRetry: () => setState(() {}),
                  );
                }

                final assessments = (snapshot.data ?? [])
                    .map((raw) => WanderingAssessment.fromFirestore(
                        raw['id'] as String? ?? '', raw))
                    .toList();

                final latest =
                    assessments.isNotEmpty ? assessments.first : null;

                if (_showForm || latest == null) {
                  return _buildForm();
                }
                return _buildResults(latest, assessments);
              },
            ),
    );
  }

  // ── Results view ────────────────────────────────────────────────

  Widget _buildResults(
      WanderingAssessment latest, List<WanderingAssessment> history) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Risk score hero
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Score ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: latest.rawRiskScore / 10,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            latest.riskColor),
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
                Text('${latest.riskLevel} RISK',
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

        // Missing safeguards alert
        if (latest.missingSafeguards.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Missing Safeguards',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF57C00))),
                const SizedBox(height: 6),
                ...latest.missingSafeguards.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              size: 14, color: Color(0xFFF57C00)),
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
                    Text(a.dateString,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 6),
                    Text('\u2014 ${a.riskLevel}',
                        style: TextStyle(
                            fontSize: 13, color: a.riskColor)),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  // ── Assessment form ─────────────────────────────────────────────

  Widget _buildForm() {
    final riskCount =
        _riskFactors.values.where((v) => v).length;
    final safeguardCount =
        _safeguards.values.where((v) => v).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Risk factors
        Text('RISK FACTORS ($riskCount of 8)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
            )),
        const SizedBox(height: 4),
        const Text('Check all that apply',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        ...WanderingAssessment.kRiskFactorLabels.entries.map((e) =>
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value, style: const TextStyle(fontSize: 14)),
              value: _riskFactors[e.key]!,
              onChanged: (v) =>
                  setState(() => _riskFactors[e.key] = v),
              activeColor: const Color(0xFFE53935),
            )),

        const SizedBox(height: 20),

        // Safeguards
        Text('SAFEGUARDS IN PLACE ($safeguardCount of 5)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppTheme.textSecondary,
            )),
        const SizedBox(height: 4),
        const Text('Check all safeguards currently active',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        ...WanderingAssessment.kSafeguardLabels.entries.map((e) =>
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(e.value, style: const TextStyle(fontSize: 14)),
              value: _safeguards[e.key]!,
              onChanged: (v) =>
                  setState(() => _safeguards[e.key] = v),
              activeColor: const Color(0xFF43A047),
            )),

        const SizedBox(height: 20),

        // Details
        TextField(
          controller: _triggersCtrl,
          decoration: const InputDecoration(
            labelText: 'Known triggers (optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g., Asks for deceased mother...',
          ),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _timesCtrl,
          decoration: const InputDecoration(
            labelText: 'Peak risk times (optional)',
            border: OutlineInputBorder(),
            hintText: 'e.g., 3-6 PM, early morning',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 12),
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
            backgroundColor: const Color(0xFFD84315),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Complete Assessment',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
