import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/widgets/elder_profile_form_modal.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart'
    as UserModel;

class ManageCareRecipientProfilesScreen extends StatefulWidget {
  const ManageCareRecipientProfilesScreen({super.key});

  @override
  State<ManageCareRecipientProfilesScreen> createState() =>
      _ManageCareRecipientProfilesScreenState();
}

class _ManageCareRecipientProfilesScreenState
    extends State<ManageCareRecipientProfilesScreen> {
  // --- PERFORMANCE FIX: Step 1 ---
  late AppLocalizations _l10n;
  late ThemeData _theme;

  final _inviteEmailController = TextEditingController();
  String? _selectedElderIdForInvite;

  bool _isCreatingNewProfile = false;
  bool _isInviting = false;
  ElderProfile? _editingProfile;

  List<ElderProfile> _displayedProfiles = [];

  // --- PERFORMANCE FIX: Step 2 ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
  }

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  void _startCreateNewProfile() {
    setState(() {
      _isCreatingNewProfile = true;
      _editingProfile = null;
    });
  }

  void _startEditProfile(ElderProfile profile) {
    setState(() {
      _isCreatingNewProfile = true;
      _editingProfile = profile;
    });
  }

  void _cancelCreateOrEdit() {
    setState(() {
      _isCreatingNewProfile = false;
      _editingProfile = null;
    });
  }

  Future<void> _handleModalSubmit(Map<String, dynamic> dataFromModal) async {
    final firestoreService = context.read<FirestoreService>();

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_l10n.errorNotLoggedIn)));
      }
      return;
    }

    try {
      if (_editingProfile != null) {
        if (_editingProfile!.id.isEmpty) {
          throw Exception('Care Recipient ID is missing, cannot update.');
        }
        await firestoreService.updateElderProfile(
          _editingProfile!.id,
          dataFromModal,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _l10n.profileUpdatedSnackbar(_editingProfile!.profileName),
              ),
            ),
          );
        }
      } else {
        final newElderId = await firestoreService.createElderProfile(
          dataFromModal,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _l10n.profileCreatedSnackbar(
                  dataFromModal['profileName'] as String,
                ),
              ),
            ),
          );
          final newProfile = await firestoreService.getElderProfile(newElderId);
          if (newProfile != null && mounted) {
            Provider.of<ActiveElderProvider>(
              context,
              listen: false,
            ).setActive(newProfile);
          }
        }
      }
      _cancelCreateOrEdit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.errorSavingProfile(e.toString()))),
        );
      }
    }
  }

  Future<void> _handleInviteCaregiver() async {
    final firestoreService = context.read<FirestoreService>();
    if (_selectedElderIdForInvite == null ||
        _inviteEmailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a care recipient and enter an email.')));
      return;
    }

    setState(() => _isInviting = true);
    try {
      await firestoreService.inviteCaregiverToElderProfile(
        _selectedElderIdForInvite!,
        _inviteEmailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _l10n.invitationSentSnackbar(_inviteEmailController.text.trim()),
            ),
          ),
        );
      }
      _inviteEmailController.clear();
      _selectedElderIdForInvite = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.errorSendingInvitation(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInviting = false);
      }
    }
  }

  Future<void> _handleRemoveCaregiver(
    String elderId,
    String caregiverIdToRemove,
    String caregiverIdentifier,
  ) async {
    final firestoreService = context.read<FirestoreService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.removeCaregiverDialogTitle),
        content: Text(_l10n.removeCaregiverDialogContent(caregiverIdentifier)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.removeButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await firestoreService.removeCaregiverFromElderProfile(
          elderId,
          caregiverIdToRemove,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_l10n.caregiverRemovedSnackbar(caregiverIdentifier)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.errorRemovingCaregiver(e.toString()))),
          );
        }
      }
    }
  }

  Future<Map<String, String>> _fetchCaregiverIdentifiers(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};
    Map<String, String> identifiers = {};
    try {
      if (userIds.length > 10) {
        debugPrint(
          'Warning: Fetching more than 10 caregiver identifiers at once. Consider batching.',
        );
      }
      QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('users')
          .where(
            FieldPath.documentId,
            whereIn: userIds.isNotEmpty ? userIds : [' '],
          )
          .get();
      for (var doc in userDocs.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        identifiers[doc.id] =
            data?['displayName'] as String? ??
            data?['email'] as String? ??
            doc.id;
      }
    } catch (e) {
      debugPrint('Error fetching caregiver identifiers: $e');
      for (var id in userIds) {
        if (!identifiers.containsKey(id)) {
          identifiers[id] = id;
        }
      }
    }
    return identifiers;
  }

  Widget _buildCareRecipientProfileCard(
    ElderProfile profile,
    ElderProfile? activeElder,
    UserModel.UserProfile? currentUserProfile,
  ) {
    final bool isActive = activeElder?.id == profile.id;
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isPrimaryAdmin =
        profile.id.isNotEmpty &&
        currentUserId != null && profile.primaryAdminUserId == currentUserId;

    return Card(
      key: ValueKey(profile.id),
      elevation: isActive ? 4 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isActive ? AppTheme.accentColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    profile.profileName,
                    style: AppStyles.sectionTitle.copyWith(
                      color: isActive
                          ? AppTheme.accentColor
                          : AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      if (isPrimaryAdmin)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppTheme.accentColor,
                        ),
                        tooltip: _l10n.tooltipEditProfile,
                        onPressed: () => _startEditProfile(profile),
                      ),
                    if (isPrimaryAdmin)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                          label: Text(_l10n.inviteButton),
                          onPressed: () => _showInviteDialog(profile),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentColor.withOpacity(0.8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            textStyle: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () {
                        Provider.of<ActiveElderProvider>(context, listen: false).setActive(profile);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_l10n.profileSetActiveSnackbar(profile.profileName)),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? AppTheme.accentColor : AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                      ),
                      child: Text(isActive ? _l10n.activeButton : _l10n.setActiveButton),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (profile.dateOfBirth.isNotEmpty)
              Text(
                '${_l10n.dobLabelPrefix} ${profile.dateOfBirth}',
                style: _theme.textTheme.bodyLarge,
              ),
            if (profile.allergies.isNotEmpty)
              Text(
                '${_l10n.allergiesLabelPrefix} ${profile.allergies.join(", ")}',
                style: _theme.textTheme.bodyLarge,
              ),
            if (profile.dietaryRestrictions.isNotEmpty)
              Text(
                '${_l10n.dietLabelPrefix} ${profile.dietaryRestrictions}',
                style: _theme.textTheme.bodyLarge,
              ),
            if ((profile.emergencyContactName?.isNotEmpty ?? false) ||
                (profile.emergencyContactPhone?.isNotEmpty ?? false) ||
                (profile.emergencyContactRelationship?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _l10n.emergencyContactSectionTitle,
                      style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (profile.emergencyContactName?.isNotEmpty ?? false)
                      Text('${_l10n.emergencyContactNameLabel}: ${profile.emergencyContactName}', style: _theme.textTheme.bodyLarge),
                    if (profile.emergencyContactPhone?.isNotEmpty ?? false)
                      Text('${_l10n.emergencyContactPhoneLabel}: ${profile.emergencyContactPhone}', style: _theme.textTheme.bodyLarge),
                    if (profile.emergencyContactRelationship?.isNotEmpty ?? false)
                      Text('${_l10n.emergencyContactRelationshipLabel}: ${profile.emergencyContactRelationship}', style: _theme.textTheme.bodyLarge),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            Text(
              _l10n.primaryAdminLabel,
              style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            FutureBuilder<DocumentSnapshot>(
              future: profile.primaryAdminUserId.isNotEmpty
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(profile.primaryAdminUserId)
                      .get()
                  : Future.value(null),
              builder: (context, snapshot) {
                if (profile.primaryAdminUserId.isEmpty) {
                  return Text(
                    _l10n.adminNotAssigned,
                    style: _theme.textTheme.bodyLarge,
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    _l10n.loadingAdminInfo,
                    style: _theme.textTheme.bodyLarge,
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    (snapshot.data != null && !snapshot.data!.exists)) {
                  return Text(
                    profile.primaryAdminUserId,
                    style: _theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  );
                }
                final adminData =
                    snapshot.data!.data() as Map<String, dynamic>?;
                final adminName =
                    adminData?['displayName'] as String? ??
                    adminData?['email'] as String? ??
                    profile.primaryAdminUserId;
                return Text(adminName ?? 'N/A', style: _theme.textTheme.bodyLarge);
              },
            ),
            const SizedBox(height: 12),

            Text(
              _l10n.caregiversLabel(profile.caregiverUserIds.length),
              style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (profile.caregiverUserIds.isEmpty)
              Text(_l10n.noCaregiversYet, style: _theme.textTheme.bodyLarge)
            else
              FutureBuilder<Map<String, String>>(
                future: _fetchCaregiverIdentifiers(profile.caregiverUserIds),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(
                      _l10n.errorLoadingCaregiverNames,
                      style: const TextStyle(color: AppTheme.dangerColor),
                    );
                  }
                  final caregiverIdentifiers = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: profile.caregiverUserIds.map((uid) {
                      final String identifier =
                          caregiverIdentifiers[uid] ?? uid;
                      final bool isThisCaregiverThePrimaryAdmin =
                          uid == profile.primaryAdminUserId;
                      return Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• $identifier ${isThisCaregiverThePrimaryAdmin ? _l10n.caregiverAdminSuffix : ""}',
                                style: _theme.textTheme.bodyLarge,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPrimaryAdmin &&
                                !isThisCaregiverThePrimaryAdmin)
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AppTheme.dangerColor,
                                  size: 20,
                                ),
                                tooltip: _l10n.tooltipRemoveCaregiver(
                                  identifier,
                                ),
                                onPressed: () => _handleRemoveCaregiver(
                                  profile.id,
                                  uid,
                                  identifier,
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(ElderProfile profile) {
    _selectedElderIdForInvite = profile.id;
    _inviteEmailController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_l10n.inviteDialogTitle(profile.profileName)),
          content: TextField(
            controller: _inviteEmailController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: _l10n.caregiversEmailLabel,
              hintText: _l10n.enterEmailHint,
              icon: const Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(_l10n.cancelButton),
              onPressed: () {
                Navigator.of(context).pop();
                _selectedElderIdForInvite = null;
              },
            ),
            ElevatedButton(
              onPressed: _isInviting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      _handleInviteCaregiver();
                    },
              child: _isInviting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textOnPrimary,
                      ),
                    )
                  : Text(_l10n.sendInviteButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- PERFORMANCE FIX: Step 3 ---
    // The build method now uses the stored _l10n and _theme variables.
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final activeElder = Provider.of<ActiveElderProvider>(context).activeElder;
    final currentUserProfile = Provider.of<UserProfileProvider>(
      context,
    ).userProfile;

    if (_isCreatingNewProfile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _editingProfile == null
                ? 'Create Care Recipient Profile'
                : _l10n.editProfileTitle(
                    (_editingProfile?.profileName ?? 'Profile'),
                  ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelCreateOrEdit,
          ),
        ),
        body: ElderProfileFormModal(
          visible: true,
          onClose: _cancelCreateOrEdit,
          onSubmit: _handleModalSubmit,
          initialData: _editingProfile != null
              ? {
                  'profileName': _editingProfile!.profileName,
                  'dateOfBirth': _editingProfile!.dateOfBirth,
                  'allergies': _editingProfile!.allergies,
                  'dietaryRestrictions': _editingProfile!.dietaryRestrictions,
                  'preferredName': _editingProfile!.preferredName,
                  'sexualOrientation': _editingProfile!.sexualOrientation,
                  'genderIdentity': _editingProfile!.genderIdentity,
                  'preferredPronouns': _editingProfile!.preferredPronouns,
                  'emergencyContactName': _editingProfile!.emergencyContactName,
                  'emergencyContactPhone': _editingProfile!.emergencyContactPhone,
                  'emergencyContactRelationship': _editingProfile!.emergencyContactRelationship,                                
                }
              : null,
          mode: _editingProfile != null ? 'edit' : 'create',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Care Recipient Profiles'),
      ),
      body: StreamBuilder<List<ElderProfile>>(
        stream: context.read<FirestoreService>().getMyEldersStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${_l10n.errorPrefix}${snapshot.error}',
                style: const TextStyle(color: AppTheme.dangerColor),
              ),
            );
          }
          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty && currentUserId != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.group_add_outlined,
                      size: 60,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No care recipient profiles found.',
                      style: AppStyles.emptyStateText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _l10n.createNewProfileOrWait,
                      style: _theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(_l10n.createNewProfileButton),
                      onPressed: _startCreateNewProfile,
                    ),
                  ],
                ),
              ),
            );
          }
          if (currentUserId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.no_accounts_outlined,
                      size: 60,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _l10n.pleaseLogInToManageProfiles,
                      style: AppStyles.emptyStateText,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          profiles.sort((a, b) => (a.priorityIndex ?? 9999).compareTo(b.priorityIndex ?? 9999));
          _displayedProfiles = List.from(profiles);

          return ReorderableListView.builder(
            key: UniqueKey(),
            padding: AppStyles.screenPadding,
            itemCount: _displayedProfiles.length,
            itemBuilder: (context, index) {
              final profile = _displayedProfiles[index];
              return _buildCareRecipientProfileCard(
                profile,
                activeElder,
                currentUserProfile,
              );
            },
            onReorder: (oldIndex, newIndex) async {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final ElderProfile item = _displayedProfiles.removeAt(oldIndex);
                _displayedProfiles.insert(newIndex, item);
              });

              final firestoreService = context.read<FirestoreService>();
              List<Future<void>> updateFutures = [];
              for (var i = 0; i < _displayedProfiles.length; i++) {
                if (_displayedProfiles[i].priorityIndex != i) {
                  _displayedProfiles[i].priorityIndex = i;
                  updateFutures.add(
                    firestoreService.updateElderPriority(
                      elderId: _displayedProfiles[i].id,
                      priorityIndex: i,
                    ),
                  );
                }
              }
              await Future.wait(updateFutures);

              if (_displayedProfiles.isNotEmpty) {
                Provider.of<ActiveElderProvider>(context, listen: false)
                    .setActive(_displayedProfiles.first);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_l10n.profileSetActiveSnackbar(_displayedProfiles.first.profileName)),
                ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startCreateNewProfile,
        label: Text(_l10n.fabNewProfile),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: AppTheme.textOnPrimary,
      ),
    );
  }
}