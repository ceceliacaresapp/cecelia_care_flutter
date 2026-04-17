import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/cached_avatar.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController =
      TextEditingController();
  final TextEditingController _dateOfBirthController =
      TextEditingController();
  final TextEditingController _relationshipController =
      TextEditingController();
  final TextEditingController _sexualOrientationController =
      TextEditingController();
  final TextEditingController _genderIdentityController =
      TextEditingController();
  final TextEditingController _preferredPronounsController =
      TextEditingController();
  final TextEditingController _userGoalsController =
      TextEditingController();

  UserProfile? _originalProfile;

  // Photo upload state
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final UserProfile? profile = userProfileProvider.userProfile;

    if (profile != null) {
      _originalProfile = profile;
      _displayNameController.text = profile.displayName;
      _dateOfBirthController.text = profile.dateOfBirth ?? '';
      _relationshipController.text = profile.relationshipToElder ?? '';
      _sexualOrientationController.text =
          profile.sexualOrientation ?? '';
      _genderIdentityController.text = profile.genderIdentity ?? '';
      _preferredPronounsController.text =
          profile.preferredPronouns ?? '';
      _userGoalsController.text = profile.userGoals ?? '';
    } else {
      userProfileProvider.loadCurrentUserProfile();
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _dateOfBirthController.dispose();
    _relationshipController.dispose();
    _sexualOrientationController.dispose();
    _genderIdentityController.dispose();
    _preferredPronounsController.dispose();
    _userGoalsController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photo picker — picks, uploads to Storage, saves URL via provider
  // ---------------------------------------------------------------------------

  Future<void> _pickAndUploadPhoto() async {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final profile = userProfileProvider.userProfile;
    if (profile == null) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            if (profile.avatarUrl?.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await userProfileProvider
                      .updateUserProfile({'avatarUrl': null});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile photo removed.')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? file =
        await picker.pickImage(source: source, imageQuality: 80);
    if (file == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_photos/${profile.uid}/profile.jpg');

      await ref.putFile(File(file.path));
      final String url = await ref.getDownloadURL();

      await userProfileProvider.updateUserProfile({'avatarUrl': url});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('MyAccountScreen: photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo upload failed: ${e.toString()}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Date picker
  // ---------------------------------------------------------------------------

  Future<void> _selectDate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    DateTime initialDate = DateTime.now();

    if (_dateOfBirthController.text.isNotEmpty) {
      try {
        initialDate = DateFormat('yyyy-MM-dd')
            .parse(_dateOfBirthController.text);
      } catch (e) {
        debugPrint('Error parsing DOB for date picker: $e');
        initialDate = DateTime.now();
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: l10n.settingsHintDOB,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Save profile
  // ---------------------------------------------------------------------------

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final UserProfile? profile = userProfileProvider.userProfile;

    if (profile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsUserProfileNotLoaded)),
        );
      }
      return;
    }

    final newDisplayName = _displayNameController.text.trim();
    final newDOB = _dateOfBirthController.text.trim();
    final newRelationship = _relationshipController.text.trim();
    final newSexualOrientation =
        _sexualOrientationController.text.trim();
    final newGenderIdentity = _genderIdentityController.text.trim();
    final newPreferredPronouns =
        _preferredPronounsController.text.trim();
    final newUserGoals = _userGoalsController.text.trim();

    if (_originalProfile != null &&
        newDisplayName == _originalProfile!.displayName &&
        newDOB == (_originalProfile!.dateOfBirth ?? '') &&
        newRelationship ==
            (_originalProfile!.relationshipToElder ?? '') &&
        newSexualOrientation ==
            (_originalProfile!.sexualOrientation ?? '') &&
        newGenderIdentity ==
            (_originalProfile!.genderIdentity ?? '') &&
        newPreferredPronouns ==
            (_originalProfile!.preferredPronouns ?? '') &&
        newUserGoals == (_originalProfile!.userGoals ?? '')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsProfileNoChanges)),
        );
      }
      return;
    }

    final Map<String, dynamic> updates = {
      'displayName': newDisplayName,
      'dateOfBirth': newDOB.isNotEmpty ? newDOB : null,
      'relationshipToElder':
          newRelationship.isNotEmpty ? newRelationship : null,
      'sexualOrientation':
          newSexualOrientation.isNotEmpty ? newSexualOrientation : null,
      'genderIdentity':
          newGenderIdentity.isNotEmpty ? newGenderIdentity : null,
      'preferredPronouns':
          newPreferredPronouns.isNotEmpty ? newPreferredPronouns : null,
      'userGoals': newUserGoals.isNotEmpty ? newUserGoals : null,
    };

    try {
      await userProfileProvider.updateUserProfile(updates);
      _originalProfile = userProfileProvider.userProfile?.copyWith(
        displayName: newDisplayName,
        dateOfBirth: newDOB.isNotEmpty ? newDOB : null,
        relationshipToElder:
            newRelationship.isNotEmpty ? newRelationship : null,
        sexualOrientation:
            newSexualOrientation.isNotEmpty ? newSexualOrientation : null,
        genderIdentity:
            newGenderIdentity.isNotEmpty ? newGenderIdentity : null,
        preferredPronouns:
            newPreferredPronouns.isNotEmpty ? newPreferredPronouns : null,
        userGoals: newUserGoals.isNotEmpty ? newUserGoals : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsProfileUpdatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  l10n.settingsErrorUpdatingProfile(e.toString()))),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context);
    final UserProfile? userProfile = userProfileProvider.userProfile;
    final bool isLoading = userProfileProvider.isLoading;

    if (userProfile != null &&
        _originalProfile?.uid != userProfile.uid) {
      _loadProfileData();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitleMyAccount),
      ),
      body: isLoading && userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : userProfile == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      l10n.settingsErrorLoadingProfile,
                      style: AppStyles.emptyStateText,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: AppStyles.screenPadding,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Profile photo ──────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: _isUploadingPhoto
                                ? null
                                : _pickAndUploadPhoto,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CachedAvatar(
                                  imageUrl: userProfile.avatarUrl,
                                  radius: 48,
                                  backgroundColor: AppTheme.primaryColor
                                      .withAlpha(
                                          (255 * 0.2).round()),
                                  fallbackChild: _isUploadingPhoto
                                      ? const CircularProgressIndicator()
                                      : (userProfile
                                                  .displayName.isNotEmpty
                                              ? Text(
                                                  userProfile
                                                      .displayName[0]
                                                      .toUpperCase(),
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    color: AppTheme
                                                        .primaryColor,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.person,
                                                  size: 48,
                                                  color:
                                                      AppTheme.primaryColor,
                                                )),
                                ),
                                // Camera badge
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Tap to change photo',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Display name ───────────────────────────────
                        Text(
                          l10n.settingsLabelDisplayName,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: InputDecoration(
                              hintText: l10n.settingsHintDisplayName),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return l10n
                                  .settingsDisplayNameCannotBeEmpty;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── User goals ─────────────────────────────────
                        Text(
                          l10n.settingsLabelUserGoals,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _userGoalsController,
                          decoration: InputDecoration(
                              hintText: l10n.settingsHintUserGoals),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // ── Date of birth ──────────────────────────────
                        Text(
                          l10n.settingsLabelDOB,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _dateOfBirthController,
                          decoration: InputDecoration(
                            hintText: l10n.settingsHintDOB,
                            suffixIcon: const Icon(
                                Icons.calendar_today,
                                color: AppTheme.primaryColor),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                        ),
                        const SizedBox(height: 16),

                        // ── Relationship ───────────────────────────────
                        Text(
                          l10n.settingsLabelRelationshipToElder,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _relationshipController,
                          decoration: InputDecoration(
                              hintText: l10n
                                  .settingsHintRelationshipToElder),
                        ),
                        const SizedBox(height: 16),

                        // ── Sexual orientation ─────────────────────────
                        Text(
                          l10n.settingsLabelSexualOrientation,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _sexualOrientationController,
                          decoration: InputDecoration(
                              hintText:
                                  l10n.settingsHintSexualOrientation),
                        ),
                        const SizedBox(height: 16),

                        // ── Gender identity ────────────────────────────
                        Text(
                          l10n.settingsLabelGenderIdentity,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _genderIdentityController,
                          decoration: InputDecoration(
                              hintText:
                                  l10n.settingsHintGenderIdentity),
                        ),
                        const SizedBox(height: 16),

                        // ── Preferred pronouns ─────────────────────────
                        Text(
                          l10n.settingsLabelPreferredPronouns,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: _preferredPronounsController,
                          decoration: InputDecoration(
                              hintText:
                                  l10n.settingsHintPreferredPronouns),
                        ),
                        const SizedBox(height: 24),

                        // ── Save button ────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading &&
                                    userProfileProvider.userProfile ==
                                        null
                                ? null
                                : _handleSaveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                            ),
                            child: userProfileProvider.isLoading &&
                                    userProfileProvider.userProfile !=
                                        null
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: AppTheme.textOnPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.settingsButtonSaveProfile),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }
}
