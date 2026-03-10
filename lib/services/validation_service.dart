import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

class ValidationService {
  static String? validateRequiredField(
    String? value, {
    required String fieldName, 
    required AppLocalizations l10n,
  }) {
    if (value == null || value.trim().isEmpty) {
      // TEMP FIX: Replaced missing l10n call with string to fix build error
      return '$fieldName is required.'; 
    }
    return null;
  }

  static String? validateNumericField(
    String? value, {
    required String fieldName,
    required AppLocalizations l10n,
    int? min,
    int? max,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }
    final number = int.tryParse(value.trim());
    if (number == null) {
      // TEMP FIX: Replaced missing l10n call
      return 'Please enter a valid number for $fieldName.';
    }
    if (min != null && number < min) {
      // TEMP FIX: Replaced missing l10n call
      return '$fieldName must be at least $min.';
    }
    if (max != null && number > max) {
      // TEMP FIX: Replaced missing l10n call
      return '$fieldName must be at most $max.';
    }
    return null;
  }

  // --- Form Specific Validations ---

  // Meal Form
  static String? validateMealDescription(String? value, String fieldName, AppLocalizations l10n) {
    return validateRequiredField(value, fieldName: fieldName, l10n: l10n);
  }

  // Mood Form
  static String? validateMoodSelection(String? selectedMood, String? otherMood, AppLocalizations l10n) {
    // We assume these specific keys exist since the compiler didn't flag them
    if ((selectedMood == null || selectedMood.isEmpty || selectedMood == l10n.moodOptionOther) && (otherMood == null || otherMood.trim().isEmpty)) {
      return l10n.moodFormValidationSelectOrSpecifyMood;
    }
    if (selectedMood == l10n.moodOptionOther && (otherMood == null || otherMood.trim().isEmpty)) {
      return l10n.moodFormValidationSpecifyOtherMood;
    }
    return null;
  }

  static String? validateMoodIntensity(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return null; // Optional field
    return validateNumericField(value, fieldName: l10n.moodFormLabelIntensity, l10n: l10n, min: 1, max: 5);
  }

  // Pain Form
  static String? validatePainDescriptionSelection(String? selectedDesc, String? otherDesc, AppLocalizations l10n) {
     if ((selectedDesc == null || selectedDesc.isEmpty || selectedDesc == l10n.formOptionOther) && (otherDesc == null || otherDesc.trim().isEmpty)) {
      return l10n.painFormValidationSelectOrSpecifyDescription;
    }
    if (selectedDesc == l10n.formOptionOther && (otherDesc == null || otherDesc.trim().isEmpty)) {
      return l10n.painFormValidationSpecifyOtherDescription;
    }
    return null;
  }

  static String? validatePainIntensity(String? value, AppLocalizations l10n) {
    return validateNumericField(value, fieldName: l10n.painFormLabelIntensity, l10n: l10n, min: 0, max: 10);
  }

  static String? validatePainLocation(String? value, AppLocalizations l10n) {
    return validateRequiredField(value, fieldName: l10n.painFormLabelLocation, l10n: l10n);
  }

  // Sleep Form
  static String? validateTotalDuration(String? value, AppLocalizations l10n) {
    if (value != null && value.isNotEmpty) {
        if (!RegExp(r'^[\d\shmHM]+$').hasMatch(value)) {
            // TEMP FIX: Replaced missing l10n call
            return 'Invalid format for ${l10n.sleepFormLabelTotalDuration}';
        }
    }
    return null; 
  }

  static String? validateSleepQualitySelection(String? selectedQuality, String? otherQuality, AppLocalizations l10n) {
    if ((selectedQuality == null || selectedQuality.isEmpty || selectedQuality == l10n.formOptionOther) && (otherQuality == null || otherQuality.trim().isEmpty)) {
      return l10n.sleepFormValidationSelectQuality; 
    }
     if (selectedQuality == l10n.formOptionOther && (otherQuality == null || otherQuality.trim().isEmpty)) {
      return l10n.sleepFormValidationDescribeOtherQuality;
    }
    return null;
  }

  static String? validateSleepTime(String? value, String fieldName, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
        return '$fieldName is required.';
    }
    return null;
  }

  static String? validateSleepQuality(int? value, AppLocalizations l10n) { 
    if (value == null) return l10n.sleepFormValidationSelectQuality;
    if (value < 1 || value > 5) return l10n.moodFormValidationIntensityRange; 
    return null;
  }

  // Expense Form
  static String? validateExpenseDescription(String? value, AppLocalizations l10n) {
    return validateRequiredField(value, fieldName: l10n.expenseFormLabelDescription, l10n: l10n);
  }
  static String? validateExpenseAmount(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.expenseFormValidationAmountEmpty;
    final double? amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) return l10n.expenseFormValidationAmountInvalid;
    return null;
  }
  static String? validateExpenseCategory(String? value, AppLocalizations l10n) {
    return validateRequiredField(value, fieldName: l10n.expenseFormLabelCategory, l10n: l10n);
  }

  // Vital Form
  static String? validateVitalValue(String? value, String vitalTypeKey, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) return l10n.vitalFormValidationValueEmpty;
    return null;
  }

  // Medication Form
  static String? validateMedicationName(String? value, AppLocalizations l10n) {
    return validateRequiredField(value, fieldName: l10n.medFormLabelName, l10n: l10n);
  }

  // Activity Form
  static String? validateActivityType(String? value, AppLocalizations l10n) {
    return validateRequiredField(value, fieldName: l10n.activityFormLabelActivityType, l10n: l10n);
  }
  static String? validateActivityDuration(int? value, AppLocalizations l10n) { 
    if (value != null && value <= 0) {
        // TEMP FIX: Replaced missing l10n call
        return '${l10n.activityFormLabelDuration} must be a positive number.';
    }
    return null; 
  }
}