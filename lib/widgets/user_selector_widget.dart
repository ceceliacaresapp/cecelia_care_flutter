import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

enum MessageAudience { all, specific }

// Message accent color — blue-grey, matching the message card/tile color.
const _kMsgColor = Color(0xFF546E7A);

class UserSelectorWidget extends StatefulWidget {
  final List<UserProfile> allUsers;
  final bool isLoadingUsers;
  final List<String> initialSelectedUserIds;
  final bool initialIsPublic;
  final Function(List<String> selectedIds, bool isPublic) onSelectionChanged;

  const UserSelectorWidget({
    super.key,
    required this.allUsers,
    required this.isLoadingUsers,
    required this.initialSelectedUserIds,
    required this.initialIsPublic,
    required this.onSelectionChanged,
  });

  @override
  State<UserSelectorWidget> createState() => _UserSelectorWidgetState();
}

class _UserSelectorWidgetState extends State<UserSelectorWidget> {
  late Set<String> _selectedUserIds;
  late MessageAudience _audience;

  @override
  void initState() {
    super.initState();
    _selectedUserIds = Set<String>.from(widget.initialSelectedUserIds);
    _audience = widget.initialIsPublic
        ? MessageAudience.all
        : MessageAudience.specific;
  }

  @override
  void didUpdateWidget(covariant UserSelectorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIsPublic != oldWidget.initialIsPublic ||
        !Set<String>.from(widget.initialSelectedUserIds)
            .containsAll(_selectedUserIds) ||
        !_selectedUserIds
            .containsAll(Set<String>.from(widget.initialSelectedUserIds))) {
      setState(() {
        _selectedUserIds = Set<String>.from(widget.initialSelectedUserIds);
        _audience = widget.initialIsPublic
            ? MessageAudience.all
            : MessageAudience.specific;
      });
    }
  }

  void _handleAudienceChange(MessageAudience? newAudience) {
    if (newAudience == null) return;
    setState(() {
      _audience = newAudience;
      if (_audience == MessageAudience.all) _selectedUserIds.clear();
      widget.onSelectionChanged(
        _selectedUserIds.toList(),
        _audience == MessageAudience.all,
      );
    });
  }

  void _handleUserSelection(UserProfile user, bool? isSelected) {
    if (isSelected == null) return;
    setState(() {
      if (isSelected) {
        _selectedUserIds.add(user.uid);
      } else {
        _selectedUserIds.remove(user.uid);
      }
      if (_selectedUserIds.isNotEmpty && _audience == MessageAudience.all) {
        _audience = MessageAudience.specific;
      }
      widget.onSelectionChanged(
        _selectedUserIds.toList(),
        _audience == MessageAudience.all && _selectedUserIds.isEmpty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isSpecific = _audience == MessageAudience.specific;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Send to label ───────────────────────────────────────
        Text(
          l10n.userSelectorSendToLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        // ── Audience segmented button ───────────────────────────
        SegmentedButton<MessageAudience>(
          segments: [
            ButtonSegment<MessageAudience>(
              value: MessageAudience.all,
              label: Text(l10n.userSelectorAudienceAll),
              icon: const Icon(Icons.people_alt_outlined, size: 16),
            ),
            ButtonSegment<MessageAudience>(
              value: MessageAudience.specific,
              label: Text(l10n.userSelectorAudienceSpecific),
              icon: const Icon(Icons.lock_outline, size: 16),
            ),
          ],
          selected: {_audience},
          onSelectionChanged: (newSelection) =>
              _handleAudienceChange(newSelection.first),
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: _kMsgColor.withOpacity(0.12),
            selectedForegroundColor: _kMsgColor,
            foregroundColor: AppTheme.textSecondary,
            side: BorderSide(color: _kMsgColor.withOpacity(0.3)),
            textStyle: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),

        // ── Specific user list ──────────────────────────────────
        if (isSpecific) ...[
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(maxHeight: 160),
            decoration: BoxDecoration(
              color: _kMsgColor.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kMsgColor.withOpacity(0.2)),
            ),
            child: widget.isLoadingUsers
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : widget.allUsers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          l10n.userSelectorNoUsersAvailable,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.allUsers.length,
                        itemBuilder: (context, index) {
                          final user = widget.allUsers[index];
                          final isChecked =
                              _selectedUserIds.contains(user.uid);
                          return CheckboxListTile(
                            title: Text(
                              user.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: isChecked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isChecked
                                    ? _kMsgColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            value: isChecked,
                            onChanged: (bool? selected) =>
                                _handleUserSelection(user, selected),
                            activeColor: _kMsgColor,
                            checkColor: Colors.white,
                            dense: true,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8),
                          );
                        },
                      ),
          ),
        ],
      ],
    );
  }
}
