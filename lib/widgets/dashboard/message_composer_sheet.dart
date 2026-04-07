// lib/widgets/dashboard/message_composer_sheet.dart
//
// Bottom-sheet form for posting a quick message to the active elder's
// timeline. Used by the dashboard's "New message" quick action.
//
// Extracted from dashboard_screen.dart so the screen file shrinks and
// future screens (e.g. timeline) can reuse the same composer.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/user_selector_widget.dart';

class MessageComposerSheet extends StatefulWidget {
  const MessageComposerSheet({
    super.key,
    required this.activeElder,
    required this.firestoreService,
  });

  final ElderProfile activeElder;
  final FirestoreService firestoreService;

  @override
  State<MessageComposerSheet> createState() => _MessageComposerSheetState();
}

class _MessageComposerSheetState extends State<MessageComposerSheet> {
  static const _kColor = AppTheme.tileBlueGrey;

  final TextEditingController _ctrl = TextEditingController();
  bool _isPublic = true;
  List<String> _selectedUserIds = [];
  List<UserProfile> _associatedUsers = [];
  bool _isLoadingUsers = false;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _fetchAssociatedUsers();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAssociatedUsers() async {
    if (widget.activeElder.id.isEmpty) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await widget.firestoreService
          .getAssociatedUsersForElder(widget.activeElder.id);
      if (mounted) setState(() => _associatedUsers = users);
    } catch (e) {
      debugPrint('MessageComposerSheet: error fetching users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _post() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isPosting = true);
    try {
      List<String> visibleToUserIds = [];
      if (_isPublic) {
        visibleToUserIds.add('all');
      } else {
        visibleToUserIds.addAll(_selectedUserIds);
        if (!visibleToUserIds.contains(user.uid)) {
          visibleToUserIds.add(user.uid);
        }
      }

      await widget.firestoreService.addJournalEntry(
        elderId: widget.activeElder.id,
        type: EntryType.message,
        creatorId: user.uid,
        text: text,
        visibleToUserIds: visibleToUserIds,
        isPublic: _isPublic,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message posted to timeline.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('MessageComposerSheet._post error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not post message: ${e.toString()}'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elderName = (widget.activeElder.preferredName?.isNotEmpty == true)
        ? widget.activeElder.preferredName!
        : widget.activeElder.profileName;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline,
                    color: _kColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'New message for $elderName\'s timeline',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Audience selector
          UserSelectorWidget(
            allUsers: _associatedUsers,
            isLoadingUsers: _isLoadingUsers,
            initialSelectedUserIds: _selectedUserIds,
            initialIsPublic: _isPublic,
            onSelectionChanged: (ids, isPublic) {
              setState(() {
                _selectedUserIds = ids;
                _isPublic = isPublic;
              });
            },
          ),

          const SizedBox(height: 12),

          // Audience hint
          Text(
            _isPublic
                ? 'Posting to all caregivers'
                : 'Private — visible only to selected people',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: _isPublic ? AppTheme.textSecondary : _kColor,
            ),
          ),

          const SizedBox(height: 12),

          // Text field
          TextField(
            controller: _ctrl,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Write a message for $elderName\'s timeline...',
              filled: true,
              fillColor: _kColor.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: _kColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: _kColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kColor),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed:
                    _isPosting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isPosting ? null : _post,
                icon: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_outlined, size: 16),
                label: const Text('Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
