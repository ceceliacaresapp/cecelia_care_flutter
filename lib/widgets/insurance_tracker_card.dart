// lib/widgets/insurance_tracker_card.dart
//
// Visual tracker for the caregiver's annual insurance plan: deductible
// progress, out-of-pocket-max progress, and quick YTD stats. Pure UI —
// the parent screen owns the InsurancePlan + medical-expense totals and
// passes them in.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/insurance_plan.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class InsuranceTrackerCard extends StatelessWidget {
  const InsuranceTrackerCard({
    super.key,
    required this.plan,
    required this.ytdMedicalSpend,
    required this.ytdTaxDeductible,
    required this.monthlyAverage,
    required this.onSetup,
  });

  final InsurancePlan? plan;
  final double ytdMedicalSpend;
  final double ytdTaxDeductible;
  final double monthlyAverage;
  final VoidCallback onSetup;

  static final NumberFormat _money =
      NumberFormat.simpleCurrency(decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    if (plan == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.tileBlueDark.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
              color: AppTheme.tileBlueDark.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.health_and_safety_outlined,
                color: AppTheme.tileBlueDark, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track your insurance progress',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    'Set your annual deductible and out-of-pocket max to see how close you are to insurance picking up the rest.',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            ElevatedButton(
              onPressed: onSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tileBlueDark,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Set up'),
            ),
          ],
        ),
      );
    }

    final p = plan!;
    final deductibleMet = (p.deductibleMetOverride ?? 0) +
        ytdMedicalSpend.clamp(0, p.deductibleAmount);
    final deductibleProgress = p.deductibleAmount > 0
        ? (deductibleMet / p.deductibleAmount).clamp(0.0, 1.0)
        : 0.0;
    final oopMet = ytdMedicalSpend.clamp(0, p.outOfPocketMax);
    final oopProgress = p.outOfPocketMax > 0
        ? (oopMet / p.outOfPocketMax).clamp(0.0, 1.0)
        : 0.0;
    final deductibleHit = deductibleProgress >= 1.0;
    final oopHit = oopProgress >= 1.0;

    // Estimated date to reach OOP max based on monthly avg.
    String? estimateText;
    if (!oopHit && monthlyAverage > 0 && p.outOfPocketMax > ytdMedicalSpend) {
      final monthsRemaining =
          (p.outOfPocketMax - ytdMedicalSpend) / monthlyAverage;
      final eta = DateTime.now().add(
          Duration(days: (monthsRemaining * 30).round()));
      if (eta.year == p.year) {
        estimateText =
            'At current rate, you may reach your max around ${DateFormat('MMM yyyy').format(eta)}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(
            color: AppTheme.tileBlueDark.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tileBlueDark.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.health_and_safety_outlined,
                    color: AppTheme.tileBlueDark, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Insurance · ${p.year}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    if (p.monthlyPremium != null && p.monthlyPremium! > 0)
                      Text(
                        'Premium ${_money.format(p.monthlyPremium)}/mo',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined,
                    color: AppTheme.tileBlueDark, size: 18),
                tooltip: 'Edit insurance settings',
                onPressed: onSetup,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Deductible bar
          _ProgressSection(
            label: 'Deductible',
            current: deductibleMet.toDouble(),
            max: p.deductibleAmount,
            progress: deductibleProgress,
            color: deductibleHit
                ? AppTheme.statusGreen
                : (deductibleProgress > 0.6
                    ? AppTheme.tileOrange
                    : Colors.grey.shade500),
            celebration: deductibleHit
                ? 'Deductible met — insurance starts paying more!'
                : null,
          ),
          const SizedBox(height: 12),

          // OOP max bar
          _ProgressSection(
            label: 'Out-of-pocket max',
            current: oopMet.toDouble(),
            max: p.outOfPocketMax,
            progress: oopProgress,
            color: oopHit
                ? AppTheme.statusGreen
                : (oopProgress > 0.75
                    ? AppTheme.tileBlue
                    : Colors.grey.shade500),
            celebration: oopHit
                ? 'Max reached — everything else is covered!'
                : estimateText,
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Quick stats row
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'YTD medical',
                  value: _money.format(ytdMedicalSpend),
                  color: AppTheme.tileBlueDark,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Tax-deductible',
                  value: _money.format(ytdTaxDeductible),
                  color: AppTheme.entryMoodAccent,
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Monthly avg',
                  value: _money.format(monthlyAverage),
                  color: AppTheme.tileOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.label,
    required this.current,
    required this.max,
    required this.progress,
    required this.color,
    this.celebration,
  });

  final String label;
  final double current;
  final double max;
  final double progress;
  final Color color;
  final String? celebration;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700)),
            Text(
              '${money.format(current)} / ${money.format(max)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        if (celebration != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                progress >= 1.0
                    ? Icons.celebration
                    : Icons.schedule,
                size: 12,
                color: color,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(celebration!,
                    style: TextStyle(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: color,
                    )),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            )),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}
