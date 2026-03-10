import 'package:flutter/material.dart';
// Assuming your AppTheme and AppStyles are set up for consistent styling.
// If kPrimaryColor etc. are meant to be from your theme, import them.
// For now, using the local constants as defined in your original file.
// import 'package:cecelia_care_flutter/utils/app_theme.dart';
// import 'package:cecelia_care_flutter/utils/app_styles.dart';

// Local constants as provided in your file.
// Consider moving these to a central theme/style file if used globally.
const Color kPrimaryColor = Color(
  0xFF3366FF,
); // Example, use your AppTheme.primaryColor if available
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

// --------------------------------------------------------------------
// ElderProfileFormModal
// --------------------------------------------------------------------
//
// This widget builds an AlertDialog when visible == true, otherwise it
// returns SizedBox.shrink().
// The onSubmit callback receives a Map<String,dynamic> with keys:
//   profileName, dateOfBirth, allergies (List<String>), dietaryRestrictions.
// --------------------------------------------------------------------

class ElderProfileFormModal extends StatefulWidget {
  /// Whether to show the dialog. If false, widget builds nothing.
  final bool visible;

  /// Called when the user taps “Cancel” or after a successful submission.
  final VoidCallback onClose;

  /// Called when the form is submitted (create or update). The map contains:
  /// {
  ///   'profileName': String,
  ///   'dateOfBirth': String, // YYYY-MM-DD format
  ///   'allergies': List<String>,
  ///   'dietaryRestrictions': String,
  ///   'preferredName': String?,
  ///   'sexualOrientation': String?,
  ///   'genderIdentity': String?,
  ///   'preferredPronouns': String?,
  ///   'emergencyContactName': String?,
  ///   'emergencyContactPhone': String?,
  ///   'emergencyContactRelationship': String?,  
  /// }
  /// Should return a Future that completes when the save is done.
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  /// If mode == 'edit', initialData should be non-null and contain keys:
  ///   'profileName', 'dateOfBirth', 'allergies', 'dietaryRestrictions',
  ///   'preferredName', 'sexualOrientation', 'genderIdentity', 'preferredPronouns'
  ///   'emergencyContactName', 'emergencyContactPhone', 'emergencyContactRelationship'
  /// If mode == 'create', initialData can be null or ignored.
  final Map<String, dynamic>? initialData;

  /// Either 'create' or 'edit'. Controls the dialog title and the submit button text.
  final String mode;

  const ElderProfileFormModal({
    super.key,
    required this.visible,
    required this.onClose,
    required this.onSubmit,
    this.initialData,
    this.mode = 'create',
  });

  @override
  State<ElderProfileFormModal> createState() => _ElderProfileFormModalState();
}

class _ElderProfileFormModalState extends State<ElderProfileFormModal> {
  // Controllers for each field
  late TextEditingController _profileNameController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _allergiesController;
  late TextEditingController _dietaryRestrictionsController;
  // New SOGI controllers
  late TextEditingController _preferredNameController;
  late TextEditingController _sexualOrientationController;
  late TextEditingController _genderIdentityController;
  late TextEditingController _preferredPronounsController;
  // NEW: Emergency Contact controllers
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;
  late TextEditingController _emergencyContactRelationshipController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _profileNameController = TextEditingController();
    _dateOfBirthController = TextEditingController();
    _allergiesController = TextEditingController();
    _dietaryRestrictionsController = TextEditingController();
    // Initialize new SOGI controllers
    _preferredNameController = TextEditingController();
    _sexualOrientationController = TextEditingController();
    _genderIdentityController = TextEditingController();
    _preferredPronounsController = TextEditingController();
    // NEW: Initialize emergency contact controllers
    _emergencyContactNameController = TextEditingController();
    _emergencyContactPhoneController = TextEditingController();
    _emergencyContactRelationshipController = TextEditingController();    
    _populateFields();
  }

  @override
  void didUpdateWidget(ElderProfileFormModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If visibility changed from false→true, or initialData changed, or mode changed, re-populate:
    if (widget.visible &&
        (oldWidget.visible == false ||
            oldWidget.initialData != widget.initialData ||
            oldWidget.mode != widget.mode)) {
      _populateFields();
    }
  }

  void _populateFields() {
    if (widget.visible) {
      if (widget.mode == 'edit' && widget.initialData != null) {
        final data = widget.initialData!;
        _profileNameController.text = data['profileName'] as String? ?? '';
        _dateOfBirthController.text = data['dateOfBirth'] as String? ?? '';
        // Allergies are stored as List<String> in the model, but edited as comma-separated string
        final allergiesList = data['allergies'] as List<dynamic>? ?? [];
        _allergiesController.text = allergiesList
            .map((e) => e.toString())
            .join(', ');
        _dietaryRestrictionsController.text =
            data['dietaryRestrictions'] as String? ?? '';
        // Populate new SOGI fields
        _preferredNameController.text = data['preferredName'] as String? ?? '';
        _sexualOrientationController.text = data['sexualOrientation'] as String? ?? '';
        _genderIdentityController.text = data['genderIdentity'] as String? ?? '';
        _preferredPronounsController.text = data['preferredPronouns'] as String? ?? '';
        // NEW: Populate emergency contact fields
        _emergencyContactNameController.text = data['emergencyContactName'] as String? ?? '';
        _emergencyContactPhoneController.text = data['emergencyContactPhone'] as String? ?? '';
        _emergencyContactRelationshipController.text = data['emergencyContactRelationship'] as String? ?? '';        
      } else {
        // create mode → clear everything
        _profileNameController.clear();
        _dateOfBirthController.clear();
        _allergiesController.clear();
        _dietaryRestrictionsController.clear();
        _preferredNameController.clear();
        _sexualOrientationController.clear();
        _genderIdentityController.clear();
        _preferredPronounsController.clear();
          // NEW: Clear emergency contact controllers
        _emergencyContactNameController.clear();
        _emergencyContactPhoneController.clear();
        _emergencyContactRelationshipController.clear();      
      }
    }
  }

  @override
  void dispose() {
    _profileNameController.dispose();
    _dateOfBirthController.dispose();
    _allergiesController.dispose();
    _dietaryRestrictionsController.dispose();
    // Dispose new SOGI controllers
    _preferredNameController.dispose();
    _sexualOrientationController.dispose();
    _genderIdentityController.dispose();
    _preferredPronounsController.dispose();
    // NEW: Dispose emergency contact controllers
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _emergencyContactRelationshipController.dispose();    
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final profileName = _profileNameController.text.trim();
    final dob = _dateOfBirthController.text.trim();
    final allergiesRaw = _allergiesController.text;
    final dietary = _dietaryRestrictionsController.text.trim();
    // Get values from new SOGI controllers
    final preferredName = _preferredNameController.text.trim();
    final sexualOrientation = _sexualOrientationController.text.trim();
    final genderIdentity = _genderIdentityController.text.trim();
    final preferredPronouns = _preferredPronounsController.text.trim();
    // NEW: Get values from emergency contact controllers
    final emergencyContactName = _emergencyContactNameController.text.trim();
    final emergencyContactPhone = _emergencyContactPhoneController.text.trim();
    final emergencyContactRelationship = _emergencyContactRelationshipController.text.trim();    

    if (profileName.isEmpty) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Profile name is required.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }

    // Optional: Validate DOB format if needed
    if (dob.isNotEmpty && !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
      await showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Validation Error'),
          content: const Text('Date of Birth must be in YYYY-MM-DD format.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(c).pop(),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Convert comma-separated string to List<String> for allergies
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
      // Add new SOGI fields to profileData
      // Send null if empty, so Firestore can remove the field if desired
      'preferredName': preferredName.isNotEmpty ? preferredName : null,
      'sexualOrientation': sexualOrientation.isNotEmpty ? sexualOrientation : null,
      'genderIdentity': genderIdentity.isNotEmpty ? genderIdentity : null,
      'preferredPronouns': preferredPronouns.isNotEmpty ? preferredPronouns : null,
      // NEW: Add emergency contact fields to profileData
      'emergencyContactName': emergencyContactName.isNotEmpty ? emergencyContactName : null,
      'emergencyContactPhone': emergencyContactPhone.isNotEmpty ? emergencyContactPhone : null,
      'emergencyContactRelationship': emergencyContactRelationship.isNotEmpty ? emergencyContactRelationship : null,      
      // 'adminUserIds' should be handled by the service layer, typically adding the current user on creation.
    };

    try {
      await widget.onSubmit(profileData);
      // Parent (manage_elder_profiles_screen) is responsible for closing the modal via its own state
      // widget.onClose(); // This can be called by the parent after successful submission
    } catch (e) {
      if (mounted) {
        // Check if the widget is still in the tree
        await showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Submission Error'),
            content: Text('An error occurred: ${e.toString()}'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(c).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleClose() {
    if (_isSubmitting) return; // Don't close if submitting
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        // A semi-transparent barrier:
        Positioned.fill(
          child: GestureDetector(
            onTap: _handleClose, // Close when tapping outside the dialog
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ), // Darker overlay
          ),
        ),

        // Centered dialog
        Center(
          child: SingleChildScrollView(
            // Allows content to scroll if it overflows
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ), // Padding around the dialog
            child: Material(
              // Material widget for elevation and shape
              elevation: 8.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // Softer corners
              ),
              child: Container(
                width:
                    MediaQuery.of(context).size.width * 0.9, // Responsive width
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Fit content
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.mode == 'edit'
                          ? 'Edit Elder Profile'
                          : 'Create New Elder Profile',
                      style: kModalTitleStyle.copyWith(
                        fontSize: 22,
                      ), // Slightly larger title
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24), // More space after title
                    // Profile Name *
                    const Text('Profile Name*', style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _profileNameController,
                      decoration: kInputDecoration.copyWith(
                        hintText: "Elder's Full Name or Nickname",
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Date of Birth (optional)
                    const Text(
                      'Date of Birth (YYYY-MM-DD)',
                      style: kFormLabelStyle,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dateOfBirthController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'YYYY-MM-DD',
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      keyboardType: TextInputType.datetime,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Allergies (optional)
                    const Text(
                      'Allergies (comma-separated)',
                      style: kFormLabelStyle,
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _allergiesController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., Peanuts, Aspirin',
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Dietary Restrictions (optional)
                    const Text('Dietary Restrictions', style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _dietaryRestrictionsController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., Low sodium, no gluten',
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // Preferred Name (optional)
                    const Text('Preferred Name', style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _preferredNameController,
                      decoration: kInputDecoration.copyWith(
                        hintText: "Elder's Preferred Name (Optional)",
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Sexual Orientation (optional)
                    const Text('Sexual Orientation', style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _sexualOrientationController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., Lesbian, Bisexual (Optional)',
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Gender Identity (optional)
                    const Text('Gender Identity', style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _genderIdentityController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., Woman, Non-binary (Optional)',
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Preferred Pronouns (optional)
                    const Text('Preferred Pronouns', style: kFormLabelStyle),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _preferredPronounsController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., she/her, they/them (Optional)',
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // NEW SECTION: Emergency Contact Information
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Emergency Contact Information', // TODO: Localize this title
                      style: kModalTitleStyle.copyWith(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact Name (optional)
                    const Text('Contact Name', style: kFormLabelStyle), // TODO: Localize
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emergencyContactNameController,
                      decoration: kInputDecoration.copyWith(
                        hintText: "Emergency Contact's Full Name (Optional)", // TODO: Localize
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact Phone (optional)
                    const Text('Contact Phone', style: kFormLabelStyle), // TODO: Localize
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emergencyContactPhoneController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., +1 (555) 123-4567 (Optional)', // TODO: Localize
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Emergency Contact Relationship (optional)
                    const Text('Relationship to Care Recipient', style: kFormLabelStyle), // TODO: Localize
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emergencyContactRelationshipController,
                      decoration: kInputDecoration.copyWith(
                        hintText: 'e.g., Son, Daughter, Neighbor (Optional)', // TODO: Localize
                        hintStyle: const TextStyle(color: kTextLight),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24), // Space before buttons                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isSubmitting ? null : _handleClose,
                          style: TextButton.styleFrom(
                            foregroundColor:
                                kPrimaryColor, // Use your theme color
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                kPrimaryColor, // Use your theme color
                            foregroundColor:
                                Colors.white, // Text color for ElevatedButton
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
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
