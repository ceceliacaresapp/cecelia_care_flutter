// lib/utils/parse_utils.dart

/// Attempts to parse an integer from a dynamic value.
/// If the value is already an int, it's returned directly.
/// If it's a String, it extracts the first sequence of digits and tries to parse that.
/// Returns null if parsing fails or no digits are found.
int? parseInt(dynamic v) =>
  v is int ? v : int.tryParse(RegExp(r'\d+').firstMatch('$v')?.group(0) ?? '');

/// Attempts to parse a double from a dynamic value.
/// If the value is already a double, it's returned directly.
/// If it's a String, it extracts the first sequence of digits and decimal points and tries to parse that.
/// Returns null if parsing fails or no valid number-like string is found.
double? parseDouble(dynamic v) =>
  v is double ? v : double.tryParse(RegExp(r'[\d.]+').firstMatch('$v')?.group(0) ?? '');

/// Attempts to parse a boolean from a dynamic value.
/// Handles direct booleans and common string representations (case-insensitive).
/// Returns null if the value is not a recognized boolean representation.
bool? parseBool(dynamic v) {
  if (v is bool) return v;
  if (v is String) {
    final l = v.toLowerCase().trim(); // Added trim() for robustness
    if (['yes','y','true','taken'].contains(l)) return true;
    if (['no','n','false','skipped', 'missed'].contains(l)) return false; // Added 'missed'
  }
  return null; // Default to null if not a bool or recognized string
}