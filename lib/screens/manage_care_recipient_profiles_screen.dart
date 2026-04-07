import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
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
  late AppLocalizations _l10n;
  late ThemeData _theme;

  final _inviteEmailController = TextEditingController();
  String? _selectedElderIdForInvite;

  bool _isCreatingNewProfile = false;
  bool _isInviting = false;
  ElderProfile? _editingProfile;

  List<ElderProfile> _displayedProfiles = [];

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

  void _startCreateNewProfile() => setState(() {
        _isCreatingNewProfile = true;
        _editingProfile = null;
      });

  void _startEditProfile(ElderProfile profile) => setState(() {
        _isCreatingNewProfile = true;
        _editingProfile = profile;
      });

  void _cancelCreateOrEdit() => setState(() {
        _isCreatingNewProfile = false;
        _editingProfile = null;
      });

  Future<void> _handleModalSubmit(Map<String, dynamic> data) async {
    final firestoreService = context.read<FirestoreService>();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.errorNotLoggedIn)));
      return;
    }
    try {
      if (_editingProfile != null) {
        if (_editingProfile!.id.isEmpty) {
          throw Exception('Care Recipient ID is missing, cannot update.');
        }
        await firestoreService.updateElderProfile(_editingProfile!.id, data);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                _l10n.profileUpdatedSnackbar(_editingProfile!.profileName))));
      } else {
        final newElderId =
            await firestoreService.createElderProfile(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_l10n
                  .profileCreatedSnackbar(data['profileName'] as String))));
          final newProfile =
              await firestoreService.getElderProfile(newElderId);
          if (newProfile != null && mounted) {
            Provider.of<ActiveElderProvider>(context, listen: false)
                .setActive(newProfile);
          }
        }
      }
      _cancelCreateOrEdit();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.errorSavingProfile(e.toString()))));
    }
  }

  // ---------------------------------------------------------------------------
  // Invite caregiver — writes both caregiverUserIds AND caregiverRoles
  // ---------------------------------------------------------------------------

  Future<void> _handleInviteCaregiver(
    String elderId,
    String email,
    CaregiverRole role,
  ) async {
    final firestoreService = context.read<FirestoreService>();
    setState(() => _isInviting = true);
    try {
      // Invite via FirestoreService (adds to caregiverUserIds)
      await firestoreService.inviteCaregiverToElderProfile(elderId, email);

      // Look up the invited user's UID so we can set their role
      final QuerySnapshot userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .limit(1)
          .get();

      if (userSnap.docs.isNotEmpty) {
        final invitedUid = userSnap.docs.first.id;
        // Write the role to caregiverRoles map
        await FirebaseFirestore.instance
            .collection('elderProfiles')
            .doc(elderId)
            .update({
          'caregiverRoles.$invitedUid': role.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_l10n.invitationSentSnackbar(email))));
        _inviteEmailController.clear();
        _selectedElderIdForInvite = null;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_l10n.errorSendingInvitation(e.toString()))));
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Change role of an existing caregiver
  // ---------------------------------------------------------------------------

  Future<void> _handleChangeRole(
    String elderId,
    String uid,
    String displayName,
    CaregiverRole currentRole,
  ) async {
    CaregiverRole newRole = currentRole == CaregiverRole.caregiver
        ? CaregiverRole.viewer
        : CaregiverRole.caregiver;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change role'),
        content: Text(
          'Change $displayName from ${currentRole.label} to ${newRole.label}?\n\n'
          '${newRole.description}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_l10n.cancelButton)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Change role'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('elderProfiles')
          .doc(elderId)
          .update({
        'caregiverRoles.$uid': newRole.firestoreValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '$displayName is now a ${newRole.label.toLowerCase()}'),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not change role: $e'),
          backgroundColor: AppTheme.dangerColor));
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
        content:
            Text(_l10n.removeCaregiverDialogContent(caregiverIdentifier)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(_l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.removeButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await firestoreService.removeCaregiverFromElderProfile(
            elderId, caregiverIdToRemove);
        // Also remove the role entry
        await FirebaseFirestore.instance
            .collection('elderProfiles')
            .doc(elderId)
            .update({
          'caregiverRoles.$caregiverIdToRemove': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(_l10n.caregiverRemovedSnackbar(caregiverIdentifier))));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_l10n.errorRemovingCaregiver(e.toString()))));
      }
    }
  }

  Future<Map<String, ({String name, Timestamp? lastActiveAt})>>
      _fetchCaregiverIdentifiers(List<String> userIds) async {
    if (userIds.isEmpty) return {};
    Map<String, ({String name, Timestamp? lastActiveAt})> identifiers = {};
    try {
      QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();
      for (var doc in userDocs.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        identifiers[doc.id] = (
          name: data?['displayName'] as String? ??
              data?['email'] as String? ??
              doc.id,
          lastActiveAt: data?['lastActiveAt'] as Timestamp?,
        );
      }
    } catch (e) {
      debugPrint('Error fetching caregiver identifiers: $e');
      for (var id in userIds) {
        if (!identifiers.containsKey(id)) {
          identifiers[id] = (name: id, lastActiveAt: null);
        }
      }
    }
    return identifiers;
  }

  String _formatLastActive(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final active = ts.toDate();
    final diff = now.difference(active);
    if (diff.inMinutes < 1) return 'Active now';
    if (diff.inMinutes < 60) return 'Active ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Active ${diff.inHours}h ago';
    if (diff.inDays < 7) return 'Active ${diff.inDays}d ago';
    return 'Active ${active.month}/${active.day}';
  }

  bool _isRecentlyActive(Timestamp? ts) {
    if (ts == null) return false;
    return DateTime.now().difference(ts.toDate()).inHours < 1;
  }

  // ---------------------------------------------------------------------------
  // Profile card
  // ---------------------------------------------------------------------------

  Widget _buildCareRecipientProfileCard(
    ElderProfile profile,
    ElderProfile? activeElder,
    UserModel.UserProfile? currentUserProfile,
  ) {
    final bool isActive = activeElder?.id == profile.id;
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final bool isPrimaryAdmin = profile.id.isNotEmpty &&
        currentUserId != null &&
        profile.primaryAdminUserId == currentUserId;

    return Card(
      key: ValueKey(profile.id),
      elevation: isActive ? 4 : 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
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
            // Header: avatar + name
            Row(
              children: [
                _ElderAvatar(
                    profileName: profile.profileName,
                    photoUrl: profile.photoUrl,
                    radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.profileName,
                        style: AppStyles.sectionTitle.copyWith(
                          color: isActive
                              ? AppTheme.accentColor
                              : AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (profile.dateOfBirth.isNotEmpty)
                        Text('Born: ${profile.dateOfBirth}',
                            style: _theme.textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Action buttons row — stacked below the name so they don't overflow
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Set active / Active badge
                _ActionChip(
                  icon: isActive ? Icons.check_circle : Icons.radio_button_unchecked,
                  label: isActive ? 'Active' : 'Set active',
                  color: isActive ? AppTheme.accentColor : AppTheme.primaryColor,
                  filled: isActive,
                  onTap: () {
                    Provider.of<ActiveElderProvider>(context, listen: false)
                        .setActive(profile);
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(_l10n.profileSetActiveSnackbar(
                              profile.profileName))));
                  },
                ),
                if (isPrimaryAdmin)
                  _ActionChip(
                    icon: Icons.edit_outlined,
                    label: 'Edit profile',
                    color: AppTheme.accentColor,
                    onTap: () => _startEditProfile(profile),
                  ),
                if (isPrimaryAdmin)
                  _ActionChip(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Invite',
                    color: const Color(0xFF00897B),
                    onTap: () => _showInviteDialog(profile),
                  ),
              ],
            ),

            const SizedBox(height: 8),
            if (profile.dateOfBirth.isNotEmpty)
              Text('${_l10n.dobLabelPrefix} ${profile.dateOfBirth}',
                  style: _theme.textTheme.bodyLarge),
            if (profile.allergies.isNotEmpty)
              Text(
                  '${_l10n.allergiesLabelPrefix} ${profile.allergies.join(", ")}',
                  style: _theme.textTheme.bodyLarge),
            if (profile.dietaryRestrictions.isNotEmpty)
              Text(
                  '${_l10n.dietLabelPrefix} ${profile.dietaryRestrictions}',
                  style: _theme.textTheme.bodyLarge),
            if ((profile.emergencyContactName?.isNotEmpty ?? false) ||
                (profile.emergencyContactPhone?.isNotEmpty ?? false) ||
                (profile.emergencyContactRelationship?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_l10n.emergencyContactSectionTitle,
                        style: _theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (profile.emergencyContactName?.isNotEmpty ?? false)
                      Text(
                          '${_l10n.emergencyContactNameLabel}: ${profile.emergencyContactName}',
                          style: _theme.textTheme.bodyLarge),
                    if (profile.emergencyContactPhone?.isNotEmpty ?? false)
                      Text(
                          '${_l10n.emergencyContactPhoneLabel}: ${profile.emergencyContactPhone}',
                          style: _theme.textTheme.bodyLarge),
                    if (profile.emergencyContactRelationship?.isNotEmpty ??
                        false)
                      Text(
                          '${_l10n.emergencyContactRelationshipLabel}: ${profile.emergencyContactRelationship}',
                          style: _theme.textTheme.bodyLarge),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Primary admin
            Text(_l10n.primaryAdminLabel,
                style: _theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            FutureBuilder<DocumentSnapshot>(
              future: profile.primaryAdminUserId.isNotEmpty
                  ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(profile.primaryAdminUserId)
                      .get()
                  : Future.value(null),
              builder: (context, snapshot) {
                if (profile.primaryAdminUserId.isEmpty)
                  return Text(_l10n.adminNotAssigned,
                      style: _theme.textTheme.bodyLarge);
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Text(_l10n.loadingAdminInfo,
                      style: _theme.textTheme.bodyLarge);
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    (snapshot.data != null && !snapshot.data!.exists))
                  return Text(profile.primaryAdminUserId,
                      style: _theme.textTheme.bodyLarge
                          ?.copyWith(fontStyle: FontStyle.italic));
                final adminData =
                    snapshot.data!.data() as Map<String, dynamic>?;
                final adminName = adminData?['displayName'] as String? ??
                    adminData?['email'] as String? ??
                    profile.primaryAdminUserId;
                return Row(
                  children: [
                    Text(adminName, style: _theme.textTheme.bodyLarge),
                    const SizedBox(width: 6),
                    _RoleBadge(role: CaregiverRole.admin),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // Caregivers list with role management
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.group_outlined, size: 16,
                    color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'CARE TEAM (${profile.caregiverUserIds.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (profile.caregiverUserIds.isEmpty)
              Text(_l10n.noCaregiversYet, style: _theme.textTheme.bodyMedium)
            else
              FutureBuilder<Map<String, ({String name, Timestamp? lastActiveAt})>>(
                future: _fetchCaregiverIdentifiers(profile.caregiverUserIds),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Text(_l10n.errorLoadingCaregiverNames,
                        style:
                            const TextStyle(color: AppTheme.dangerColor));
                  }

                  final identifiers = snapshot.data!;
                  return Column(
                    children: profile.caregiverUserIds.map((uid) {
                      final record = identifiers[uid];
                      final identifier = record?.name ?? uid;
                      final activeLabel = _formatLastActive(record?.lastActiveAt);
                      final recentlyActive = _isRecentlyActive(record?.lastActiveAt);
                      final isAdmin = uid == profile.primaryAdminUserId;
                      final role = profile.roleForUser(uid);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? const Color(0xFF1E88E5).withValues(alpha: 0.04)
                              : AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAdmin
                                ? const Color(0xFF1E88E5).withValues(alpha: 0.2)
                                : AppTheme.textLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Name + role + activity
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    identifier,
                                    style: _theme.textTheme.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      _RoleBadge(role: role),
                                      if (activeLabel.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          activeLabel,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: recentlyActive
                                                ? const Color(0xFF43A047)
                                                : AppTheme.textLight,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Admin controls: change role + remove
                            if (isPrimaryAdmin && !isAdmin) ...[
                              IconButton(
                                icon: const Icon(Icons.swap_horiz_outlined,
                                    size: 20),
                                tooltip: 'Change role',
                                color: AppTheme.primaryColor,
                                onPressed: () => _handleChangeRole(
                                    profile.id, uid, identifier, role),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20),
                                tooltip:
                                    _l10n.tooltipRemoveCaregiver(identifier),
                                color: AppTheme.dangerColor,
                                onPressed: () => _handleRemoveCaregiver(
                                    profile.id, uid, identifier),
                              ),
                            ],
                            if (isAdmin)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.shield_outlined,
                                    size: 18, color: Color(0xFF1E88E5)),
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

  // ---------------------------------------------------------------------------
  // Invite dialog — now includes a role picker
  // ---------------------------------------------------------------------------

  void _showInviteDialog(ElderProfile profile) {
    _selectedElderIdForInvite = profile.id;
    _inviteEmailController.clear();
    CaregiverRole selectedRole = CaregiverRole.caregiver;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(_l10n.inviteDialogTitle(profile.profileName)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _inviteEmailController,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: _l10n.caregiversEmailLabel,
                      hintText: _l10n.enterEmailHint,
                      icon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  // Role picker
                  const Text(
                    'ROLE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...[CaregiverRole.caregiver, CaregiverRole.viewer]
                      .map((role) {
                    final isSelected = selectedRole == role;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedRole = role),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.06)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textLight.withValues(alpha: 0.5),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            _RoleBadge(role: role),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(role.label,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimary,
                                      )),
                                  Text(role.description,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  size: 18,
                                  color: AppTheme.primaryColor),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(_l10n.cancelButton),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _selectedElderIdForInvite = null;
                },
              ),
              ElevatedButton(
                onPressed: _isInviting
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        _handleInviteCaregiver(
                          profile.id,
                          _inviteEmailController.text.trim(),
                          selectedRole,
                        );
                      },
                child: _isInviting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textOnPrimary))
                    : Text(_l10n.sendInviteButton),
              ),
            ],
          );
        });
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final activeElder =
        Provider.of<ActiveElderProvider>(context).activeElder;
    final currentUserProfile =
        Provider.of<UserProfileProvider>(context).userProfile;

    if (_isCreatingNewProfile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_editingProfile == null
              ? 'Create Care Recipient Profile'
              : _l10n.editProfileTitle(
                  _editingProfile?.profileName ?? 'Profile')),
          leading: IconButton(
              icon: const Icon(Icons.close), onPressed: _cancelCreateOrEdit),
        ),
        body: ElderProfileFormModal(
          visible: true,
          onClose: _cancelCreateOrEdit,
          onSubmit: _handleModalSubmit,
          elderId: _editingProfile?.id,
          initialData: _editingProfile != null
              ? {
                  'profileName': _editingProfile!.profileName,
                  'dateOfBirth': _editingProfile!.dateOfBirth,
                  'allergies': _editingProfile!.allergies,
                  'dietaryRestrictions':
                      _editingProfile!.dietaryRestrictions,
                  'preferredName': _editingProfile!.preferredName,
                  'sexualOrientation':
                      _editingProfile!.sexualOrientation,
                  'genderIdentity': _editingProfile!.genderIdentity,
                  'preferredPronouns': _editingProfile!.preferredPronouns,
                  'emergencyContactName':
                      _editingProfile!.emergencyContactName,
                  'emergencyContactPhone':
                      _editingProfile!.emergencyContactPhone,
                  'emergencyContactRelationship':
                      _editingProfile!.emergencyContactRelationship,
                  'photoUrl': _editingProfile!.photoUrl,
                }
              : null,
          mode: _editingProfile != null ? 'edit' : 'create',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Care Recipient Profiles')),
      body: StreamBuilder<List<ElderProfile>>(
        stream: context
            .read<FirestoreService>()
            .getMyEldersStream(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: Text('${_l10n.errorPrefix}${snapshot.error}',
                    style:
                        const TextStyle(color: AppTheme.dangerColor)));

          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty && currentUserId != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.group_add_outlined,
                        size: 60, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text('No care recipient profiles found.',
                        style: AppStyles.emptyStateText,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(_l10n.createNewProfileOrWait,
                        style: _theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center),
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
                child: Text(_l10n.pleaseLogInToManageProfiles,
                    style: AppStyles.emptyStateText,
                    textAlign: TextAlign.center),
              ),
            );
          }

          profiles.sort((a, b) =>
              (a.priorityIndex ?? 9999).compareTo(b.priorityIndex ?? 9999));
          _displayedProfiles = List.from(profiles);

          return ListView.builder(
            padding: AppStyles.screenPadding,
            itemCount: _displayedProfiles.length,
            itemBuilder: (context, index) {
              final profile = _displayedProfiles[index];
              return _buildCareRecipientProfileCard(
                  profile, activeElder, currentUserProfile);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'manageCareRecipientFab',
        onPressed: _startCreateNewProfile,
        label: Text(_l10n.fabNewProfile),
        icon: const Icon(Icons.add),
        backgroundColor: AppTheme.accentColor,
        foregroundColor: AppTheme.textOnPrimary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role badge chip
// ---------------------------------------------------------------------------

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final CaregiverRole role;

  @override
  Widget build(BuildContext context) {
    final color = _colorForRole(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForRole(role), size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            role.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForRole(CaregiverRole r) {
    switch (r) {
      case CaregiverRole.admin:
        return const Color(0xFF1E88E5);
      case CaregiverRole.caregiver:
        return const Color(0xFF00897B);
      case CaregiverRole.viewer:
        return const Color(0xFF8E24AA);
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _iconForRole(CaregiverRole r) {
    switch (r) {
      case CaregiverRole.admin:
        return Icons.shield_outlined;
      case CaregiverRole.caregiver:
        return Icons.favorite_border;
      case CaregiverRole.viewer:
        return Icons.visibility_outlined;
      default:
        return Icons.help_outline;
    }
  }
}

// ---------------------------------------------------------------------------
// Elder avatar
// ---------------------------------------------------------------------------

class _ElderAvatar extends StatelessWidget {
  const _ElderAvatar({
    required this.profileName,
    required this.photoUrl,
    this.radius = 24,
  });

  final String profileName;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial =
        profileName.isNotEmpty ? profileName[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              initial,
              style: TextStyle(
                fontSize: radius * 0.75,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Action chip — used for profile card action buttons
// ---------------------------------------------------------------------------

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: filled ? 1.0 : 0.4),
            width: filled ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: filled ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
