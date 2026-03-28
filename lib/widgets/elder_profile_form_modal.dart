import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// Local constants — consider moving to AppTheme if used globally.
const Color kPrimaryColor = Color(0xFF3366FF);
const Color kTextLight = Colors.grey;
const TextStyle kModalTitleStyle = TextStyle(
  fontSize: 20,
  fontWeight: FontWeight.bold,
  color: Colors.black,
);
const TextStyle kFormLabelStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w600,
);
const InputDecoration kInputDecoration = InputDecoration(
  border: OutlineInputBorder(),
  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
);

// ---------------------------------------------------------------------------
// ElderProfileFormModal
// ---------------------------------------------------------------------------
//
// Builds an AlertDialog when visible == true, otherwise SizedBox.shrink().
//
// The onSubmit callback receives a Map<String,dynamic> with keys:
//   profileName, dateOfBirth, allergies (List<String>),
//   dietaryRestrictions, preferredName, sexualOrientation,
//   genderIdentity, preferredPronouns, emergencyContactName,
//   emergencyContactPhone, emergencyContactRelationship,
//   photoUrl (String? — null means no change / cleared)
// ---------------------------------------------------------------------------

class ElderProfileFormModal extends StatefulWidget {
  final bool visible;
  final VoidCallback onClose;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final Map<String, dynamic>? initialData;
  final String mode; // 'create' | 'edit'

  // elderId is used as the storage path prefix for the profile photo.
  // In create mode it may be null — we fall back to a timestamp-keyed path.
  final String? elderId;

  const ElderProfileFormModal({
    super.key,
    required this.visible,
    required this.onClose,
    required this.onSubmit,
    this.initialData,
    this.mode = 'create',
    this.elderId,
  });

  @override
  State<ElderProfileFormModal> createState() => _ElderProfileFormModalState();
}

class _ElderProfileFormModalState extends State<ElderProfileFormModal> {
  // Text controllers
  late TextEditingController _profileNameController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _allergiesController;
  late TextEditingController _dietaryRestrictionsController;
  late TextEditingController _preferredNameController;
  late TextEditingController _sexualOrientationController;
  late TextEditingController _genderIdentityController;
  late TextEditingController _preferredPronounsController;
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _emergencyContactRelationshipController;

  // Photo state
  String? _photoUrl;          // current URL (existing or newly uploaded)
  bool _isUploadingPhoto = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _profileNameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _allergiesController = TextEditingController();
    _dietaryRestrictionsController = TextEditingController();
    _preferredNameController = TextEditingController();
    _sexualOrientationController = TextEditingController();
    _genderIdentityController = TextEditingController();
    _preferredPronounsController = TextEditingController();
    _emergencyContactNameController = TextEditingController();
    _emergencyContactPhoneController = TextEditingController();
    _emergencyContactRelationshipController = TextEditingController();
    _populateFields();
  }

  @override
  void didUpdateWidget(ElderProfileFormModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible &&
        (oldWidget.visible == false ||
            oldWidget.initialData != widget.initialData ||
            oldWidget.mode != widget.mode)) {
      _populateFields();
    }
  }

  void _populateFields() {
    if (!widget.visible) return;

    if (widget.mode == 'edit' && widget.initialData != null) {
      final data = widget.initialData!;
      _profileNameController.text = data['profileName'] as String? ?? '';
      _dateOfBirthController.text = data['dateOfBirth'] as String? ?? '';
      final allergiesList = data['allergies'] as List<dynamic>? ?? [];
      _allergiesController.text =
          allergiesList.map((e) => e.toString()).join(', ');
      _dietaryRestrictionsController.text =
          data['dietaryRestrictions'] as String? ?? '';
      _preferredNameController.text =
          data['preferredName'] as String? ?? '';
      _sexualOrientationController.text =
          data['sexualOrientation'] as String? ?? '';
      _genderIdentityController.text =
          data['genderIdentity'] as String? ?? '';
      _preferredPronounsController.text =
          data['preferredPronouns'] as String? ?? '';
      _emergencyContactNameController.text =
          data['emergencyContactName'] as String? ?? '';
      _emergencyContactPhoneController.text =
          data['emergencyContactPhone'] as String? ?? '';
      _emergencyContactRelationshipController.text =
          data['emergencyContactRelationship'] as String? ?? '';
      _photoUrl = data['photoUrl'] as String?;
    } else {
      _profileNameController.clear();
      _dateOfBirthController.clear();
      _allergiesController.clear();
      _dietaryRestrictionsController.clear();
      _preferredNameController.clear();
      _sexualOrientationController.clear();
      _genderIdentityController.clear();
      _preferredPronounsController.clear();
      _emergencyContactNameController.clear();
      _emergencyContactPhoneController.clear();
      _emergencyContactRelationshipController.clear();
      _photoUrl = null;
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _dateOfBirthController.dispose();
    _allergiesController.dispose();
    _dietaryRestrictionsController.dispose();
    _preferredNameController.dispose();
    _sexualOrientationController.dispose();
    _genderIdentityController.dispose();
    _preferredPronounsController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Photo picker
  // ---------------------------------------------------------------------------

  Future<void> _pickPhoto() async {
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
            if (_photoUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.red),
                title: const Text('Remove photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _photoUrl = null);
                  Navigator.pop(context);
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
      // Upload to Firebase Storage under elder_profile_photos/{id or timestamp}/
      final String pathKey = widget.elderId ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('elder_profile_photos/$pathKey/profile.jpg');

      await ref.putFile(File(file.path));
      final String url = await ref.getDownloadURL();

      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      debugPrint('ElderProfileFormModal: photo upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Photo upload failed: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _handleSubmit() async {
    final profileName = _profileNameController.text.trim();
    final dob = _dateOfBirthController.text.trim();
    final allergiesRaw = _allergiesController.text;
    final dietary = _dietaryRestrictionsController.text.trim();
    final preferredName = _preferredNameController.text.trim();
    final sexualOrientation = _sexualOrientationController.text.trim();
    final genderIdentity = _genderIdentityController.text.trim();
    final preferredPronouns = _preferredPronounsController.text.trim();
    final emergencyContactName =
        _emergencyContactNameController.text.trim();
    final emergencyContactPhone =
        _emergencyContactPhoneController.text.trim();
    final emergencyContactRelationship =
        _emergencyContactRelationshipController.text.trim();

    if (profileName.isEmpty) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Profile name is required.'),
          actions: [
            TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(c).pop()),
          ],
        ),
      );
      return;
    }

    if (dob.isNotEmpty &&
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text(
              'Date of Birth must be in YYYY-MM-DD format.'),
          actions: [
            TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(c).pop()),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final allergiesList = allergiesRaw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final profileData = <String, dynamic>{
      'profileName': profileName,
      'dateOfBirth': dob,
      'allergies': allergiesList,
      'dietaryRestrictions': dietary,
      'preferredName':
          preferredName.isNotEmpty ? preferredName : null,
      'sexualOrientation':
          sexualOrientation.isNotEmpty ? sexualOrientation : null,
      'genderIdentity':
          genderIdentity.isNotEmpty ? genderIdentity : null,
      'preferredPronouns':
          preferredPronouns.isNotEmpty ? preferredPronouns : null,
      'emergencyContactName':
          emergencyContactName.isNotEmpty ? emergencyContactName : null,
      'emergencyContactPhone':
          emergencyContactPhone.isNotEmpty ? emergencyContactPhone : null,
      'emergencyContactRelationship':
          emergencyContactRelationship.isNotEmpty
              ? emergencyContactRelationship
              : null,
      // NEW: include the photo URL (null if cleared or never set)
      'photoUrl': _photoUrl,
    };

    try {
      await widget.onSubmit(profileData);
    } catch (e) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Submission Error'),
            content: Text('An error occurred: ${e.toString()}'),
            actions: [
              TextButton(
                  child: const Text('OK'),
                  onPressed: () => Navigator.of(c).pop()),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _handleClose() {
    if (_isSubmitting) return;
    widget.onClose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final String nameInitial =
        _profileNameController.text.trim().isNotEmpty
            ? _profileNameController.text.trim()[0].toUpperCase()
            : '?';

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _handleClose,
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 24),
            child: Material(
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      widget.mode == 'edit'
                          ? 'Edit Elder Profile'
                          : 'Create New Elder Profile',
                      style:
                          kModalTitleStyle.copyWith(fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // ── Profile photo picker ─────────────────────
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingPhoto ? null : _pickPhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor:
                                  kPrimaryColor.withOpacity(0.12),
                              backgroundImage:
                                  _photoUrl != null
                                      ? NetworkImage(_photoUrl!)
                                      : null,
                              child: _isUploadingPhoto
                                  ? const CircularProgressIndicator()
                                  : (_photoUrl == null
                                      ? Text(
                                          nameInitial,
                                          style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryColor,
                                          ),
                                        )
                                      : null),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: kPrimaryColor,
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
                        'Tap to add photo',
                        style: TextStyle(
                            fontSize: 12, color: kTextLight),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Profile Name ─────────────────────────────
                    const Text('Profile Name*',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _profileNameController,
                      onChanged: (_) =>
                          setState(() {}), // refresh initial for avatar
                      decoration: kInputDecoration.copyWith(
                        hintText: "Elder's Full Name or Nickname",
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ── Date of Birth ────────────────────────────
                    const Text('Date of Birth (YYYY-MM-DD)',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dateOfBirthController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'YYYY-MM-DD',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      keyboardType: TextInputType.datetime,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ── Allergies ────────────────────────────────
                    const Text('Allergies (comma-separated)',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _allergiesController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., Peanuts, Aspirin',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ── Dietary Restrictions ─────────────────────
                    const Text('Dietary Restrictions',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dietaryRestrictionsController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., Low sodium, no gluten',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // ── Preferred Name ───────────────────────────
                    const Text('Preferred Name',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _preferredNameController,
                      decoration: kInputDecoration.copyWith(
                        hintText:
                            "Elder's Preferred Name (Optional)",
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ── Sexual Orientation ───────────────────────
                    const Text('Sexual Orientation',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _sexualOrientationController,
                      decoration: kInputDecoration.copyWith(
                        hintText:
                            'e.g., Lesbian, Bisexual (Optional)',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ── Gender Identity ──────────────────────────
                    const Text('Gender Identity',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _genderIdentityController,
                      decoration: kInputDecoration.copyWith(
                        hintText:
                            'e.g., Woman, Non-binary (Optional)',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ── Preferred Pronouns ───────────────────────
                    const Text('Preferred Pronouns',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _preferredPronounsController,
                      decoration: kInputDecoration.copyWith(
                        hintText:
                            'e.g., she/her, they/them (Optional)',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // ── Emergency Contact ────────────────────────
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Emergency Contact Information',
                      style:
                          kModalTitleStyle.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text('Contact Name',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emergencyContactNameController,
                      decoration: kInputDecoration.copyWith(
                        hintText:
                            "Emergency Contact's Full Name (Optional)",
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const Text('Contact Phone',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emergencyContactPhoneController,
                      decoration: kInputDecoration.copyWith(
                        hintText:
                            'e.g., +1 (555) 123-4567 (Optional)',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    const Text('Relationship to Care Recipient',
                        style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller:
                          _emergencyContactRelationshipController,
                      decoration: kInputDecoration.copyWith(
                        hintText:
                            'e.g., Son, Daughter, Neighbor (Optional)',
                        hintStyle:
                            const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),

                    // ── Action buttons ───────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : _handleClose,
                          style: TextButton.styleFrom(
                            foregroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation<
                                            Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  widget.mode == 'edit'
                                      ? 'Save Changes'
                                      : 'Create Profile',
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
