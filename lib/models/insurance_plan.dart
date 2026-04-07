// lib/models/insurance_plan.dart
//
// Personal annual insurance plan settings used by the budget screen's
// out-of-pocket tracker. Stored locally in SharedPreferences under
// `insurance_plan_{year}` — this is private financial data the caregiver
// manages for themselves and does not need to live in Firestore.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class InsurancePlan {
  final int year;
  final double deductibleAmount;
  final double outOfPocketMax;

  /// Optional manual deductible-met override (for mid-year setup before
  /// any expenses are logged).
  final double? deductibleMetOverride;

  /// Optional Adjusted Gross Income for the IRS 7.5% medical-deduction
  /// threshold calculation.
  final double? adjustedGrossIncome;

  /// Monthly premium tracked separately so it doesn't get lumped into
  /// medical spending toward the OOP cap.
  final double? monthlyPremium;

  const InsurancePlan({
    required this.year,
    required this.deductibleAmount,
    required this.outOfPocketMax,
    this.deductibleMetOverride,
    this.adjustedGrossIncome,
    this.monthlyPremium,
  });

  bool get hasAgi =>
      adjustedGrossIncome != null && adjustedGrossIncome! > 0;

  /// IRS allows medical-expense deductions only above 7.5% of AGI.
  double get irsMedicalThreshold =>
      hasAgi ? adjustedGrossIncome! * 0.075 : 0;

  Map<String, dynamic> toJson() => {
        'year': year,
        'deductibleAmount': deductibleAmount,
        'outOfPocketMax': outOfPocketMax,
        if (deductibleMetOverride != null)
          'deductibleMetOverride': deductibleMetOverride,
        if (adjustedGrossIncome != null)
          'adjustedGrossIncome': adjustedGrossIncome,
        if (monthlyPremium != null) 'monthlyPremium': monthlyPremium,
      };

  factory InsurancePlan.fromJson(Map<String, dynamic> j) => InsurancePlan(
        year: j['year'] as int,
        deductibleAmount: (j['deductibleAmount'] as num).toDouble(),
        outOfPocketMax: (j['outOfPocketMax'] as num).toDouble(),
        deductibleMetOverride:
            (j['deductibleMetOverride'] as num?)?.toDouble(),
        adjustedGrossIncome:
            (j['adjustedGrossIncome'] as num?)?.toDouble(),
        monthlyPremium: (j['monthlyPremium'] as num?)?.toDouble(),
      );

  static String _key(int year) => 'insurance_plan_$year';

  static Future<InsurancePlan?> load(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(year));
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw);
      if (j is Map<String, dynamic>) return InsurancePlan.fromJson(j);
    } catch (_) {}
    return null;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(year), jsonEncode(toJson()));
  }

  static Future<void> clear(int year) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(year));
  }
}

/// IRS standard medical mileage rate (cents/mile). Update annually.
const double kMedicalMileageRate = 0.21; // 2025 IRS rate
