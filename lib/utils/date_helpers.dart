import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// A utility class for common date and time operations.
class DateHelpers {
  /// Formats a [DateTime] object into a 'yyyy-MM-dd' string.
  ///
  /// This is useful for creating consistent date strings for Firestore paths or display.
  static String dateStringFor(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// Returns a Firestore [Timestamp] representing midnight (00:00:00) of the given [DateTime].
  ///
  /// This is useful for date-based queries where you want to include the entire day.
  static Timestamp midnightTimestamp(DateTime dateTime) {
    final midnight = DateTime(dateTime.year, dateTime.month, dateTime.day);
    return Timestamp.fromDate(midnight);
  }

  // You can add more static date helper methods here as needed.
}