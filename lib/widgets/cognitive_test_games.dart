// lib/widgets/cognitive_test_games.dart
//
// Self-contained interactive game widgets for the Cognitive Assessment
// screener. Each widget manages its own animation/timer state and exposes
// an onComplete callback that emits a structured result.
//
//   • ClockDrawingCanvas — finger-drawing canvas with stroke recording
//   • TrailMakingGame — tap numbered circles in order, line drawing
//   • DigitSpanGame — animated digit display, forward/backward modes
//   • CategoryFluencyTimer — 60-second countdown ring + tap counter
//   • PatternSequenceGame — multiple-choice next-shape game
//
// All widgets are intentionally calm and large for elderly users. Touch
// targets are >= 48px and animations are slow enough to follow.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

// ─────────────────────────────────────────────────────────────
// Result classes
// ─────────────────────────────────────────────────────────────

class TrailMakingResult {
  final bool completed;
  final int seconds;
  final int errors;
  final int reached;
  final int score;
  const TrailMakingResult({
    required this.completed,
    required this.seconds,
    required this.errors,
    required this.reached,
    required this.score,
  });
}

class DigitSpanResult {
  final int maxForward;
  final int maxBackward;
  final int score;
  const DigitSpanResult({
    required this.maxForward,
    required this.maxBackward,
    required this.score,
  });
}

// ─────────────────────────────────────────────────────────────
// Clock Drawing Canvas
// ─────────────────────────────────────────────────────────────

class ClockDrawingCanvas extends StatefulWidget {
  const ClockDrawingCanvas({super.key, this.onChanged});

  /// Fires whenever a stroke is added so the parent can know if anything
  /// has been drawn (used to gate the "score" buttons).
  final ValueChanged<List<List<Offset>>>? onChanged;

  @override
  State<ClockDrawingCanvas> createState() => ClockDrawingCanvasState();
}

class ClockDrawingCanvasState extends State<ClockDrawingCanvas> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];

  List<List<Offset>> get strokes => _strokes;
  bool get isEmpty => _strokes.isEmpty;

  void clear() {
    setState(() {
      _strokes.clear();
      _current = [];
    });
    widget.onChanged?.call(_strokes);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            GestureDetector(
              onPanStart: (d) {
                _current = [d.localPosition];
                _strokes.add(_current);
                setState(() {});
              },
              onPanUpdate: (d) {
                setState(() => _current.add(d.localPosition));
              },
              onPanEnd: (_) {
                _current = [];
                widget.onChanged?.call(_strokes);
              },
              child: CustomPaint(
                painter: _ClockPainter(_strokes),
                size: Size.infinite,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Clear',
                onPressed: clear,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.strokes);
  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A237E)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) {
        if (stroke.isNotEmpty) {
          canvas.drawCircle(stroke.first, 1.5, paint..style = PaintingStyle.fill);
          paint.style = PaintingStyle.stroke;
        }
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      oldDelegate.strokes != strokes;
}

// ─────────────────────────────────────────────────────────────
// Trail Making Game
// ─────────────────────────────────────────────────────────────

class TrailMakingGame extends StatefulWidget {
  const TrailMakingGame({
    super.key,
    required this.onComplete,
    this.totalTargets = 15,
  });

  final void Function(TrailMakingResult) onComplete;
  final int totalTargets;

  @override
  State<TrailMakingGame> createState() => _TrailMakingGameState();
}

class _TrailMakingGameState extends State<TrailMakingGame> {
  late final List<_TrailPoint> _points;
  int _next = 1;
  int _errors = 0;
  int _flashIdx = -1;
  Timer? _timer;
  Timer? _flashTimer;
  int _seconds = 0;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _generatePoints();
  }

  void _generatePoints() {
    // Generate non-overlapping random positions inside the play area.
    // Coordinates are stored as 0..1 fractions of width/height.
    final rng = Random();
    final pts = <_TrailPoint>[];
    int attempts = 0;
    while (pts.length < widget.totalTargets && attempts < 5000) {
      attempts++;
      final x = 0.08 + rng.nextDouble() * 0.84;
      final y = 0.08 + rng.nextDouble() * 0.84;
      bool ok = true;
      for (final p in pts) {
        final dx = p.x - x;
        final dy = p.y - y;
        if (dx * dx + dy * dy < 0.022) {
          ok = false;
          break;
        }
      }
      if (ok) pts.add(_TrailPoint(pts.length + 1, x, y));
    }
    _points = pts;
  }

  void _start() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
    setState(() {});
  }

  void _onTap(int number, int idx) {
    if (_done) return;
    if (!_started) _start();
    if (number == _next) {
      HapticUtils.warning();
      setState(() {
        _points[idx].reached = true;
        _next++;
        if (_next > widget.totalTargets) {
          _finish(true);
        }
      });
    } else {
      _errors++;
      _flashIdx = idx;
      HapticFeedback.heavyImpact();
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _flashIdx = -1);
      });
      setState(() {});
    }
  }

  void _finish(bool completed) {
    _done = true;
    _timer?.cancel();
    final reached = _next - 1;
    int score;
    if (completed) {
      // Time + error scoring
      if (_seconds <= 30 && _errors == 0) {
        score = 5;
      } else if (_seconds <= 45 && _errors <= 1) {
        score = 4;
      } else if (_seconds <= 60 && _errors <= 2) {
        score = 3;
      } else if (_seconds <= 90) {
        score = 2;
      } else {
        score = 1;
      }
    } else {
      // Partial credit by reach
      final pct = reached / widget.totalTargets;
      if (pct >= 0.8) {
        score = 3;
      } else if (pct >= 0.5) {
        score = 2;
      } else if (pct >= 0.25) {
        score = 1;
      } else {
        score = 0;
      }
    }
    HapticUtils.success();
    widget.onComplete(TrailMakingResult(
      completed: completed,
      seconds: _seconds,
      errors: _errors,
      reached: reached,
      score: score,
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.indigo.shade700),
              const SizedBox(width: 6),
              Text('${_seconds}s',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.indigo.shade700,
                  )),
              const SizedBox(width: 18),
              Icon(Icons.error_outline, color: AppTheme.dangerColor),
              const SizedBox(width: 4),
              Text('$_errors',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.dangerColor,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade700,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Next: $_next',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (ctx, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            return Stack(
              children: [
                // Connector lines between reached points
                CustomPaint(
                  size: Size(w, h),
                  painter: _TrailLinesPainter(
                    points: _points,
                    reachedCount: _next - 1,
                    width: w,
                    height: h,
                  ),
                ),
                // Circle targets
                for (int i = 0; i < _points.length; i++)
                  Positioned(
                    left: _points[i].x * w - 26,
                    top: _points[i].y * h - 26,
                    child: GestureDetector(
                      onTap: () => _onTap(_points[i].number, i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _points[i].reached
                              ? Colors.indigo
                              : (_flashIdx == i
                                  ? AppTheme.dangerColor
                                  : Colors.white),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _points[i].reached
                                ? Colors.indigo.shade900
                                : Colors.indigo,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2)),
                          ],
                        ),
                        child: Text(
                          '${_points[i].number}',
                          style: TextStyle(
                            color: _points[i].reached
                                ? Colors.white
                                : (_flashIdx == i
                                    ? Colors.white
                                    : Colors.indigo.shade900),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _finish(false),
                  child: const Text('Stop'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrailPoint {
  final int number;
  final double x;
  final double y;
  bool reached = false;
  _TrailPoint(this.number, this.x, this.y);
}

class _TrailLinesPainter extends CustomPainter {
  _TrailLinesPainter({
    required this.points,
    required this.reachedCount,
    required this.width,
    required this.height,
  });
  final List<_TrailPoint> points;
  final int reachedCount;
  final double width;
  final double height;

  @override
  void paint(Canvas canvas, Size size) {
    final reached = points.where((p) => p.reached).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    if (reached.length < 2) return;
    final paint = Paint()
      ..color = Colors.indigo.shade400
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(reached.first.x * width, reached.first.y * height);
    for (int i = 1; i < reached.length; i++) {
      path.lineTo(reached[i].x * width, reached[i].y * height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailLinesPainter oldDelegate) =>
      oldDelegate.reachedCount != reachedCount ||
      oldDelegate.width != width ||
      oldDelegate.height != height;
}

// ─────────────────────────────────────────────────────────────
// Digit Span Game
// ─────────────────────────────────────────────────────────────

class DigitSpanGame extends StatefulWidget {
  const DigitSpanGame({super.key, required this.onComplete});
  final void Function(DigitSpanResult) onComplete;

  @override
  State<DigitSpanGame> createState() => _DigitSpanGameState();
}

class _DigitSpanGameState extends State<DigitSpanGame> {
  // Two phases: forward (caps at length 7) then backward (caps at length 6).
  bool _backwardPhase = false;
  int _length = 3;
  int _attempts = 0; // attempts at the current length
  int _maxForward = 0;
  int _maxBackward = 0;

  List<int> _sequence = [];
  int _displayIdx = -1; // -1 = not displaying, 0..n = current position
  bool _showAnswer = false;
  Timer? _displayTimer;
  final _rng = Random();

  static const int _maxForwardLength = 7;
  static const int _maxBackwardLength = 6;

  void _newSequence() {
    _sequence = List.generate(_length, (_) => _rng.nextInt(10));
    _showAnswer = false;
    _displayIdx = 0;
    _displayTimer?.cancel();
    setState(() {});
    _displayTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _displayIdx++;
        if (_displayIdx >= _sequence.length) {
          _displayIdx = -1;
          t.cancel();
        }
      });
    });
  }

  void _record(bool correct) {
    if (correct) {
      if (_backwardPhase) {
        if (_length > _maxBackward) _maxBackward = _length;
      } else {
        if (_length > _maxForward) _maxForward = _length;
      }
      // Move on after first correct attempt at this length.
      _attempts = 0;
      _length++;
      final cap =
          _backwardPhase ? _maxBackwardLength : _maxForwardLength;
      if (_length > cap) {
        _advancePhase();
        return;
      }
      _newSequence();
    } else {
      _attempts++;
      if (_attempts >= 2) {
        // Two failures at this length → end phase.
        _advancePhase();
      } else {
        _newSequence();
      }
    }
  }

  void _advancePhase() {
    if (!_backwardPhase) {
      _backwardPhase = true;
      _length = 3;
      _attempts = 0;
      _newSequence();
    } else {
      _finish();
    }
  }

  void _finish() {
    int forwardPts;
    if (_maxForward >= 6) {
      forwardPts = 3;
    } else if (_maxForward >= 5) {
      forwardPts = 2;
    } else if (_maxForward >= 4) {
      forwardPts = 1;
    } else {
      forwardPts = 0;
    }
    int backwardPts;
    if (_maxBackward >= 5) {
      backwardPts = 2;
    } else if (_maxBackward >= 3) {
      backwardPts = 1;
    } else {
      backwardPts = 0;
    }
    widget.onComplete(DigitSpanResult(
      maxForward: _maxForward,
      maxBackward: _maxBackward,
      score: forwardPts + backwardPts,
    ));
  }

  @override
  void initState() {
    super.initState();
    _newSequence();
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = _backwardPhase ? 'BACKWARD' : 'FORWARD';
    final isDisplaying = _displayIdx >= 0;
    final answerStr = _backwardPhase
        ? _sequence.reversed.join(' ')
        : _sequence.join(' ');

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$phaseLabel · length $_length',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.deepPurple.shade800)),
              Text(_backwardPhase
                  ? 'Repeat in REVERSE order'
                  : 'Repeat in same order',
                  style: TextStyle(
                      fontSize: 11, color: Colors.deepPurple.shade700)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Center(
            child: isDisplaying
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '${_sequence[_displayIdx]}',
                      key: ValueKey('${_sequence.hashCode}_$_displayIdx'),
                      style: const TextStyle(
                        fontSize: 110,
                        fontWeight: FontWeight.w900,
                        color: Colors.deepPurple,
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Did they repeat it correctly?',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _showAnswer = !_showAnswer),
                        icon: Icon(_showAnswer
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        label: Text(_showAnswer
                            ? 'Hide answer'
                            : 'Show correct answer'),
                      ),
                      if (_showAnswer) ...[
                        const SizedBox(height: 12),
                        Text(answerStr,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 6,
                            )),
                      ],
                    ],
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isDisplaying ? null : () => _record(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Incorrect'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isDisplaying ? null : () => _record(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Correct'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.replay),
                tooltip: 'Replay sequence',
                onPressed: isDisplaying ? null : _newSequence,
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _finish,
          child: const Text('Finish test'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category Fluency Timer
// ─────────────────────────────────────────────────────────────

class CategoryFluencyTimer extends StatefulWidget {
  const CategoryFluencyTimer({
    super.key,
    required this.category,
    required this.onComplete,
    this.seconds = 60,
  });

  final String category;
  final int seconds;
  final void Function(int count) onComplete;

  @override
  State<CategoryFluencyTimer> createState() => _CategoryFluencyTimerState();
}

class _CategoryFluencyTimerState extends State<CategoryFluencyTimer> {
  int _count = 0;
  int _remaining = 0;
  Timer? _timer;
  bool _started = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
  }

  void _start() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          t.cancel();
          _done = true;
          HapticUtils.celebration();
          widget.onComplete(_count);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _started
        ? _remaining / widget.seconds
        : 1.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Name as many ${widget.category.toUpperCase()} as you can',
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: 200,
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remaining > 15
                        ? const Color(0xFF1E88E5)
                        : const Color(0xFFE53935),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_remaining',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      color: _remaining > 15
                          ? Colors.black87
                          : AppTheme.dangerColor,
                    ),
                  ),
                  const Text('seconds',
                      style:
                          TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Text('$_count valid',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 18),
        if (!_done)
          ElevatedButton.icon(
            onPressed: () {
              if (!_started) _start();
              setState(() => _count++);
              HapticUtils.warning();
            },
            icon: const Icon(Icons.add, size: 28),
            label: Text(_started ? 'Tap for each answer' : 'Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 18),
              textStyle: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
          )
        else
          Text('Final: $_count',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Pattern Sequence Game
// ─────────────────────────────────────────────────────────────

class PatternSequenceGame extends StatefulWidget {
  const PatternSequenceGame({super.key, required this.onComplete});
  final void Function(int correct) onComplete;

  @override
  State<PatternSequenceGame> createState() => _PatternSequenceGameState();
}

class _PatternSequenceGameState extends State<PatternSequenceGame> {
  static const List<_Pattern> _patterns = [
    _Pattern(
      sequence: ['circle', 'square', 'circle', 'square', 'circle'],
      choices: ['circle', 'square', 'triangle', 'diamond'],
      answerIndex: 1,
    ),
    _Pattern(
      sequence: ['red-circle', 'blue-square', 'red-circle', 'blue-square'],
      choices: ['red-circle', 'blue-square', 'green-triangle', 'red-square'],
      answerIndex: 0,
    ),
    _Pattern(
      sequence: ['circle', 'circle', 'square', 'circle', 'circle'],
      choices: ['triangle', 'circle', 'square', 'diamond'],
      answerIndex: 2,
    ),
    _Pattern(
      sequence: [
        'red-circle',
        'green-square',
        'blue-triangle',
        'red-circle',
        'green-square'
      ],
      choices: [
        'red-circle',
        'green-square',
        'blue-triangle',
        'green-circle'
      ],
      answerIndex: 2,
    ),
  ];

  int _index = 0;
  int _correct = 0;
  int? _selected;
  bool _showResult = false;

  void _pick(int i) {
    if (_showResult) return;
    setState(() {
      _selected = i;
      _showResult = true;
      if (i == _patterns[_index].answerIndex) {
        _correct++;
        HapticUtils.warning();
      } else {
        HapticFeedback.heavyImpact();
      }
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_index >= _patterns.length - 1) {
        widget.onComplete(_correct);
      } else {
        setState(() {
          _index++;
          _selected = null;
          _showResult = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = _patterns[_index];
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text('Pattern ${_index + 1} of ${_patterns.length}',
              style: TextStyle(
                  color: Colors.teal.shade800,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
        const SizedBox(height: 16),
        const Text('What comes next?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in p.sequence) _shapeBox(s, 56),
            _shapeBox('?', 56),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        const Text('Choose one:',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            for (int i = 0; i < p.choices.length; i++)
              GestureDetector(
                onTap: () => _pick(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _showResult && _selected == i
                        ? (i == p.answerIndex
                            ? Colors.green.shade100
                            : Colors.red.shade100)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _showResult && _selected == i
                          ? (i == p.answerIndex
                              ? Colors.green
                              : Colors.red)
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: _shapeBox(p.choices[i], 64),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _shapeBox(String spec, double size) {
    if (spec == '?') {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: Text('?',
            style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.w900,
                color: Colors.amber.shade900)),
      );
    }
    final parts = spec.split('-');
    final color = parts.length == 2
        ? _colorFromName(parts[0])
        : Colors.indigo;
    final shape = parts.last;
    Widget shapeWidget;
    switch (shape) {
      case 'square':
        shapeWidget = Container(
          width: size * 0.7,
          height: size * 0.7,
          color: color,
        );
        break;
      case 'triangle':
        shapeWidget = CustomPaint(
          size: Size(size * 0.7, size * 0.7),
          painter: _TrianglePainter(color),
        );
        break;
      case 'diamond':
        shapeWidget = Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size * 0.55,
            height: size * 0.55,
            color: color,
          ),
        );
        break;
      case 'circle':
      default:
        shapeWidget = Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(child: shapeWidget),
    );
  }

  Color _colorFromName(String name) {
    switch (name) {
      case 'red':
        return const Color(0xFFE53935);
      case 'blue':
        return const Color(0xFF1E88E5);
      case 'green':
        return const Color(0xFF43A047);
      default:
        return Colors.indigo;
    }
  }
}

class _Pattern {
  final List<String> sequence;
  final List<String> choices;
  final int answerIndex;
  const _Pattern({
    required this.sequence,
    required this.choices,
    required this.answerIndex,
  });
}

class _TrianglePainter extends CustomPainter {
  _TrianglePainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
