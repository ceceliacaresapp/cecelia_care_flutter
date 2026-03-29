// lib/screens/sos_screen.dart
//
// Crisis toolkit for caregivers experiencing acute burnout or distress.
//
// Surfaces automatically when burnout score is red (61+), or launched
// manually from the Self Care tab's SOS button.
//
// Contains:
//   1. Calming header with gentle encouragement
//   2. Quick breathing exercise (starts with one tap)
//   3. 5-4-3-2-1 grounding exercise (step-through)
//   4. Crisis hotline numbers
//   5. "Take 5 minutes" countdown timer
//   6. Quick-journal prompt
//
// No direct Firestore access. Navigation-only — each tool either runs
// inline or pushes to BreathingExerciseScreen / CaregiverJournalScreen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cecelia_care_flutter/screens/breathing_exercise_screen.dart';
import 'package:cecelia_care_flutter/screens/caregiver_journal/caregiver_journal_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// Calm color palette for this screen — muted teal + lavender
const _kCalmPrimary = Color(0xFF5C6BC0); // indigo
const _kCalmSecondary = Color(0xFF00897B); // teal
const _kCalmBg = Color(0xFFF3F0FF); // very light lavender

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  // 5-minute timer
  bool _timerRunning = false;
  int _timerSeconds = 5 * 60; // 300 seconds
  Timer? _timer;

  // Grounding exercise state
  int _groundingStep = 0; // 0 = not started, 1–5 = steps

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerRunning = true;
      _timerSeconds = 5 * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_timerSeconds <= 0) {
        t.cancel();
        HapticFeedback.mediumImpact();
        setState(() => _timerRunning = false);
        return;
      }
      setState(() => _timerSeconds--);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() => _timerRunning = false);
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('SosScreen: could not launch phone: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: _kCalmBg,
      appBar: AppBar(
        title: const Text('Take a moment'),
        centerTitle: true,
        backgroundColor: _kCalmPrimary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_kCalmPrimary, _kCalmPrimary.withOpacity(0.82)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Calming header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _kCalmPrimary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.favorite,
                      size: 36, color: _kCalmPrimary.withOpacity(0.7)),
                  const SizedBox(height: 12),
                  Text(
                    "You're doing something incredibly brave by caring for someone else.",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _kCalmPrimary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "It's okay to pause. These tools are here to help you right now.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Quick breathing ─────────────────────────────────────
            _SosToolCard(
              icon: Icons.air_outlined,
              color: _kCalmSecondary,
              title: 'Breathing exercise',
              subtitle: 'A guided breathing exercise to calm your body.',
              actionLabel: 'Start breathing',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const BreathingExerciseScreen(initialPatternIndex: 2),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── 5-4-3-2-1 Grounding ────────────────────────────────
            _GroundingCard(
              currentStep: _groundingStep,
              onStart: () => setState(() => _groundingStep = 1),
              onNext: () {
                if (_groundingStep < 5) {
                  setState(() => _groundingStep++);
                } else {
                  setState(() => _groundingStep = 0);
                }
              },
              onReset: () => setState(() => _groundingStep = 0),
            ),

            const SizedBox(height: 14),

            // ── 5-minute break timer ────────────────────────────────
            _SosToolCard(
              icon: _timerRunning ? Icons.timer : Icons.timer_outlined,
              color: const Color(0xFFF57C00),
              title: 'Take 5 minutes',
              subtitle: _timerRunning
                  ? _formatTimer(_timerSeconds)
                  : 'Set a gentle timer to step away and breathe.',
              actionLabel: _timerRunning ? 'Stop timer' : 'Start timer',
              onTap: _timerRunning ? _stopTimer : _startTimer,
              isActive: _timerRunning,
            ),

            const SizedBox(height: 14),

            // ── Journal prompt ──────────────────────────────────────
            _SosToolCard(
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF8E24AA),
              title: 'Write it out',
              subtitle:
                  "Sometimes putting feelings into words helps. There's no wrong way to do this.",
              actionLabel: 'Open journal',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CareGiverJournalScreen(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Crisis hotlines ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.dangerColor.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_in_talk_outlined,
                          size: 18, color: AppTheme.dangerColor),
                      const SizedBox(width: 8),
                      const Text(
                        'CRISIS SUPPORT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HotlineRow(
                    name: '988 Suicide & Crisis Lifeline',
                    number: '988',
                    note: 'Call or text, 24/7',
                    onCall: () => _launchPhone('988'),
                  ),
                  const Divider(height: 16),
                  _HotlineRow(
                    name: 'Caregiver Action Network',
                    number: '1-855-227-3640',
                    note: 'Caregiver-specific support',
                    onCall: () => _launchPhone('18552273640'),
                  ),
                  const Divider(height: 16),
                  _HotlineRow(
                    name: 'SAMHSA Helpline',
                    number: '1-800-662-4357',
                    note: 'Mental health & substance use',
                    onCall: () => _launchPhone('18006624357'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'These services are free, confidential, and available 24/7.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
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
// SOS tool card — reusable for breathing, timer, journal
// ---------------------------------------------------------------------------
class _SosToolCard extends StatelessWidget {
  const _SosToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isActive ? color : color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isActive ? 28 : 12,
                      fontWeight:
                          isActive ? FontWeight.w300 : FontWeight.normal,
                      color: isActive ? color : AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
              ),
              child: Text(
                actionLabel,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5-4-3-2-1 Grounding exercise card
// ---------------------------------------------------------------------------
class _GroundingCard extends StatelessWidget {
  const _GroundingCard({
    required this.currentStep,
    required this.onStart,
    required this.onNext,
    required this.onReset,
  });

  final int currentStep; // 0 = not started, 1–5 = steps
  final VoidCallback onStart;
  final VoidCallback onNext;
  final VoidCallback onReset;

  static const _steps = [
    _GroundingStep(
      number: 5,
      sense: 'See',
      instruction: 'Name 5 things you can see right now.',
      icon: Icons.visibility_outlined,
    ),
    _GroundingStep(
      number: 4,
      sense: 'Touch',
      instruction: 'Name 4 things you can physically feel.',
      icon: Icons.touch_app_outlined,
    ),
    _GroundingStep(
      number: 3,
      sense: 'Hear',
      instruction: 'Name 3 things you can hear.',
      icon: Icons.hearing_outlined,
    ),
    _GroundingStep(
      number: 2,
      sense: 'Smell',
      instruction: 'Name 2 things you can smell.',
      icon: Icons.air_outlined,
    ),
    _GroundingStep(
      number: 1,
      sense: 'Taste',
      instruction: 'Name 1 thing you can taste.',
      icon: Icons.restaurant_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isActive = currentStep > 0;
    const color = _kCalmPrimary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isActive ? color : color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.grid_view, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '5-4-3-2-1 Grounding',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive
                            ? 'Step $currentStep of 5'
                            : 'Uses your senses to bring you back to the present.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!isActive) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onStart,
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: color.withOpacity(0.3)),
                    ),
                  ),
                  child: const Text('Begin',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ),
            ],

            if (isActive) ...[
              const SizedBox(height: 16),

              // Step progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final stepNum = i + 1;
                  final isDone = stepNum < currentStep;
                  final isCurrent = stepNum == currentStep;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 12 : 8,
                    height: isCurrent ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? color
                          : isCurrent
                              ? color
                              : color.withOpacity(0.2),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Current step instruction
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(_steps[currentStep - 1].icon,
                        color: color, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_steps[currentStep - 1].number} — ${_steps[currentStep - 1].sense}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _steps[currentStep - 1].instruction,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Next / Done buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReset,
                    child: const Text('Cancel',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                    child: Text(
                      currentStep >= 5 ? 'Finish' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroundingStep {
  final int number;
  final String sense;
  final String instruction;
  final IconData icon;

  const _GroundingStep({
    required this.number,
    required this.sense,
    required this.instruction,
    required this.icon,
  });
}

// ---------------------------------------------------------------------------
// Hotline row
// ---------------------------------------------------------------------------
class _HotlineRow extends StatelessWidget {
  const _HotlineRow({
    required this.name,
    required this.number,
    required this.note,
    required this.onCall,
  });

  final String name;
  final String number;
  final String note;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                note,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.call, size: 14),
          label: Text(number, style: const TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.dangerColor,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
