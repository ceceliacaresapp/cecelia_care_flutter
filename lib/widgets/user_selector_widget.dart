import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart'; // For l10n

enum MessageAudience { all, specific }

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
    // If the initial props change from the parent, re-evaluate.
    // This might happen if the parent resets the form.
    if (widget.initialIsPublic != oldWidget.initialIsPublic ||
        !Set<String>.from(
          widget.initialSelectedUserIds,
        ).containsAll(_selectedUserIds) ||
        !_selectedUserIds.containsAll(
          Set<String>.from(widget.initialSelectedUserIds),
        )) {
      setState(() {
        _selectedUserIds = Set<String>.from(widget.initialSelectedUserIds);
        _audience = widget.initialIsPublic
            ? MessageAudience.all
            : MessageAudience.specific;
      });
    }
  }

  void _handleAudienceChange(MessageAudience? newAudience) {
    if (newAudience != null) {
      setState(() {
        _audience = newAudience;
        if (_audience == MessageAudience.all) {
          _selectedUserIds
              .clear(); // Clear specific selections if "All" is chosen
        }
        widget.onSelectionChanged(
          _selectedUserIds.toList(),
          _audience == MessageAudience.all,
        );
      });
    }
  }

  void _handleUserSelection(UserProfile user, bool? isSelected) {
    if (isSelected == null) return;
    setState(() {
      if (isSelected) {
        _selectedUserIds.add(user.uid);
      } else {
        _selectedUserIds.remove(user.uid);
      }
      // Ensure audience is specific if individual users are selected
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.userSelectorSendToLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        SegmentedButton<MessageAudience>(
          segments: <ButtonSegment<MessageAudience>>[
            ButtonSegment<MessageAudience>(
              value: MessageAudience.all,
              label: Text(l10n.userSelectorAudienceAll),
              icon: const Icon(Icons.people_alt_outlined),
            ),
            ButtonSegment<MessageAudience>(
              value: MessageAudience.specific,
              label: Text(l10n.userSelectorAudienceSpecific),
              icon: const Icon(Icons.person_outline),
            ),
          ],
          selected: <MessageAudience>{_audience},
          onSelectionChanged: (Set<MessageAudience> newSelection) {
            _handleAudienceChange(newSelection.first);
          },
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(
            // side: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        if (_audience == MessageAudience.specific) ...[
          const SizedBox(height: 12),
          if (widget.isLoadingUsers)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (widget.allUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                l10n.userSelectorNoUsersAvailable,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 150), // Limit height
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.allUsers.length,
                itemBuilder: (context, index) {
                  final user = widget.allUsers[index];
                  return CheckboxListTile(
                    title: Text(user.displayName),
                    value: _selectedUserIds.contains(user.uid),
                    onChanged: (bool? selected) =>
                        _handleUserSelection(user, selected),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
        ],
      ],
    );
  }
}
