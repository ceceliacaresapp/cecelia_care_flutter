import 'package:flutter/material.dart';
import 'dart:async'; // Added for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import the UserProfile model from its dedicated file
import 'package:cecelia_care_flutter/models/user_profile.dart';

// The local UserProfile class that was here has been REMOVED.
// We will now use the one imported from lib/models/user_profile.dart

class UserProfileProvider extends ChangeNotifier {
  UserProfile?
  _userProfile; // This will be an instance of the imported UserProfile model
  bool _isLoading = true; // Tracks loading of the profile data
  String? _errorMessage; // For exposing errors to the UI
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _profileSubscription;

  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading; // General loading state for profile data
  String? get error => _errorMessage; // Renamed getter for consistency

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }

  UserProfileProvider() {
    // Listen to auth state changes to automatically load/clear profile
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user != null) {
        _subscribeToUserProfile(user.uid);
      } else {
        _profileSubscription?.cancel();
        _profileSubscription = null;
        _userProfile = null;
        _isLoading = false; // No user, so not loading profile
        _errorMessage = null;
        notifyListeners();
      }
    });
  }

  Future<void> loadCurrentUserProfile() async {
    // This method can be kept for one-time explicit refresh if needed,
    // but primary loading is now handled by _subscribeToUserProfile.
    // For now, let's ensure it calls the subscription method.
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
    _profileSubscription?.cancel(); // Cancel any existing subscription

    if (!_isLoading) {
      // Only set loading if not already loading
      _isLoading = true;
      _errorMessage = null; // Clear error on new subscription attempt
      notifyListeners();
    }

    _profileSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (docSnapshot) async {
            // Made async to handle profile creation
            _errorMessage = null; // Clear error on successful data
            if (docSnapshot.exists) {
              _userProfile = UserProfile.fromFirestore(docSnapshot, null);
            } else {
              // If no profile doc exists, create a minimal one:
              final user = FirebaseAuth
                  .instance
                  .currentUser; // Re-fetch current user for latest details
              if (user != null && user.uid == uid) {
                // Ensure we are creating for the correct, current user
                String newDisplayName;
                if (user.displayName != null && user.displayName!.isNotEmpty) {
                  newDisplayName = user.displayName!;
                } else if (user.email != null && user.email!.contains('@')) {
                  newDisplayName = user.email!.split('@')[0];
                  if (newDisplayName.isEmpty && user.email!.isNotEmpty) { // e.g. email is "@domain.com"
                    newDisplayName = user.email!; // use full email if split part is empty but email is not
                  } else if (newDisplayName.isEmpty) { // if email was just "@" or empty after split
                     newDisplayName = user.uid; // fallback if split results in empty
                  }
                } else if (user.email != null && user.email!.isNotEmpty) {
                  newDisplayName = user.email!; // Use full email if no @
                } else {
                  newDisplayName = user.uid; // Ultimate fallback
                }

                final newData = {
                  'displayName': newDisplayName,
                  'email': user.email ?? '',
                  'dateOfBirth': null,
                  'relationshipToElder': null,
                  'preferredTerm': null,
                  'avatarUrl': user.photoURL,
                  'createdAt': FieldValue.serverTimestamp(),
                  'updatedAt':
                      FieldValue.serverTimestamp(), // Also set updatedAt on creation
                };
                // No need to use the UserProfile.toFirestore() here as we are setting raw data
                // for a document that will then be read by UserProfile.fromFirestore.
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set(newData);
                // The stream will automatically emit the new document, so no need to manually set _userProfile here.
                // _userProfile will be updated in the next snapshot event.
              } else {
                _userProfile =
                    null; // User changed during creation attempt or other issue
              }
            }
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint(
              'UserProfileProvider: Error subscribing to user profile: $error',
            );
            _userProfile = null;
            _errorMessage = 'Failed to load your profile: ${error.toString()}';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userProfile == null) {
      debugPrint(
        'UserProfileProvider: User not logged in or profile not loaded. Cannot update.',
      );
      _errorMessage =
          'Cannot update profile: Not logged in or profile unavailable.';
      return;
    }

    _isLoading = true;
    _errorMessage = null; // Clear previous errors
    notifyListeners();

    try {
      // Ensure 'updatedAt' is part of the updates if you track it
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update(updates);

      // Efficiently update local profile
      // This requires UserProfile to have a copyWith method or manual update
      if (_userProfile != null) {
        // Using copyWith for a cleaner update
        // The stream will update the _userProfile automatically.
        // No need for manual copyWith here if the update is successful.
        // _userProfile = _userProfile!.copyWith(
        //   displayName: updates['displayName'] ?? _userProfile!.displayName,
        //   dateOfBirth: updates.containsKey('dateOfBirth') ? updates['dateOfBirth'] : _userProfile!.dateOfBirth, // Handle null explicitly
        //   avatarUrl: updates.containsKey('avatarUrl') ? updates['avatarUrl'] : _userProfile!.avatarUrl, // Handle null explicitly
        //   relationshipToElder: updates.containsKey('relationshipToElder') ? updates['relationshipToElder'] : _userProfile!.relationshipToElder, // Handle null explicitly
        //   preferredTerm: updates.containsKey('preferredTerm') ? updates['preferredTerm'] : _userProfile!.preferredTerm, // Handle preferredTerm
        //   updatedAt: updates['updatedAt'] is Timestamp ? updates['updatedAt'] : _userProfile!.updatedAt, // Ensure it's a Timestamp
        // );
        _isLoading = false;
        notifyListeners();
      } else {
        // Fallback to re-fetch if local profile somehow became null
        await loadCurrentUserProfile();
      }
    } catch (e) {
      debugPrint('UserProfileProvider: Error updating user profile: $e');
      _errorMessage = 'Failed to update your profile. Please try again.';
      // Revert loading state on error
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    _errorMessage = null; // Clear previous errors
    try {
      await FirebaseAuth.instance.signOut();
      // _profileSubscription is cancelled by the authStateChanges listener
      // _userProfile is cleared by the authStateChanges listener
      _userProfile = null;
      _errorMessage =
          null; // Successfully signed out, clear any potential error
      // _isLoading will be set to false by the authStateChanges listener triggering loadCurrentUserProfile
    } catch (e) {
      debugPrint('UserProfileProvider: Error signing out: $e');
      _errorMessage = 'Error signing out. Please try again.';
      _isLoading =
          false; // Explicitly set false on error if authStateChanges doesn't fire as expected
      notifyListeners();
    }
    // No need for finally _isLoading = false; notifyListeners(); if authStateChanges handles it.
    // However, to be safe during the sign-out process itself:
    if (_isLoading) {
      // If authStateChanges hasn't already set it
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
