// lib/widgets/expense_breakdown_chart.dart
//
// Horizontal bar chart of monthly spending grouped by category. Custom
// painted (no chart library) — same approach as the cognitive screen
// dimension bars. Sorted by spend descending.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/budget_entry.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class ExpenseBreakdownChart extends StatelessWidget {
  const ExpenseBreakdownChart({
    super.key,
    required this.expenses,
    required this.monthLabel,
  });

  final List<BudgetEntry> expenses;
  final String monthLabel;

  static const Map<String, Color> _categoryColors = {
    'Medical & Health': Color(0xFFD32F2F),
    'Housing': Color(0xFF1565C0),
    'Professional Care': Color(0xFF6A1B9A),
    'Daily Living': Color(0xFFF57C00),
    'Transportation': Color(0xFF00897B),
    'Legal & Financial': Color(0xFF455A64),
    'Caregiver Support': Color(0xFFE91E63),
  };

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    final totals = <String, double>{};
    for (final e in expenses) {
      totals.update(e.category, (v) => v + e.amount,
          ifAbsent: () => e.amount);
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = entries.fold<double>(0, (s, e) => s + e.value);
    if (grandTotal <= 0) return const SizedBox.shrink();
    final maxVal = entries.first.value;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spending by category',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
              Text(monthLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${money.format(grandTotal)}',
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          ...entries.map((e) {
            final pct = e.value / grandTotal;
            final color = _categoryColors[e.key] ?? Colors.indigo;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                      Text(
                        '${money.format(e.value)} · ${(pct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / maxVal,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
