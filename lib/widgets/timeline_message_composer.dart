// lib/widgets/timeline_message_composer.dart
//
// Extracted from timeline_screen.dart — the inline message composer with
// public/private mode toggle, user selector, text input, and send handler.

import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/user_selector_widget.dart';

/// Callback signature for the composer's send action.
typedef ComposerSendCallback = Future<void> Function({
  required String text,
  required bool isPublic,
  required List<String> visibleToUserIds,
  String? editingMessageId,
});

class TimelineMessageComposer extends StatefulWidget {
  const TimelineMessageComposer({
    super.key,
    required this.elderName,
    required this.associatedUsers,
    required this.isLoadingUsers,
    required this.onSend,
    required this.onClose,
    this.scrollController,
    this.editingMessageId,
    this.initialText,
    this.initialIsPublic = true,
    this.initialSelectedUserIds = const [],
  });

  final String elderName;
  final List<UserProfile> associatedUsers;
  final bool isLoadingUsers;
  final ComposerSendCallback onSend;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  /// If non-null, the composer is in "edit" mode for an existing message.
  final String? editingMessageId;
  final String? initialText;
  final bool initialIsPublic;
  final List<String> initialSelectedUserIds;

  @override
  State<TimelineMessageComposer> createState() =>
      _TimelineMessageComposerState();
}

class _TimelineMessageComposerState extends State<TimelineMessageComposer> {
  late final TextEditingController _controller;
  late bool _isPublic;
  late List<String> _selectedUserIds;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    _isPublic = widget.initialIsPublic;
    _selectedUserIds = List.from(widget.initialSelectedUserIds);

    // Auto-scroll timeline down so the composer is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sc = widget.scrollController;
      if (sc != null && sc.hasClients) {
        sc.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty && widget.editingMessageId == null) return;

    setState(() => _isPosting = true);
    try {
      await widget.onSend(
        text: text,
        isPublic: _isPublic,
        visibleToUserIds: _selectedUserIds,
        editingMessageId: widget.editingMessageId,
      );
      // Parent handles closing the composer on success.
    } catch (_) {
      // Parent handles error snackbar.
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserSelectorWidget(
              allUsers: widget.associatedUsers,
              isLoadingUsers: widget.isLoadingUsers,
              initialSelectedUserIds: _selectedUserIds,
              initialIsPublic: _isPublic,
              onSelectionChanged: (selectedIds, isPublic) {
                setState(() {
                  _selectedUserIds = selectedIds;
                  _isPublic = isPublic;
                });
              },
            ),
            const SizedBox(height: 10),
            Text(
              _isPublic
                  ? l10n.timelinePostingToAll
                  : l10n.timelinePostingToCount(
                      _selectedUserIds.length.toString()),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.timelineWriteMessageHint(widget.elderName),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isPosting ? null : widget.onClose,
                  child: Text(l10n.timelineCancelButton),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isPosting ? null : _handleSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.textOnPrimary,
                          ),
                        )
                      : Text(
                          widget.editingMessageId != null
                              ? l10n.timelineUpdateButton
                              : l10n.timelinePostButton,
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
