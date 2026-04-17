// lib/services/biometric_lock_service.dart
//
// Singleton managing the biometric app-lock feature.
//
// - Persists enabled/disabled state via SharedPreferences.
// - Wraps `local_auth` so the rest of the app never imports it.
// - Exposes `authenticate()` which triggers the OS biometric prompt
//   (FaceID / fingerprint / PIN fallback).
// - The UI layer wraps the app in a `BiometricLockGate` widget that
//   observes `AppLifecycleState` and shows a lock overlay on resume
//   when the feature is enabled.
//
// Platform config required (user must do this manually):
//   Android: <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
//            in AndroidManifest.xml.
//   iOS:     NSFaceIDUsageDescription key in Info.plist.
//
// See the summary at the bottom of the feature implementation for
// exact copy-paste snippets.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricLockService {
  BiometricLockService._();
  static final BiometricLockService instance = BiometricLockService._();

  static const String _enabledKey = 'biometric_lock_enabled';

  final LocalAuthentication _auth = LocalAuthentication();

  bool? _enabled;
  bool? _deviceSupported;

  /// Whether the user has turned the lock on. Returns `false` until
  /// [init] has been called.
  bool get isEnabled => _enabled ?? false;

  /// Whether the device has any enrolled biometrics. Updated on [init].
  bool get isDeviceSupported => _deviceSupported ?? false;

  /// Call once at app startup (after `WidgetsFlutterBinding.ensureInitialized`).
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? false;

    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      _deviceSupported = canCheck || isSupported;
    } on PlatformException catch (e) {
      debugPrint('BiometricLockService.init error: $e');
      _deviceSupported = false;
    }
  }

  /// Toggle the lock on or off. When enabling, we first verify the user
  /// can authenticate (so they don't lock themselves out if biometrics
  /// aren't enrolled).
  Future<bool> setEnabled(bool value) async {
    if (value && !isDeviceSupported) return false;

    if (value) {
      final passed = await authenticate(
        reason: 'Verify your identity to enable biometric lock',
      );
      if (!passed) return false;
    }

    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    return true;
  }

  /// Trigger the OS biometric prompt. Returns `true` when the user
  /// successfully authenticates (biometric, PIN, or pattern — the OS
  /// decides the fallback chain).
  ///
  /// The [reason] string is shown to the user in the system prompt.
  Future<bool> authenticate({
    String reason = 'Verify your identity to open Cecelia Care',
  }) async {
    if (!isDeviceSupported) return true; // nothing to check

    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN/pattern fallback
        ),
      );
    } on PlatformException catch (e) {
      debugPrint('BiometricLockService.authenticate error: $e');
      // On error (e.g. too many attempts, hardware unavailable) we
      // return true to avoid permanently locking the user out. The OS
      // already enforces its own lockout timer.
      return true;
    }
  }

  /// Available biometric types — useful for the settings toggle to
  /// show "FaceID" vs "Fingerprint" vs "PIN".
  Future<List<BiometricType>> get availableBiometrics async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }
}
