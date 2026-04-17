// lib/widgets/biometric_lock_gate.dart
//
// Full-screen gate that overlays the app when the biometric lock is
// enabled and the app resumes from background (or cold-starts). The
// user must authenticate via the OS biometric prompt before the
// overlay lifts.
//
// Emergency bypass: a clearly-labeled button opens the Emergency Card
// screen WITHOUT requiring auth — because if the caregiver is
// incapacitated and someone else picks up their phone, emergency info
// must be reachable. The emergency card is read-only and contains no
// PHI beyond what's on the lock-screen card — it's the same info a
// first responder would see on the wallpaper.

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/screens/emergency_card_screen.dart';
import 'package:cecelia_care_flutter/services/biometric_lock_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class BiometricLockGate extends StatefulWidget {
  const BiometricLockGate({super.key, required this.child});
  final Widget child;

  @override
  State<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends State<BiometricLockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  bool _authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // On cold start: if the lock is enabled, show the overlay and
    // immediately trigger the prompt so the user isn't staring at a
    // blank lock screen.
    if (BiometricLockService.instance.isEnabled) {
      _locked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _locked) _tryAuthenticate();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockService = BiometricLockService.instance;
    if (!lockService.isEnabled) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      // App going to background — arm the lock.
      if (mounted) setState(() => _locked = true);
    } else if (state == AppLifecycleState.resumed && _locked) {
      // Returned to foreground — trigger auth.
      _tryAuthenticate();
    }
  }

  Future<void> _tryAuthenticate() async {
    if (_authenticating) return;
    _authenticating = true;

    final passed = await BiometricLockService.instance.authenticate();

    _authenticating = false;
    if (mounted && passed) {
      setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked) _LockOverlay(onUnlock: _tryAuthenticate),
      ],
    );
  }
}

/// The overlay shown when the app is locked. Dark background, logo,
/// "Unlock" button, and "Emergency Card" bypass.
class _LockOverlay extends StatelessWidget {
  const _LockOverlay({required this.onUnlock});
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D1117),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Logo / app icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cecelia Care is locked',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use your fingerprint, face, or device PIN to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Unlock button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: onUnlock,
                  icon: const Icon(Icons.fingerprint, size: 22),
                  label: const Text(
                    'Unlock',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const Spacer(flex: 3),
              // Emergency bypass
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.dangerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  border: Border.all(
                      color: AppTheme.dangerColor.withValues(alpha: 0.35)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.medical_information_outlined,
                            color: AppTheme.dangerColor, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'EMERGENCY ACCESS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppTheme.dangerColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'View emergency medical info without unlocking.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const EmergencyCardScreen(),
                          ));
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open Emergency Card'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerColor,
                          side: BorderSide(
                              color: AppTheme.dangerColor
                                  .withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
