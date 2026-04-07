// lib/widgets/timed_loading_indicator.dart
//
// Loading spinner that auto-flips to a "couldn't load — retry" UI after a
// configurable timeout. Use this anywhere a StreamBuilder or provider can
// silently hang on a permission error / missing index / dropped network.
//
// Without a timeout, users stare at a spinner forever and have no way to
// recover. With this widget, after `timeout` seconds (default 10) the
// spinner is replaced by a friendly error card with a Retry button that
// triggers `onRetry` (typically a `setState(() {})` or a force-refresh
// call on the parent screen).
//
// Usage:
//
//   if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
//     return TimedLoadingIndicator(
//       onRetry: () => setState(() {}), // re-runs the StreamBuilder
//     );
//   }

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/utils/app_theme.dart';

class TimedLoadingIndicator extends StatefulWidget {
  const TimedLoadingIndicator({
    super.key,
    this.timeout = const Duration(seconds: 10),
    this.message = 'Loading…',
    this.timeoutMessage =
        'Unable to load. Check your connection and try again.',
    this.onRetry,
    this.padding = const EdgeInsets.all(24),
  });

  final Duration timeout;
  final String message;
  final String timeoutMessage;
  final VoidCallback? onRetry;
  final EdgeInsets padding;

  @override
  State<TimedLoadingIndicator> createState() => _TimedLoadingIndicatorState();
}

class _TimedLoadingIndicatorState extends State<TimedLoadingIndicator> {
  Timer? _timer;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _timedOut = false;
    });
    _timer?.cancel();
    _timer = Timer(widget.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
    widget.onRetry?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_timedOut) {
      return Center(
        child: Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off,
                  size: 48, color: AppTheme.dangerColor),
              const SizedBox(height: 12),
              Text(
                widget.timeoutMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              if (widget.onRetry != null)
                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: widget.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
