// lib/screens/skin_integrity_screen.dart
//
// Skin integrity tracker: Braden-inspired assessment + turning/repositioning
// log with time-since-last-turn indicator.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/skin_assessment.dart';
import 'package:cecelia_care_flutter/models/turning_log.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/screens/wound_tracking_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class SkinIntegrityScreen extends StatefulWidget {
  const SkinIntegrityScreen({super.key});

  @override
  State<SkinIntegrityScreen> createState() => _SkinIntegrityScreenState();
}

class _SkinIntegrityScreenState extends State<SkinIntegrityScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  late TabController _tabCtrl;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // Tick every minute for the "time since last turn" indicator.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skin Integrity'),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Assessment'),
            Tab(text: 'Turning Log'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.healing_outlined),
            tooltip: 'Wound Tracker',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WoundTrackingScreen())),
          ),
        ],
      ),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _AssessmentTab(firestore: _firestore, elderId: elderId),
                _TurningLogTab(firestore: _firestore, elderId: elderId),
              ],
            ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Assessment Tab
// ══════════════════════════════════════════════════════════════════════════════

class _AssessmentTab extends StatefulWidget {
  const _AssessmentTab({required this.firestore, required this.elderId});
  final FirestoreService firestore;
  final String elderId;

  @override
  State<_AssessmentTab> createState() => _AssessmentTabState();
}

class _AssessmentTabState extends State<_AssessmentTab> {
  bool _showForm = false;

  // Form state
  String _mobilityLevel = 'noImpairment';
  final Map<String, bool> _atRisk = {
    for (final k in SkinAssessment.kPressureSiteLabels.keys) k: false,
  };
  final Map<String, String> _conditions = {};
  int _sensory = 4, _moisture = 4, _nutrition = 4, _friction = 3;
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final data = SkinAssessment(
        elderId: widget.elderId,
        assessedBy: user.uid,
        assessedByName: user.displayName ?? user.email ?? 'Unknown',
        dateString: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        mobilityLevel: _mobilityLevel,
        atRiskSites: Map.from(_atRisk),
        siteConditions: Map.from(_conditions),
        sensoryPerception: _sensory,
        moisture: _moisture,
        nutrition: _nutrition,
        frictionShear: _friction,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ).toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await widget.firestore.addSkinAssessment(widget.elderId, data);
      HapticUtils.success();
      if (mounted) {
        setState(() => _showForm = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skin assessment saved.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Skin assessment save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.firestore.getSkinAssessmentsStream(widget.elderId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong.',
              style: TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonCard();
        }

        final assessments = (snapshot.data ?? [])
            .map((raw) =>
                SkinAssessment.fromFirestore(raw['id'] as String? ?? '', raw))
            .toList();
        final latest = assessments.isNotEmpty ? assessments.first : null;

        if (_showForm || latest == null) return _buildForm();
        return _buildResults(latest, assessments);
      },
    );
  }

  Widget _buildResults(SkinAssessment latest, List<SkinAssessment> history) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Score hero
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: 80, height: 80,
                  child: Stack(alignment: Alignment.center, children: [
                    CircularProgressIndicator(
                      value: latest.bradenScore / 19,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(latest.riskColor),
                    ),
                    Text('${latest.bradenScore}',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                            color: latest.riskColor)),
                  ]),
                ),
                const SizedBox(height: 12),
                Text('${latest.riskLevel} RISK',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: latest.riskColor, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(latest.riskSummary,
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                Text('Assessed ${latest.dateString} by ${latest.assessedByName}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _showForm = true),
                  child: const Text('Reassess'),
                ),
              ],
            ),
          ),
        ),

        // History
        if (history.length > 1) ...[
          const SizedBox(height: 20),
          Text('HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          ...history.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(children: [
                  Container(width: 28, height: 28,
                    decoration: BoxDecoration(color: a.riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    alignment: Alignment.center,
                    child: Text('${a.bradenScore}', style: TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold, color: a.riskColor))),
                  const SizedBox(width: 10),
                  Text(a.dateString, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text('\u2014 ${a.riskLevel}',
                      style: TextStyle(fontSize: 13, color: a.riskColor)),
                ]),
              )),
        ],
      ],
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mobility
        _header('Mobility Level'),
        Wrap(spacing: 6, runSpacing: 6,
          children: SkinAssessment.kMobilityLabels.entries.map((e) {
            final sel = _mobilityLevel == e.key;
            return ChoiceChip(label: Text(e.value), selected: sel,
              onSelected: (_) => setState(() => _mobilityLevel = e.key));
          }).toList()),
        const SizedBox(height: 16),

        // Pressure sites
        _header('Pressure Points at Risk'),
        ...SkinAssessment.kPressureSiteLabels.entries.map((e) =>
          SwitchListTile(
            contentPadding: EdgeInsets.zero, dense: true,
            title: Text(e.value, style: const TextStyle(fontSize: 14)),
            value: _atRisk[e.key]!,
            onChanged: (v) => setState(() {
              _atRisk[e.key] = v;
              if (!v) _conditions.remove(e.key);
              else _conditions[e.key] = 'intact';
            }),
            activeColor: AppTheme.statusAmber,
          )),
        const SizedBox(height: 16),

        // Braden sub-scores
        _header('Braden Sub-scores'),
        _scoreRow('Sensory Perception', _sensory, 4, SkinAssessment.kSensoryLabels,
            (v) => setState(() => _sensory = v)),
        _scoreRow('Moisture', _moisture, 4, SkinAssessment.kMoistureLabels,
            (v) => setState(() => _moisture = v)),
        _scoreRow('Nutrition', _nutrition, 4, SkinAssessment.kNutritionLabels,
            (v) => setState(() => _nutrition = v)),
        _scoreRow('Friction & Shear', _friction, 3, SkinAssessment.kFrictionLabels,
            (v) => setState(() => _friction = v)),
        const SizedBox(height: 16),

        TextField(controller: _notesCtrl,
          decoration: const InputDecoration(labelText: 'Notes (optional)',
              border: OutlineInputBorder()),
          maxLines: 2, textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.entryVitalAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Assessment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _header(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(), style: TextStyle(fontSize: 11,
        fontWeight: FontWeight.w600, letterSpacing: 0.8, color: AppTheme.textSecondary)));

  Widget _scoreRow(String label, int value, int max,
      Map<int, String> labels, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(children: List.generate(max, (i) {
          final score = i + 1;
          final sel = value == score;
          return Expanded(child: GestureDetector(
            onTap: () => onChanged(score),
            child: Container(
              margin: EdgeInsets.only(right: i < max - 1 ? 4 : 0),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.tileTeal.withValues(alpha: 0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: sel ? AppTheme.tileTeal : Colors.grey.shade300)),
              alignment: Alignment.center,
              child: Text('$score', style: TextStyle(fontSize: 14,
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  color: sel ? AppTheme.tileTeal : Colors.grey.shade500)),
            ),
          ));
        })),
        Text(labels[value] ?? '', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Turning Log Tab
// ══════════════════════════════════════════════════════════════════════════════

class _TurningLogTab extends StatelessWidget {
  const _TurningLogTab({required this.firestore, required this.elderId});
  final FirestoreService firestore;
  final String elderId;

  void _logTurn(BuildContext context) {
    String? selectedPos;
    bool skinCheck = false;
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Log Reposition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(spacing: 6, runSpacing: 6,
                children: TurningLog.kPositionLabels.entries.map((e) {
                  final sel = selectedPos == e.key;
                  return ChoiceChip(
                    label: Text('${TurningLog.kPositionIcons[e.key] ?? ''} ${e.value}'),
                    selected: sel,
                    onSelected: (_) => setSheetState(() => selectedPos = e.key),
                  );
                }).toList()),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Skin check done?', style: TextStyle(fontSize: 14)),
                value: skinCheck,
                onChanged: (v) => setSheetState(() => skinCheck = v),
              ),
              TextField(controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)', border: OutlineInputBorder(),
                  hintText: 'Redness observed, positioning aids used...'),
                maxLines: 2, textCapitalization: TextCapitalization.sentences),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: selectedPos == null
                    ? null
                    : () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        final data = TurningLog(
                          elderId: elderId,
                          loggedBy: user.uid,
                          loggedByName: user.displayName ?? user.email ?? 'Unknown',
                          timestamp: Timestamp.now(),
                          position: selectedPos!,
                          skinCheckDone: skinCheck,
                          skinNotes: notesCtrl.text.trim().isEmpty
                              ? null : notesCtrl.text.trim(),
                        ).toFirestore();
                        data['timestamp'] = FieldValue.serverTimestamp();
                        await firestore.addTurningLog(elderId, data);
                        HapticUtils.success();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.entryVitalAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'turningLogFab',
        onPressed: () => _logTurn(context),
        backgroundColor: AppTheme.entryVitalAccent,
        child: const Icon(Icons.rotate_left, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.getTurningLogsStream(elderId, startDate: startOfDay),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong.',
                style: TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            // _TurningLogTab is a StatelessWidget so we can't trigger a
            // local rebuild. The timeout still shows a friendly error
            // after 10s; users can refresh by switching tabs.
            return const SkeletonCard();
          }

          final logs = (snapshot.data ?? [])
              .map((raw) => TurningLog.fromFirestore(raw['id'] as String? ?? '', raw))
              .toList();

          // Time since last turn
          final timeSinceLast = logs.isNotEmpty
              ? DateTime.now().difference(logs.first.timestamp.toDate())
              : null;

          return Column(
            children: [
              // Status banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                color: timeSinceLast == null
                    ? Colors.grey.shade100
                    : timeSinceLast.inHours < 2
                        ? AppTheme.statusGreen.withValues(alpha: 0.08)
                        : timeSinceLast.inHours < 3
                            ? AppTheme.tileOrange.withValues(alpha: 0.08)
                            : AppTheme.statusRed.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 20,
                        color: timeSinceLast == null
                            ? Colors.grey
                            : timeSinceLast.inHours < 2
                                ? AppTheme.statusGreen
                                : timeSinceLast.inHours < 3
                                    ? AppTheme.tileOrange
                                    : AppTheme.statusRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        timeSinceLast == null
                            ? 'No turns logged today. Tap + to start.'
                            : 'Last repositioned ${_formatElapsed(timeSinceLast)} ago'
                              ' \u00B7 ${logs.length} turn${logs.length == 1 ? '' : 's'} today',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                            color: timeSinceLast == null ? Colors.grey
                                : timeSinceLast.inHours >= 3 ? AppTheme.statusRed
                                : null),
                      ),
                    ),
                  ],
                ),
              ),

              // Today's log list
              Expanded(
                child: logs.isEmpty
                    ? Center(child: Text('No turns logged today.',
                        style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: logs.length,
                        itemBuilder: (_, i) => _buildTurnCard(logs[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatElapsed(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m';
  }

  Widget _buildTurnCard(TurningLog log) {
    final time = DateFormat('h:mm a').format(log.timestamp.toDate());
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(log.positionIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.positionLabel,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text('$time \u00B7 by ${log.loggedByName}',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                if (log.skinNotes != null && log.skinNotes!.isNotEmpty)
                  Text(log.skinNotes!, style: TextStyle(fontSize: 12,
                      color: AppTheme.textSecondary), maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            )),
            if (log.skinCheckDone)
              const Icon(Icons.check_circle, size: 16, color: AppTheme.statusGreen),
          ],
        ),
      ),
    );
  }
}
