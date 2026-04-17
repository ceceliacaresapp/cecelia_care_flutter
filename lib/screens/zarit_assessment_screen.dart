// lib/screens/zarit_assessment_screen.dart
//
// ZBI-12 wizard — 12 questions, one per page, each answered on the
// validated 0–4 Likert scale. On save: writes to ZaritProvider,
// schedules the next monthly reminder, returns to Self Care with a
// result celebration.
//
// Design goals:
//  • Easy to pause — current progress persists via setState only;
//    closing the screen mid-flow discards, which is intentional (we
//    don't want half-completed assessments polluting the history).
//  • Pre-fills the "elder context" pill when the caregiver has a
//    single active elder.
//  • Accessible — large tap targets, clear colors, no timers.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/zarit_assessment.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/zarit_provider.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tilePurple;

class ZaritAssessmentScreen extends StatefulWidget {
  const ZaritAssessmentScreen({super.key});

  @override
  State<ZaritAssessmentScreen> createState() => _ZaritAssessmentScreenState();
}

class _ZaritAssessmentScreenState extends State<ZaritAssessmentScreen> {
  final PageController _pageCtrl = PageController();
  final _noteCtrl = TextEditingController();

  /// nullable per-item score so we can require an explicit answer (vs
  /// defaulting to 0 which is itself a valid response).
  late List<int?> _scores;
  int _page = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _scores = List<int?>.filled(kZaritItems.length, null);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  int get _answered => _scores.where((s) => s != null).length;
  bool get _allAnswered => _answered == kZaritItems.length;

  void _select(int score) {
    setState(() => _scores[_page] = score);
    HapticUtils.selection();
    // Auto-advance after a short delay so the choice is visible.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      if (_page < kZaritItems.length) {
        _pageCtrl.nextPage(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || !_allAnswered) return;
    setState(() => _isSaving = true);

    final elderProv = context.read<ActiveElderProvider>();
    final zarit = context.read<ZaritProvider>();

    final scores = _scores.map((s) => s ?? 0).toList();
    final elderId = elderProv.activeElder?.id;
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();

    final id = await zarit.saveAssessment(
      itemScores: scores,
      elderId: elderId,
      note: note,
    );

    if (!mounted) return;
    if (id == null) {
      setState(() => _isSaving = false);
      final msg = zarit.error ?? 'Could not save assessment.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }

    // Re-schedule the next monthly reminder so it's always ~30 days
    // from the last completion.
    unawaited(
      NotificationService.instance.scheduleZaritMonthlyReminder(),
    );

    HapticUtils.success();
    if (!mounted) return;
    // Pop back to self-care and let the summary card update from Firestore.
    Navigator.of(context).pop(true);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final totalPages = kZaritItems.length + 1; // +1 for summary page
    final progress = (_page + 1) / totalPages;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Burden Check-in'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: totalPages,
              itemBuilder: (ctx, i) {
                if (i == kZaritItems.length) return _buildSummaryPage();
                return _buildQuestionPage(i);
              },
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(int index) {
    final item = kZaritItems[index];
    final chosen = _scores[index];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${item.number} of ${kZaritItems.length}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: Text(
              item.domain,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _kAccent,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            item.prompt,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 26),
          for (final r in ZaritResponse.values)
            _ResponseOption(
              label: r.label,
              score: r.score,
              selected: chosen == r.score,
              onTap: () => _select(r.score),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryPage() {
    final scores = _scores.map((s) => s ?? 0).toList();
    final preview = ZaritAssessment(
      userId: '',
      itemScores: scores,
    );
    final level = preview.level;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Preview before saving',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: level.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusL),
              border:
                  Border.all(color: level.color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: level.color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.favorite, color: level.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Score: ${preview.total} / 48',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: level.color,
                            ),
                          ),
                          Text(
                            level.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: level.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  level.guidance,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _SubScore(
                      label: 'Personal strain',
                      value: preview.personalStrain,
                      max: 24,
                      color: level.color,
                    ),
                    const SizedBox(width: 10),
                    _SubScore(
                      label: 'Role strain',
                      value: preview.roleStrain,
                      max: 24,
                      color: level.color,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Optional note',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Any context you want to remember — big event this week, schedule change, etc.',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Text(
              'This tool uses the Zarit Burden Interview Short Form (ZBI-12, '
              'Bédard et al. 2001). Your answers stay private — only you '
              'can read or export them.',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final onSummary = _page == kZaritItems.length;
    final canGoBack = _page > 0;
    final canGoNext = _page < kZaritItems.length && _scores[_page] != null;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: canGoBack
                  ? () => _pageCtrl.previousPage(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeInOut,
                      )
                  : null,
              icon: const Icon(Icons.chevron_left, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            if (onSummary)
              ElevatedButton.icon(
                onPressed: _isSaving || !_allAnswered ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSaving ? 'Saving…' : 'Save assessment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: canGoNext
                    ? () => _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: Text(
                    _page == kZaritItems.length - 1 ? 'Review' : 'Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(110, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ResponseOption extends StatelessWidget {
  const _ResponseOption({
    required this.label,
    required this.score,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int score;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? _kAccent.withValues(alpha: 0.1)
                : AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: selected
                  ? _kAccent
                  : Colors.grey.shade200,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _kAccent
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _kAccent : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? _kAccent
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: _kAccent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubScore extends StatelessWidget {
  const _SubScore({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = (value / max).clamp(0.0, 1.0);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                '/ $max',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
