// lib/widgets/stream_error_card.dart
//
// Shared error card used by every dashboard / care / budget StreamBuilder
// when its underlying Firestore query fails. Without this, a permission
// or index error silently leaves the StreamBuilder spinning forever and
// users see a frozen screen.
//
// Two variants:
//   • StreamErrorCard — full card with icon + message + optional retry
//   • StreamErrorInline — small inline strip for compact widgets

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';

class StreamErrorCard extends StatelessWidget {
  const StreamErrorCard({
    super.key,
    required this.message,
    this.error,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline,
              color: AppTheme.dangerColor, size: compact ? 16 : 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.dangerColor,
                  ),
                ),
                if (error != null && !compact) ...[
                  const SizedBox(height: 2),
                  Text(
                    _shortenError(error.toString()),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  /// Pulls a friendly first line out of the Firebase error string.
  static String _shortenError(String raw) {
    // Firestore errors usually look like:
    //   [cloud_firestore/permission-denied] The caller does not have permission...
    final bracket = raw.indexOf(']');
    final cleaned = bracket >= 0 && bracket < raw.length - 1
        ? raw.substring(bracket + 1).trim()
        : raw;
    return cleaned.length > 120 ? '${cleaned.substring(0, 117)}…' : cleaned;
  }
}

/// Inline tiny error strip — used inside narrow areas like a card header
/// where a full StreamErrorCard would be too tall.
class StreamErrorInline extends StatelessWidget {
  const StreamErrorInline({super.key, this.message = 'Failed to load'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline,
            size: 12, color: AppTheme.dangerColor),
        const SizedBox(width: 4),
        Text(
          message,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.dangerColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
