import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/models/user_profile.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  /// Onboarding flag read directly from Firestore snapshot.
  /// null = not yet loaded or field missing (existing user → no onboarding).
  /// false = new account, needs onboarding.
  /// true = onboarding completed.
  bool? _onboardingCompleted;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _errorMessage;

  /// Returns true only if the field is explicitly false (new account).
  /// Missing field / null / true all return false → no onboarding.
  bool get needsOnboarding => _onboardingCompleted == false;

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  UserProfileProvider() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscribeToUserProfile(user.uid);
      } else {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        _userProfile = null;
        _onboardingCompleted = null;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _userProfile = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } else {
      _subscribeToUserProfile(user.uid);
    }
  }

  void _subscribeToUserProfile(String uid) {
    _profileSubscription?.cancel();

    if (!_isLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
      (docSnapshot) async {
        _errorMessage = null;
        if (docSnapshot.exists) {
          _userProfile = UserProfile.fromFirestore(docSnapshot, null);
          // Read onboarding flag directly from raw snapshot data.
          final data = docSnapshot.data();
          _onboardingCompleted = data?['onboardingCompleted'] as bool?;
        } else {
          // Auto-create a minimal profile document for new users.
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && user.uid == uid) {
            String newDisplayName;
            if (user.displayName != null && user.displayName!.isNotEmpty) {
              newDisplayName = user.displayName!;
            } else if (user.email != null &&
                user.email!.contains('@')) {
              newDisplayName = user.email!.split('@')[0];
              if (newDisplayName.isEmpty && user.email!.isNotEmpty) {
                newDisplayName = user.email!;
              } else if (newDisplayName.isEmpty) {
                newDisplayName = user.uid;
              }
            } else if (user.email != null && user.email!.isNotEmpty) {
              newDisplayName = user.email!;
            } else {
              newDisplayName = user.uid;
            }

            final newData = {
              'displayName': newDisplayName,
              'email': user.email ?? '',
              'dateOfBirth': null,
              'relationshipToElder': null,
              'preferredTerm': null,
              'avatarUrl': user.photoURL,
              'userGoals': null,
              // Onboarding flag — only new accounts get false.
              // Existing users without this field are treated as completed.
              'onboardingCompleted': false,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            };

            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .set(newData);
            // Stream will emit the new document automatically —
            // no need to manually set _userProfile here.
          } else {
            _userProfile = null;
          }
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint(
            'UserProfileProvider: Error subscribing to user profile: $error');
        _userProfile = null;
        _errorMessage =
            'Failed to load your profile: ${error.toString()}';
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // updateUserProfile — generic field map update.
  //
  // Used by both MyAccountScreen (text fields) and the photo upload flow in
  // my_account_screen.dart. The photo upload calls:
  //   updateUserProfile({'avatarUrl': url})
  // to persist the URL. No separate updateAvatarUrl method is needed because
  // this method already accepts any Firestore-compatible key/value map.
  //
  // After a successful Firestore write the real-time stream listener picks up
  // the change and rebuilds _userProfile via fromFirestore automatically, so
  // no manual copyWith is required here.
  // ---------------------------------------------------------------------------
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) {
      debugPrint(
          'UserProfileProvider: User not logged in or profile not loaded. Cannot update.');
      _errorMessage =
          'Cannot update profile: Not logged in or profile unavailable.';
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('UserProfileProvider: Error updating user profile: $e');
      _errorMessage =
          'Failed to update your profile. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await FirebaseAuth.instance.signOut();
      _userProfile = null;
      _onboardingCompleted = null;
      _errorMessage = null;
    } catch (e) {
      debugPrint('UserProfileProvider: Error signing out: $e');
      _errorMessage = 'Error signing out. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
