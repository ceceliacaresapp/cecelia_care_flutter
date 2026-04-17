// lib/utils/save_helpers.dart
//
// Utilities for assessment save handlers. Firestore's Flutter SDK caches
// writes locally by default — so an "unavailable" or "deadline-exceeded"
// error usually means the data IS queued and will sync when connectivity
// returns. Only permission / validation errors are truly fatal.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Returns `true` if the error is a network-related Firestore error (the
/// write was likely cached locally and will sync later).
bool isNetworkError(Object error) {
  if (error is FirebaseException) {
    return error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'cancelled';
  }
  final msg = error.toString().toLowerCase();
  return msg.contains('unavailable') ||
      msg.contains('network') ||
      msg.contains('timeout') ||
      msg.contains('socket') ||
      msg.contains('connection');
}

/// Show the right snackbar after a failed save.
///
/// - Network errors → amber "Saved offline — will sync when connected"
/// - Other errors → red "Failed to save" with detail
void showSaveError(BuildContext context, Object error, {String? label}) {
  if (!context.mounted) return;
  final prefix = label != null ? '$label: ' : '';

  if (isNetworkError(error)) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.cloud_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${prefix}Saved offline — will sync when connected',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.statusAmber,
      duration: const Duration(seconds: 3),
    ));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${prefix}Failed to save. $error'),
      backgroundColor: AppTheme.dangerColor,
    ));
  }
}
