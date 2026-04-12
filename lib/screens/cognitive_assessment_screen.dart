// lib/screens/cognitive_assessment_screen.dart
//
// Cognitive screening hub: shows past results in a gauge + radar + trend
// view, and runs an interactive 10-page wizard for new assessments.
// Tests are based on validated clinical instruments (Mini-Cog, SLUMS,
// Trail Making, MoCA components, MMSE orientation).

import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/cognitive_assessment.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/cognitive_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/cognitive_test_games.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';

class CognitiveAssessmentScreen extends StatelessWidget {
  const CognitiveAssessmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<CognitiveProvider>();
    final elder = context.watch<ActiveElderProvider>().activeElder;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cognitive Screen')),
        body: const Center(child: Text('No care recipient selected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cognitive Screen'),
        backgroundColor: AppTheme.entryMoodAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.entryMoodAccent,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const _AssessmentWizard(),
        )),
        icon: const Icon(Icons.psychology_alt_outlined),
        label: Text(prov.history.isEmpty
            ? 'Start First Assessment'
            : 'New Assessment'),
      ),
      body: prov.isLoading
          ? const SkeletonCard(height: 200)
          : prov.history.isEmpty
              ? _emptyState(context)
              : _resultsView(context, prov),
    );
  }

  Widget _emptyState(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.psychology_alt_outlined,
      title: 'No assessments yet',
      subtitle: '7 brain games — about 10–15 minutes.\nTracks memory, attention, and executive function over time.',
      color: Color(0xFF7B1FA2),
    );
  }

  Widget _resultsView(BuildContext context, CognitiveProvider prov) {
    final latest = prov.latest!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _heroCard(latest),
        const SizedBox(height: 16),
        _domainBreakdown(latest),
        const SizedBox(height: 16),
        if (prov.scoreTrend.length >= 2) _trendChart(prov.scoreTrend),
        const SizedBox(height: 16),
        _historyList(prov.history),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Educational screening only — not a clinical diagnosis. Always follow up with a doctor for cognitive concerns.',
            style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _heroCard(CognitiveAssessment a) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            a.levelColor.withValues(alpha: 0.18),
            a.levelColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: a.levelColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: a.scorePercent),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (_, v, __) => SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 9,
                      backgroundColor: Colors.white,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(a.levelColor),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: a.totalScore.toDouble()),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => Text('${v.toInt()}',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: a.levelColor,
                          )),
                    ),
                    Text('/ ${a.maxPossibleScore}',
                        style: TextStyle(
                            fontSize: 11,
                            color: a.levelColor.withValues(alpha: 0.8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.cognitiveLevel,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: a.levelColor,
                    )),
                const SizedBox(height: 4),
                Text(
                  a.createdAt != null
                      ? 'Assessed ${DateFormat('MMM d, yyyy').format(a.createdAt!.toDate())}'
                      : a.monthString,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary),
                ),
                Text('by ${a.assessedByName}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                if (a.weakestDomain != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: a.levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Weakest: ${a.weakestDomain}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: a.levelColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _domainBreakdown(CognitiveAssessment a) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Domain breakdown',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ...a.domainScores.entries.map((e) {
              final pct = e.value;
              final max = CognitiveAssessment.kDomainMax[e.key] ?? 5;
              final raw = pct == null ? null : (pct * max).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                        Text(
                          pct == null ? 'Skipped' : '$raw / $max',
                          style: TextStyle(
                              fontSize: 11,
                              color: pct == null
                                  ? AppTheme.textLight
                                  : AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct ?? 0,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pct == null
                              ? Colors.grey.shade400
                              : (pct >= 0.8
                                  ? AppTheme.statusGreen
                                  : pct >= 0.6
                                      ? AppTheme.tileBlue
                                      : pct >= 0.4
                                          ? AppTheme.tileOrange
                                          : AppTheme.statusRed),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _trendChart(List<double> scores) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Trend',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                Text('${scores.length} assessments',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: Size.infinite,
                painter: _TrendLinePainter(scores),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyList(List<CognitiveAssessment> history) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('History',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...history.map((a) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: a.levelColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.createdAt != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(a.createdAt!.toDate())
                              : a.monthString,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text('${a.totalScore}/${a.maxPossibleScore}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: a.levelColor)),
                      const SizedBox(width: 8),
                      Text(a.cognitiveLevel,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(max);
    final minV = values.reduce(min);
    final range = (maxV - minV).clamp(1.0, double.infinity);
    final paint = Paint()
      ..color = AppTheme.entryMoodAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final fillPaint = Paint()
      ..color = AppTheme.entryMoodAccent.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final dotPaint = Paint()..color = AppTheme.entryMoodAccent;

    final path = Path();
    final fillPath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height -
          ((values[i] - minV) / range) * (size.height - 12) -
          6;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.values != values;
}

// ─────────────────────────────────────────────────────────────
// Assessment wizard
// ─────────────────────────────────────────────────────────────

class _AssessmentWizard extends StatefulWidget {
  const _AssessmentWizard();

  @override
  State<_AssessmentWizard> createState() => _AssessmentWizardState();
}

class _AssessmentWizardState extends State<_AssessmentWizard> {
  static const Color _accent = AppTheme.entryMoodAccent;
  static const int _totalPages = 10;

  static const List<String> _wordPool = [
    'APPLE', 'TABLE', 'PENNY', 'GARDEN', 'ELBOW',
    'RIVER', 'CANDLE', 'PILLOW', 'FOREST', 'MIRROR',
    'BUTTON', 'WAGON', 'GLOVE', 'SUNSET', 'BANJO',
    'KETTLE', 'MARBLE', 'OCEAN', 'POCKET', 'SADDLE',
  ];

  static const List<String> _fluencyCategories = [
    'animals',
    'fruits',
    'tools',
    'pieces of clothing',
  ];

  final PageController _pc = PageController();
  int _page = 0;
  final _rng = Random();

  // Test state.
  late List<String> _wordsShown;
  int _wordRecallIdx = -1; // -1 = not started; 0..n = displaying word
  final Set<String> _recalledWords = {};
  final GlobalKey<ClockDrawingCanvasState> _clockKey = GlobalKey();
  final Map<String, bool> _clockRubric = {
    'circle': false,
    'numbers': false,
    'positions': false,
    'hands': false,
  };
  TrailMakingResult? _trailResult;
  DigitSpanResult? _digitResult;
  late String _fluencyCategory;
  int? _fluencyCount;
  final Map<String, bool> _orientation = {};
  int? _patternCorrect;

  // Notes.
  final TextEditingController _notesCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final pool = [..._wordPool]..shuffle(_rng);
    _wordsShown = pool.take(5).toList();
    _fluencyCategory =
        _fluencyCategories[_rng.nextInt(_fluencyCategories.length)];
  }

  @override
  void dispose() {
    _pc.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _pc.nextPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut);
    }
  }

  void _prev() {
    if (_page > 0) {
      _pc.previousPage(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut);
    }
  }

  // ── Score helpers ───────────────────────────────────────────
  int _wordRecallScore() => _recalledWords.length;
  int _clockScore() =>
      _clockRubric.values.where((v) => v).length;
  int _fluencyScore() {
    final c = _fluencyCount ?? -1;
    if (c < 0) return 0;
    if (c <= 1) return 0;
    if (c <= 5) return 1;
    if (c <= 10) return 2;
    if (c <= 15) return 3;
    if (c <= 20) return 4;
    return 5;
  }
  int _orientationScore() =>
      _orientation.values.where((v) => v).length;

  Future<void> _saveAndExit() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final elder = context.read<ActiveElderProvider>().activeElder;
      if (user == null || elder == null) return;

      final assessment = CognitiveAssessment(
        elderId: elder.id,
        assessedBy: user.uid,
        assessedByName: user.displayName ?? user.email ?? 'Unknown',
        monthString: CognitiveProvider.currentMonthString(),
        wordRecallScore: _wordRecallScore(),
        clockDrawingScore: _clockScore(),
        trailMakingScore: _trailResult?.score,
        digitSpanScore: _digitResult?.score,
        categoryFluencyScore: _fluencyCount == null ? null : _fluencyScore(),
        orientationScore: _orientation.isEmpty ? null : _orientationScore(),
        patternSequenceScore: _patternCorrect,
        wordsShown: _wordsShown,
        wordsRecalled: _recalledWords.toList(),
        trailMakingTimeSeconds: _trailResult?.seconds,
        trailMakingErrors: _trailResult?.errors,
        digitSpanMaxForward: _digitResult?.maxForward,
        digitSpanMaxBackward: _digitResult?.maxBackward,
        categoryFluencyCount: _fluencyCount,
        categoryFluencyCategory: _fluencyCategory,
        orientationAnswers: Map<String, bool>.from(_orientation),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      await context.read<CognitiveProvider>().saveAssessment(assessment);
      HapticUtils.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Assessment saved'),
              backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text('Step ${_page + 1} of $_totalPages'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () async {
            final navigator = Navigator.of(context);
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Exit assessment?'),
                content: const Text('Progress will be lost.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Stay')),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Exit')),
                ],
              ),
            );
            if (ok == true) navigator.pop();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_page + 1) / _totalPages,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: PageView(
        controller: _pc,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (i) => setState(() => _page = i),
        children: [
          _pageWelcome(),
          _pageMemorize(),
          _pageClock(),
          _pageTrail(),
          _pageDigitSpan(),
          _pageFluency(),
          _pageRecall(),
          _pageOrientation(),
          _pagePattern(),
          _pageResults(),
        ],
      ),
      bottomNavigationBar: _page == _totalPages - 1 || _page == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (_page > 0)
                      OutlinedButton.icon(
                        onPressed: _prev,
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _next,
                      child: const Text('Skip'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Page 0: Welcome ─────────────────────────────────────────
  Widget _pageWelcome() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.psychology_alt_outlined,
              size: 96, color: _accent),
          const SizedBox(height: 16),
          const Text(
            "Let's do some brain exercises!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'This takes about 10–15 minutes. Sit together with the care recipient — you facilitate, they participate. You can skip any section.',
            style: TextStyle(fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _next,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 16),
              textStyle: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Let's Begin"),
          ),
        ],
      ),
    );
  }

  // ── Page 1: Memorize words ──────────────────────────────────
  Widget _pageMemorize() {
    return StatefulBuilder(builder: (ctx, setLocal) {
      void show(int i) {
        setLocal(() => _wordRecallIdx = i);
        if (i < _wordsShown.length - 1) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) show(i + 1);
          });
        }
      }

      if (_wordRecallIdx == -1) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Memory: Word List',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text(
                'Read these 5 words OUT LOUD to the care recipient and ask them to remember them. We will test recall after the other exercises.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => show(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 16),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start word list'),
              ),
            ],
          ),
        );
      }
      final showingDone = _wordRecallIdx >= _wordsShown.length;
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_wordsShown.length, (i) {
                final active = i <= _wordRecallIdx;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: active ? _accent : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: showingDone
                  ? const Text(
                      'All read!',
                      key: ValueKey('done'),
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.w700),
                    )
                  : Text(
                      _wordsShown[_wordRecallIdx],
                      key: ValueKey(_wordRecallIdx),
                      style: const TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.w900,
                        color: _accent,
                        letterSpacing: 4,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            if (showingDone)
              ElevatedButton.icon(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text("I've read them all"),
              ),
          ],
        ),
      );
    });
  }

  // ── Page 2: Clock drawing ───────────────────────────────────
  Widget _pageClock() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Visuospatial: Clock Drawing',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Ask: "Please draw a clock showing 10 minutes past 11."',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClockDrawingCanvas(key: _clockKey),
          ),
          const SizedBox(height: 8),
          const Text('Caregiver scoring',
              style:
                  TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ..._clockRubric.entries.map((e) {
            final labels = {
              'circle': 'Circle roughly correct?',
              'numbers': 'All 12 numbers present?',
              'positions': 'Numbers in correct positions?',
              'hands': 'Hands showing correct time?',
            };
            return CheckboxListTile(
              dense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4),
              activeColor: _accent,
              value: e.value,
              title: Text(labels[e.key] ?? '',
                  style: const TextStyle(fontSize: 12)),
              onChanged: (v) =>
                  setState(() => _clockRubric[e.key] = v ?? false),
            );
          }),
        ],
      ),
    );
  }

  // ── Page 3: Trail Making ────────────────────────────────────
  Widget _pageTrail() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text('Attention: Trail Making',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Text(
            'Tap the numbered circles in order, 1 through 15, as fast as you can.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TrailMakingGame(
              onComplete: (r) {
                setState(() => _trailResult = r);
                Future.delayed(const Duration(milliseconds: 300), _next);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 4: Digit Span ──────────────────────────────────────
  Widget _pageDigitSpan() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Working Memory: Digit Span',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Text(
            'Read each number out loud as it appears, then ask the recipient to repeat.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DigitSpanGame(onComplete: (r) {
              setState(() => _digitResult = r);
              Future.delayed(const Duration(milliseconds: 300), _next);
            }),
          ),
        ],
      ),
    );
  }

  // ── Page 5: Category Fluency ───────────────────────────────
  Widget _pageFluency() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Language: Category Fluency',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Tap "+" for each valid answer the recipient names.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: CategoryFluencyTimer(
              category: _fluencyCategory,
              onComplete: (count) {
                setState(() => _fluencyCount = count);
                Future.delayed(const Duration(seconds: 1), _next);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 6: Delayed Recall ──────────────────────────────────
  Widget _pageRecall() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('Memory: Delayed Word Recall',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
            'Ask: "What were the 5 words I showed you earlier?" Tap each word the recipient correctly recalls.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: _wordsShown.map((w) {
              final selected = _recalledWords.contains(w);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _recalledWords.remove(w);
                    } else {
                      _recalledWords.add(w);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? _accent.withValues(alpha: 0.18)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _accent : Colors.grey.shade300,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 18,
                        color: selected ? _accent : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(w,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? _accent
                                : Colors.grey.shade700,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text('${_recalledWords.length} of ${_wordsShown.length} recalled',
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  // ── Page 7: Orientation ─────────────────────────────────────
  Widget _pageOrientation() {
    final now = DateTime.now();
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final questions = [
      {'id': 'year', 'q': 'What year is it?', 'a': '${now.year}'},
      {'id': 'month', 'q': 'What month is it?', 'a': months[now.month - 1]},
      {'id': 'day', 'q': 'What day of the week?', 'a': days[now.weekday - 1]},
      {'id': 'place', 'q': 'What is this place?', 'a': '(judge)'},
      {'id': 'city', 'q': 'What city are we in?', 'a': '(judge)'},
      {
        'id': 'president',
        'q': 'Who is the current president?',
        'a': '(judge)'
      },
    ];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Orientation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text(
          'Ask each question and tap whether they answered correctly.',
          style: TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        ...questions.map((q) {
          final id = q['id']!;
          final ans = _orientation[id];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(q['q']!,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text('Correct: ${q['a']}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cancel,
                      color: ans == false
                          ? AppTheme.dangerColor
                          : Colors.grey.shade400,
                    ),
                    onPressed: () => setState(() => _orientation[id] = false),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.check_circle,
                      color: ans == true
                          ? AppTheme.statusGreen
                          : Colors.grey.shade400,
                    ),
                    onPressed: () => setState(() => _orientation[id] = true),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Page 8: Pattern Sequence ────────────────────────────────
  Widget _pagePattern() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Executive: Pattern Sequence',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Ask: "What comes next in the pattern?"',
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: PatternSequenceGame(
              onComplete: (correct) {
                setState(() => _patternCorrect = correct);
                Future.delayed(const Duration(milliseconds: 300), _next);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Page 9: Results ─────────────────────────────────────────
  Widget _pageResults() {
    final preview = CognitiveAssessment(
      elderId: '',
      assessedBy: '',
      assessedByName: '',
      monthString: CognitiveProvider.currentMonthString(),
      wordRecallScore: _wordRecallScore(),
      clockDrawingScore: _clockScore(),
      trailMakingScore: _trailResult?.score,
      digitSpanScore: _digitResult?.score,
      categoryFluencyScore: _fluencyCount == null ? null : _fluencyScore(),
      orientationScore: _orientation.isEmpty ? null : _orientationScore(),
      patternSequenceScore: _patternCorrect,
    );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: preview.scorePercent),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (_, v, __) => SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(preview.levelColor),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(
                          begin: 0,
                          end: preview.totalScore.toDouble()),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (_, v, __) => Text('${v.toInt()}',
                          style: TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: preview.levelColor)),
                    ),
                    Text('/ ${preview.maxPossibleScore}',
                        style: TextStyle(
                            fontSize: 13,
                            color: preview.levelColor
                                .withValues(alpha: 0.8))),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(preview.cognitiveLevel,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: preview.levelColor,
              )),
        ),
        Divider(height: 32, thickness: 0.5,
            color: AppTheme.textLight.withValues(alpha: 0.3)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Domain breakdown',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...preview.domainScores.entries.map((e) {
                  final pct = e.value;
                  final max = CognitiveAssessment.kDomainMax[e.key] ?? 5;
                  final raw = pct == null ? null : (pct * max).round();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 110,
                            child: Text(e.key,
                                style: const TextStyle(fontSize: 12))),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct ?? 0,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct == null
                                    ? Colors.grey
                                    : preview.levelColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 38,
                          child: Text(
                            pct == null ? '—' : '$raw/$max',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        if (preview.weakestDomain != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: preview.levelColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: preview.levelColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates_outlined,
                    color: preview.levelColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weakest: ${preview.weakestDomain}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: preview.levelColor)),
                      const SizedBox(height: 2),
                      Text(
                        CognitiveAssessment.kDomainDescriptions[
                                preview.weakestDomain] ??
                            '',
                        style: const TextStyle(
                            fontSize: 11, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        Divider(height: 32, thickness: 0.5,
            color: AppTheme.textLight.withValues(alpha: 0.3)),
        TextField(
          controller: _notesCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            border: OutlineInputBorder(),
            hintText: 'Anything to remember about this session...',
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: _saving ? null : _saveAndExit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save_outlined),
          label: const Text('Save Assessment'),
        ),
      ],
    );
  }
}
