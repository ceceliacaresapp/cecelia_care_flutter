// lib/models/day_entries.dart

import 'medication_entry.dart';
import 'sleep_entry.dart';
import 'meal_entry.dart';
import 'mood_entry.dart';
import 'pain_entry.dart';
import 'activity_entry.dart';
import 'vital_entry.dart';
import 'expense_entry.dart';

/// A “snapshot” of everything logged for one elder on one date.
/// Each field is a list of entries of that type. In a real app, replace
/// `dynamic` with your concrete model classes (e.g. MedEntry, SleepEntry, etc.).
class DayEntries {
  final List<MedicationEntry> meds;
  final List<SleepEntry> sleep;
  final List<MealEntry> meals;
  final List<MoodEntry> moods;
  final List<PainEntry> pain;
  final List<ActivityEntry> activities;
  final List<VitalEntry> vitals;
  final List<ExpenseEntry> expenses;

  DayEntries({
    required this.meds,
    required this.sleep,
    required this.meals,
    required this.moods,
    required this.pain,
    required this.activities,
    required this.vitals,
    required this.expenses,
  });

  /// If you want an “empty” DayEntries by default:
  factory DayEntries.empty() {
    return DayEntries(
      meds: [],
      sleep: [],
      meals: [],
      moods: [],
      pain: [],
      activities: [],
      vitals: [],
      expenses: [],
    );
  }

  /// Returns true if all entry lists are empty.
  bool get isEmpty =>
      meds.isEmpty &&
      sleep.isEmpty &&
      meals.isEmpty &&
      moods.isEmpty &&
      pain.isEmpty &&
      activities.isEmpty &&
      vitals.isEmpty &&
      expenses.isEmpty;
}

extension DayEntriesCopyWith on DayEntries {
  DayEntries copyWith({
    List<MedicationEntry>? meds,
    List<SleepEntry>? sleep,
    List<MealEntry>? meals,
    List<MoodEntry>? moods,
    List<PainEntry>? pain,
    List<ActivityEntry>? activities,
    List<VitalEntry>? vitals,
    List<ExpenseEntry>? expenses,
  }) {
    return DayEntries(
      meds: meds ?? this.meds,
      sleep: sleep ?? this.sleep,
      meals: meals ?? this.meals,
      moods: moods ?? this.moods,
      pain: pain ?? this.pain,
      activities: activities ?? this.activities,
      vitals: vitals ?? this.vitals,
      expenses: expenses ?? this.expenses,
    );
  }
}
