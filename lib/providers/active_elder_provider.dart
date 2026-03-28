import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/elder_profile.dart';
import '../models/caregiver_role.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';

// --- I18N UPDATE ---
/// A data class to hold structured error information for localization.
class ActiveElderError {
  /// A key to identify the type of error, e.g., 'load_failed', 'update_failed'.
  final String type;
  /// The raw error message for debugging purposes.
  final String details;

  ActiveElderError({required this.type, required this.details});
}


/// Manages the state of the currently active `ElderProfile`.
///
/// This provider handles the complex logic of determining which elder profile
/// is active for the current user. It listens to authentication state changes
/// and synchronizes the active elder's ID between Firestore and local device
/// storage (`SharedPreferences`) to ensure the user's choice is remembered
/// across sessions.
class ActiveElderProvider with ChangeNotifier {
  final FirestoreService _firestoreService;
  final SharedPreferences _prefs;
  StreamSubscription<User?>? _authSubscription;

  static const String _prefsKey = 'activeElderId';

  // --- State Properties ---
  ElderProfile? _activeElder;
  bool _isLoading = true;
  // --- I18N UPDATE ---
  // Replaced the simple String with a structured error object.
  ActiveElderError? _errorInfo;


  String? _initializedForUid;

  // --- Getters ---
  ElderProfile? get activeElder => _activeElder;
  bool get isLoading => _isLoading;
  // --- I18N UPDATE ---
  // Getter returns the new error object. The UI can use this to show a localized message.
  ActiveElderError? get errorInfo => _errorInfo;

  /// The current Firebase Auth user's role on the active elder profile.
  ///
  /// Returns [CaregiverRole.unknown] when there is no active elder or no
  /// signed-in user. Components should call this instead of checking
  /// primaryAdminUserId directly — it accounts for caregiverRoles and the
  /// backwards-compat caregiver fallback in ElderProfile.roleForUser().
  CaregiverRole get currentUserRole {
    final elder = _activeElder;
    if (elder == null) return CaregiverRole.unknown;
    final uid = _initializedForUid;
    return elder.roleForUser(uid);
  }

  /// Convenience — true when the current user is an admin on the active elder.
  bool get isAdmin => currentUserRole == CaregiverRole.admin;

  /// Convenience — true when the current user can log entries.
  bool get canLog => currentUserRole.canLog;

  /// Convenience — true when the current user can send messages.
  bool get canMessage => currentUserRole.canMessage;

  ActiveElderProvider(this._firestoreService, this._prefs) {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _initializeForUser(user?.uid);
    });
  }

  Future<void> _initializeForUser(String? uid) async {
    if (_initializedForUid == uid && uid != null) {
      debugPrint('ActiveElderProvider: Already initialized for user $uid. Skipping.');
      return;
    }

    if (uid == null) {
      debugPrint('ActiveElderProvider: User logged out. Clearing state.');
      _activeElder = null;
      _isLoading = false;
      _errorInfo = null;
      _initializedForUid = null;
      notifyListeners();
      return;
    }

    debugPrint('ActiveElderProvider: Initializing for user $uid.');
    _isLoading = true;
    _initializedForUid = uid;
    _activeElder = null;
    _errorInfo = null;
    notifyListeners();

    await _loadAndSetInitialElder(uid);
  }

  Future<void> _loadAndSetInitialElder(String uid) async {
    try {
      UserProfile? userProfile = await _firestoreService.getUserProfile(uid);
      String? preferredElderId = userProfile?.activeElderId ?? _prefs.getString(_prefsKey);
      debugPrint("ActiveElderProvider: Preferred elder ID is '$preferredElderId'.");

      ElderProfile? potentialElder;
      if (preferredElderId != null && preferredElderId.isNotEmpty) {
        potentialElder = await _firestoreService.getElderProfile(preferredElderId);
        if (potentialElder == null || !potentialElder.caregiverUserIds.contains(uid)) {
          potentialElder = null;
        }
      }

      if (potentialElder == null) {
        debugPrint('ActiveElderProvider: No valid preferred elder. Attempting to auto-select.');
        final elders = await _firestoreService.getMyEldersStream(uid).first;
        if (elders.isNotEmpty) {
          elders.sort((a, b) => (a.priorityIndex ?? 999).compareTo(b.priorityIndex ?? 999));
          potentialElder = elders.first;
        }
      }

      _activeElder = potentialElder;
      if (_activeElder != null) {
        debugPrint("ActiveElderProvider: Final active elder is '${_activeElder!.profileName}'.");
        await _syncActiveElderId(uid, _activeElder!.id, userProfile?.activeElderId);
      } else {
        debugPrint('ActiveElderProvider: No elders available for this user.');
        await _syncActiveElderId(uid, null, userProfile?.activeElderId);
      }
      _errorInfo = null;
    } catch (e, s) {
      debugPrint('ActiveElderProvider._loadAndSetInitialElder error: $e\n$s');
      // --- I18N UPDATE ---
      _errorInfo = ActiveElderError(type: 'load_initial_failed', details: e.toString());
      _activeElder = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActive(ElderProfile elder) async {
    final String? uid = _initializedForUid;
    if (uid == null) {
      // --- I18N UPDATE ---
      _errorInfo = ActiveElderError(type: 'set_active_not_logged_in', details: 'User not logged in.');
      notifyListeners();
      return;
    }
    if (elder.id == _activeElder?.id) return;

    _isLoading = true;
    _errorInfo = null;
    notifyListeners();

    ElderProfile? previousElder = _activeElder;

    try {
      if (!elder.caregiverUserIds.contains(uid)) {
        // --- I18N UPDATE ---
        // Instead of throwing an exception with a hardcoded string, set the structured error.
        _errorInfo = ActiveElderError(type: 'set_active_not_caregiver', details: 'User is not a caregiver for the selected elder.');
        throw Exception(_errorInfo!.details); // Throw to stop execution, details are for debug log.
      }
      _activeElder = elder;
      await _syncActiveElderId(uid, elder.id, previousElder?.id);
      debugPrint("ActiveElderProvider: Manually set active elder to '${elder.profileName}'.");
    } catch (e, s) {
      debugPrint('ActiveElderProvider.setActive error: $e\n$s');
      // Set the error only if it hasn't been set by a specific check above.
      _errorInfo ??= ActiveElderError(type: 'set_active_failed', details: e.toString());
      _activeElder = previousElder; // Revert on failure.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncActiveElderId(String uid, String? newElderId, String? cloudElderId) async {
    List<Future<void>> syncTasks = [];

    if (_prefs.getString(_prefsKey) != newElderId) {
      if (newElderId == null) {
        syncTasks.add(_prefs.remove(_prefsKey));
      } else {
        syncTasks.add(_prefs.setString(_prefsKey, newElderId));
      }
    }

    if (cloudElderId != newElderId) {
      syncTasks.add(_firestoreService.setUserActiveElder(uid, newElderId));
    }

    if (syncTasks.isNotEmpty) {
      await Future.wait(syncTasks);
      debugPrint("ActiveElderProvider: Synced active elder ID '$newElderId'.");
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
