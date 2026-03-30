// lib/widgets/offline_banner.dart
//
// Self-contained offline indicator. Watches connectivity via
// connectivity_plus and shows a slim amber banner when the device
// loses its network connection. Auto-hides when connectivity returns.
//
// Usage: place once near the top of the widget tree (e.g. in HomeScreen).
// No provider, no main.dart changes — fully self-managing.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;
  late final AnimationController _animCtrl;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );

    // Check initial state
    Connectivity().checkConnectivity().then((results) {
      _handleResults(results);
    });

    // Listen for changes
    _subscription = Connectivity().onConnectivityChanged.listen(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (offline != _isOffline && mounted) {
      setState(() => _isOffline = offline);
      if (offline) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnim,
      builder: (context, child) {
        if (!_isOffline && _animCtrl.isDismissed) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: (_slideAnim.value + 1.0).clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF3E0),
          border: Border(
            bottom: BorderSide(color: Color(0xFFFFCC02), width: 1),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 16, color: Color(0xFFF57C00)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'You\'re offline — changes will sync when reconnected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFE65100),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
