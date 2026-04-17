// lib/screens/burnout_intervention_screen.dart
//
// Warm, empathetic intervention screen. Shows when the caregiver's wellbeing
// score has been <= 40 for 3+ consecutive days. Not clinical. Not alarming.
// A friend checking in.

import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/providers/wellness_provider.dart';
import 'package:cecelia_care_flutter/screens/breathing_exercise_screen.dart';
import 'package:cecelia_care_flutter/screens/caregiver_journal/caregiver_journal_screen.dart';
import 'package:cecelia_care_flutter/screens/sos_screen.dart';

class BurnoutInterventionScreen extends StatelessWidget {
  const BurnoutInterventionScreen({super.key});

  Future<void> _dismiss(BuildContext context, {bool permanent = false}) async {
    final sp = await SharedPreferences.getInstance();
    if (permanent) {
      await sp.setBool('burnout_intervention_permanent_dismiss', true);
    } else {
      await sp.setString('burnout_intervention_dismissed',
          DateTime.now().toIso8601String());
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  /// Returns true if the intervention should be suppressed.
  static Future<bool> shouldSuppress() async {
    final sp = await SharedPreferences.getInstance();

    // Permanent dismiss.
    if (sp.getBool('burnout_intervention_permanent_dismiss') == true) {
      return true;
    }

    // Temporary dismiss (3-day cooldown).
    final dismissed = sp.getString('burnout_intervention_dismissed');
    if (dismissed != null) {
      final dismissedDate = DateTime.tryParse(dismissed);
      if (dismissedDate != null &&
          DateTime.now().difference(dismissedDate).inDays < 3) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final wellProv = context.watch<WellnessProvider>();
    final weakest = wellProv.weakestDimension;
    final scores = wellProv.recentCheckins
        .take(7)
        .map((c) => c.wellbeingScore.toDouble())
        .toList()
        .reversed
        .toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8EAF6), Color(0xFFE1BEE7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 20),

              // ── Empathetic header ──────────────────────────────
              const Text('\uD83D\uDC9B', // 💛
                  style: TextStyle(fontSize: 48),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'Hey, we noticed something.',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4A148C),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your wellbeing has been low for several days. '
                'You\'re doing incredible work \u2014 and you deserve care too.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // ── Sparkline ──────────────────────────────────────
              if (scores.length >= 2) ...[
                const Text('YOUR PAST WEEK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: Color(0xFF7E57C2),
                    ),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: scores.map((s) {
                      final height = (s / 100) * 50;
                      final color = s <= 30
                          ? AppTheme.statusRed
                          : s <= 60
                              ? AppTheme.tileOrange
                              : AppTheme.statusGreen;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${s.toInt()}',
                                style: TextStyle(fontSize: 9, color: color)),
                            const SizedBox(height: 2),
                            Container(
                              width: 20,
                              height: height.clamp(4.0, 50.0),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Weakest dimension callout ──────────────────────
              if (weakest != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: Color(0xFF7E57C2)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your $weakest has been especially low this week.',
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF4A148C)),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ── Action cards ───────────────────────────────────
              _ActionCard(
                emoji: '\uD83C\uDF2C\uFE0F', // 🌬️
                title: 'Take a breath',
                subtitle: 'A quick breathing exercise to reset',
                color: AppTheme.tileTeal,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const BreathingExerciseScreen())),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '\uD83D\uDCDD', // 📝
                title: 'Talk it out',
                subtitle: 'Write in your private journal',
                color: AppTheme.tileIndigo,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const CareGiverJournalScreen())),
              ),
              const SizedBox(height: 10),
              _ActionCard(
                emoji: '\uD83C\uDD98', // 🆘
                title: 'I need help now',
                subtitle: 'Crisis tools, hotlines, and support',
                color: AppTheme.statusRed,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const SosScreen())),
              ),

              const SizedBox(height: 32),

              // ── Dismiss options ────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () => _dismiss(context),
                  child: const Text('I\'m okay, thanks',
                      style: TextStyle(
                          fontSize: 15, color: Color(0xFF7E57C2))),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () => _dismiss(context, permanent: true),
                  child: Text('Don\'t show this again',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
