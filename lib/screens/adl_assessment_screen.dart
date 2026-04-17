// lib/screens/adl_assessment_screen.dart
//
// Combined ADL assessment form + history trend. Uses the Katz ADL Index
// (6 dimensions, each 0–2, total 0–12).
import 'package:cecelia_care_flutter/utils/save_helpers.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/adl_assessment.dart';
import 'package:cecelia_care_flutter/providers/adl_provider.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/timed_loading_indicator.dart';

class AdlAssessmentScreen extends StatefulWidget {
  const AdlAssessmentScreen({super.key});

  @override
  State<AdlAssessmentScreen> createState() => _AdlAssessmentScreenState();
}

class _AdlAssessmentScreenState extends State<AdlAssessmentScreen> {
  // One score per dimension: null = not yet selected.
  final Map<String, int?> _scores = {
    for (final d in AdlAssessment.kDimensions) d: null,
  };
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isEditing = false;

  bool get _canSave => _scores.values.every((v) => v != null);

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      await context.read<AdlProvider>().saveAssessment(
            bathing: _scores['Bathing']!,
            dressing: _scores['Dressing']!,
            eating: _scores['Eating']!,
            toileting: _scores['Toileting']!,
            transferring: _scores['Transferring']!,
            continence: _scores['Continence']!,
            notes: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ADL assessment saved.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('ADL save error: $e');
      if (mounted) showSaveError(context, e, label: 'ADL');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _prepopulateFromExisting(AdlAssessment a) {
    _scores['Bathing'] = a.bathing;
    _scores['Dressing'] = a.dressing;
    _scores['Eating'] = a.eating;
    _scores['Toileting'] = a.toileting;
    _scores['Transferring'] = a.transferring;
    _scores['Continence'] = a.continence;
    _noteCtrl.text = a.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final adl = context.watch<AdlProvider>();
    final elderName =
        context.watch<ActiveElderProvider>().activeElder?.profileName ?? '';
    final weekLabel = AdlProvider.weekLabel(AdlProvider.currentWeekString());

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADL Assessment'),
      ),
      body: adl.isLoading
          ? const TimedLoadingIndicator()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Header ───────────────────────────────────────
                Text(
                  elderName.isNotEmpty
                      ? 'Weekly ADL Assessment for $elderName'
                      : 'Weekly ADL Assessment',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(weekLabel,
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textSecondary)),
                const SizedBox(height: 16),

                // ── Form or summary ──────────────────────────────
                if (adl.currentWeek != null && !_isEditing)
                  _buildSummary(adl.currentWeek!)
                else
                  _buildForm(adl.currentWeek),

                const SizedBox(height: 24),

                // ── History trend ────────────────────────────────
                if (adl.history.isNotEmpty) ...[
                  const Text('TREND',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      )),
                  const SizedBox(height: 12),
                  _buildTrendChart(adl),
                  const SizedBox(height: 16),
                  ...adl.history.map(_buildHistoryCard),
                ] else if (adl.currentWeek == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      'Complete your first assessment above to start tracking ADL independence over time.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }

  // ── Summary card (already assessed this week) ───────────────────

  Widget _buildSummary(AdlAssessment a) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: a.scorePercent),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(a.scoreColor),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: a.totalScore.toDouble()),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (_, v, __) => Text('${v.toInt()}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: a.scoreColor,
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${a.totalScore}/12',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(a.scoreLabel,
                          style: TextStyle(
                              fontSize: 14, color: a.scoreColor)),
                      Text('Assessed by ${a.assessedByName}',
                          style: TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dimension dots
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: AdlAssessment.kDimensions.map((d) {
                final score = a.dimensionMap[d] ?? 0;
                return Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AdlAssessment.kScoreColors[score],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(d.substring(0, 3),
                        style: const TextStyle(fontSize: 9)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                _prepopulateFromExisting(a);
                setState(() => _isEditing = true);
              },
              child: const Text('Update Assessment'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Assessment form ─────────────────────────────────────────────

  Widget _buildForm(AdlAssessment? existing) {
    // Prepopulate on first entry into edit mode if updating.
    if (existing != null && !_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prepopulateFromExisting(existing);
        setState(() => _isEditing = true);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...AdlAssessment.kDimensions.map(_buildDimensionCard),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
            hintText: 'Any changes this week...',
          ),
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _canSave && !_isSaving ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.tileBlueDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Assessment',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildDimensionCard(String dimension) {
    final description =
        AdlAssessment.kDimensionDescriptions[dimension] ?? '';
    final selected = _scores[dimension];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dimension,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 10),
                child: Text(description,
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary)),
              ),
            Row(
              children: [0, 1, 2].map((score) {
                final isSelected = selected == score;
                final color = AdlAssessment.kScoreColors[score];
                final label = AdlAssessment.kScoreLabels[score]!;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _scores[dimension] = score),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(
                          right: score < 2 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        border: Border.all(
                          color: isSelected ? color : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? color
                                : Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Trend chart (bar-based, no chart library) ───────────────────

  Widget _buildTrendChart(AdlProvider adl) {
    final trend = adl.scoreTrend;
    if (trend.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: trend.asMap().entries.map((e) {
          final idx = e.key;
          final score = e.value;
          final fraction = score / 12;
          final assessment = adl.history.reversed.toList()[idx];
          final color = assessment.scoreColor;
          final weekNum = assessment.weekString.split('-W').last;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${score.toInt()}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  const SizedBox(height: 2),
                  Container(
                    height: 80 * fraction,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('W$weekNum',
                      style: const TextStyle(fontSize: 9)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── History cards ───────────────────────────────────────────────

  Widget _buildHistoryCard(AdlAssessment a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusS)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: a.scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              alignment: Alignment.center,
              child: Text('${a.totalScore}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: a.scoreColor,
                  )),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AdlProvider.weekLabel(a.weekString),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(
                    '${a.scoreLabel} \u00B7 By ${a.assessedByName}',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            // Dimension dots
            Row(
              children: AdlAssessment.kDimensions.map((d) {
                final score = a.dimensionMap[d] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(left: 3),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AdlAssessment.kScoreColors[score],
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
