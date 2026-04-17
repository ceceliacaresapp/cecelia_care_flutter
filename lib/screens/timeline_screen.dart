// lib/screens/timeline_screen.dart

import 'package:cecelia_care_flutter/widgets/show_entry_dialog.dart';
import 'package:cecelia_care_flutter/providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/entry_type_helpers.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';
import 'package:cecelia_care_flutter/widgets/staggered_fade_in.dart';
import 'package:cecelia_care_flutter/utils/entry_summary.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/multi_elder_timeline_badge.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/widgets/cached_avatar.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';
import 'package:cecelia_care_flutter/widgets/timeline_message_composer.dart';

// Color tables for entry types live in lib/utils/entry_type_helpers.dart
// (shared with dashboard_screen.dart). Thin alias keeps the existing
// timeline call sites unchanged.
EntryTypeStyle _entryTypeStyle(EntryType type) =>
    entryTypeTimelineStyle(type);

Color _avatarColorForInitial(String initial) {
  const List<Color> palette = [
    AppTheme.primaryColor,
    AppTheme.entryActivityAccent,
    AppTheme.entryMoodAccent,
    AppTheme.tileBlueDark,
    AppTheme.entryMealAccent,
    AppTheme.entryExpenseAccent,
  ];
  if (initial.isEmpty) return AppTheme.backgroundGray;
  return palette[initial.codeUnitAt(0) % palette.length];
}

/// Cosmetic display-name sanitizer.
///
/// Old journal entries may have the raw email stored in loggedByDisplayName.
/// Until backfillDisplayNames() migrates them in Firestore, this strips the
/// domain so the UI shows "jane.doe" instead of "jane.doe@gmail.com".
String _sanitizeDisplayName(String name) {
  if (name.contains('@')) {
    final prefix = name.split('@').first;
    return prefix.isNotEmpty ? prefix : name;
  }
  return name;
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => TimelineScreenState();
}

// FIX 1: Removed `with SingleTickerProviderStateMixin`.
// No TickerProvider (AnimationController, TabController, etc.) is used in
// this class. Keeping it produced a lint warning and wasted resources.
class TimelineScreenState extends State<TimelineScreen> {
  late AppLocalizations _l10n;
  late ThemeData _theme;

  final TextEditingController _messageController = TextEditingController();
  bool _showMessageInput = false;
  List<String> _selectedUserIdsForMessage = [];
  bool _isPublicMessage = true;

  List<UserProfile> _elderAssociatedUsers = [];
  bool _isLoadingUsers = false;

  String? _editingMessageId;

  Set<String> _hiddenMessageIds = {};
  static const String _hiddenMessagesKeyPrefix = 'hiddenMessages_';
  bool _showOnlyHiddenMessages = false;

  bool _onlyMyLogs = false;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filtersExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final activeElderProvider =
        Provider.of<ActiveElderProvider>(context, listen: false);
    if (activeElderProvider.activeElder != null) {
      final currentElderId = activeElderProvider.activeElder!.id;
      _fetchElderAssociatedUsers(currentElderId);
      _loadHiddenMessageIds(currentElderId);
    }
    // Mark messages as read when the Timeline screen first becomes visible.
    // This handles the case where the user navigates here directly (not via
    // the nav tab tap, which already calls markRead in home_screen.dart).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<MessageProvider>(context, listen: false).markRead();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);

    final activeElder = Provider.of<ActiveElderProvider>(context).activeElder;
    if (activeElder != null) {
      _loadHiddenMessageIds(activeElder.id);
      if (_elderAssociatedUsers.isEmpty ||
          (_elderAssociatedUsers.isNotEmpty &&
              !activeElder.caregiverUserIds
                  .contains(_elderAssociatedUsers.first.uid) &&
              activeElder.primaryAdminUserId !=
                  _elderAssociatedUsers.first.uid)) {
        _fetchElderAssociatedUsers(activeElder.id);
      }
    } else {
      if (_hiddenMessageIds.isNotEmpty) {
        if (mounted) setState(() => _hiddenMessageIds.clear());
      }
      if (_elderAssociatedUsers.isNotEmpty) {
        if (mounted) setState(() => _elderAssociatedUsers.clear());
      }
      if (_showOnlyHiddenMessages) {
        if (mounted) setState(() => _showOnlyHiddenMessages = false);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void showNewMessageInput() {
    if (mounted) {
      setState(() {
        _editingMessageId = null;
        _messageController.clear();
        _isPublicMessage = true;
        _selectedUserIdsForMessage.clear();
        _showMessageInput = true;
      });
    }
  }

  bool get _hasActiveFilters =>
      _onlyMyLogs ||
      _startDate != null ||
      _endDate != null ||
      _searchQuery.isNotEmpty;

  void _resetDateFilters() {
    if (mounted) {
      setState(() {
        _startDate = null;
        _endDate = null;
        _onlyMyLogs = false;
        _searchQuery = '';
        _searchCtrl.clear();
      });
    }
  }

  Future<void> _fetchElderAssociatedUsers(String elderId) async {
    if (_isLoadingUsers) return;
    if (mounted) setState(() => _isLoadingUsers = true);
    try {
      final firestoreService = context.read<FirestoreService>();
      final users =
          await firestoreService.getAssociatedUsersForElder(elderId);
      if (mounted) setState(() => _elderAssociatedUsers = users);
    } catch (e) {
      debugPrint('Error fetching associated users: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  // FIX 2: Shortened timestamp format 'MMM d, y, hh:mm a' → 'MMM d, h:mm a'.
  // The old format produced strings like "Jul 6, 2025, 03:28 PM" which
  // overflowed the card header Row by 14px on a standard phone screen.
  // Dropping the year fixes the overflow without losing meaningful information.
  String _formatFullTimestamp(Timestamp? timestamp, AppLocalizations l10n) {
    if (timestamp == null) return l10n.timelineUnknownTime;
    try {
      final dt = timestamp.toDate();
      return DateFormat('MMM d, h:mm a', l10n.localeName).format(dt);
    } catch (_) {
      return l10n.timelineInvalidTime;
    }
  }

  Future<void> _handleComposerSend({
    required String text,
    required bool isPublic,
    required List<String> visibleToUserIds,
    String? editingMessageId,
  }) async {
    final User? user = FirebaseAuth.instance.currentUser;
    final activeElder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;

    if (user == null) {
      if (mounted) {
        _showSnackBar(_l10n.timelineMustBeLoggedInToPost, isError: true);
      }
      return;
    }
    if (activeElder == null) {
      if (mounted) {
        _showSnackBar(_l10n.timelineSelectElderToPost, isError: true);
      }
      return;
    }

    final String currentUserId = user.uid;
    final List<String> resolvedIds = [];
    if (isPublic) {
      resolvedIds.add('all');
    } else {
      resolvedIds.addAll(visibleToUserIds);
      if (!resolvedIds.contains(currentUserId)) {
        resolvedIds.add(currentUserId);
      }
    }

    final firestoreService = context.read<FirestoreService>();

    if (editingMessageId != null) {
      await firestoreService.updateJournalEntry(
        entryId: editingMessageId,
        type: EntryType.message,
        text: text,
        visibleToUserIds: resolvedIds,
        isPublic: isPublic,
      );
      if (mounted) {
        _showSnackBar(_l10n.timelineMessageUpdatedSuccess, isError: false);
      }
    } else {
      await firestoreService.addJournalEntry(
        elderId: activeElder.id,
        type: EntryType.message,
        creatorId: currentUserId,
        text: text,
        visibleToUserIds: resolvedIds,
        isPublic: isPublic,
      );
    }

    _closeComposer();
  }

  void _closeComposer() {
    if (!mounted) return;
    _messageController.clear();
    setState(() {
      _showMessageInput = false;
      _isPublicMessage = true;
      _selectedUserIdsForMessage.clear();
      _editingMessageId = null;
    });
  }

  String _getHiddenMessagesPreferenceKey(String elderId) {
    final currentUserId = AuthService.currentUserId;
    if (currentUserId == null || elderId.isEmpty) return '';
    return '$_hiddenMessagesKeyPrefix${currentUserId}_$elderId';
  }

  Future<void> _loadHiddenMessageIds(String elderId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getHiddenMessagesPreferenceKey(elderId);
    if (key.isEmpty) return;

    final List<String>? ids = prefs.getStringList(key);
    final newHiddenSet = Set<String>.from(ids ?? []);

    if (mounted) {
      final bool changed = _hiddenMessageIds.length != newHiddenSet.length ||
          !_hiddenMessageIds.containsAll(newHiddenSet);
      if (changed) setState(() => _hiddenMessageIds = newHiddenSet);
      if (newHiddenSet.isEmpty && _showOnlyHiddenMessages) {
        setState(() => _showOnlyHiddenMessages = false);
      }
    }
  }

  void _startEditMessage(JournalEntry entry) {
    if (entry.id == null || entry.id!.isEmpty) return;
    if (mounted) {
      setState(() {
        _editingMessageId = entry.id;
        _messageController.text = entry.text ?? '';
        _isPublicMessage = entry.isPublic ?? true;
        _selectedUserIdsForMessage = List<String>.from(
            (entry.visibleToUserIds as List<dynamic>?)
                    ?.where((id) => id != 'all') ??
                []);
        _showMessageInput = true;

        final activeElder =
            Provider.of<ActiveElderProvider>(context, listen: false)
                .activeElder;
        if (activeElder != null &&
            _elderAssociatedUsers.isEmpty &&
            !_isLoadingUsers) {
          _fetchElderAssociatedUsers(activeElder.id);
        }
      });
    }
  }

  Future<void> _deleteMessage(JournalEntry entry) async {
    if (entry.id == null || entry.id!.isEmpty) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.timelineConfirmDeleteMessageTitle),
        content: Text(_l10n.timelineConfirmDeleteMessageContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final firestoreService = context.read<FirestoreService>();
      try {
        await firestoreService.deleteJournalEntry(entry.id!);
        if (mounted) {
          _showSnackBar(_l10n.timelineMessageDeletedSuccess,
              isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(
              _l10n.timelineErrorDeletingMessage(e.toString()),
              isError: true);
        }
      }
    }
  }

  Future<void> _hideMessageAndPersist(JournalEntry entry) async {
    if (entry.id == null || entry.id!.isEmpty) return;
    final activeElder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
    if (activeElder == null) return;

    final key = _getHiddenMessagesPreferenceKey(activeElder.id);
    if (key.isEmpty) return;

    if (mounted) setState(() => _hiddenMessageIds.add(entry.id!));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, _hiddenMessageIds.toList());

    if (mounted) {
      _showSnackBar(_l10n.timelineMessageHiddenSuccess, isError: false);
    }
  }

  Future<void> _unhideMessageAndPersist(JournalEntry entry) async {
    if (entry.id == null || entry.id!.isEmpty) return;
    final activeElder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
    if (activeElder == null) return;

    final key = _getHiddenMessagesPreferenceKey(activeElder.id);
    if (key.isEmpty) return;

    if (mounted) setState(() => _hiddenMessageIds.remove(entry.id!));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, _hiddenMessageIds.toList());

    if (mounted) {
      _showSnackBar(_l10n.timelineMessageUnhiddenSuccess, isError: false);
      if (_hiddenMessageIds.isEmpty && _showOnlyHiddenMessages) {
        setState(() => _showOnlyHiddenMessages = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () =>
              setState(() => _filtersExpanded = !_filtersExpanded),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              border: Border(
                bottom: BorderSide(
                  color: _filtersExpanded
                      ? AppTheme.primaryColor.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: _hasActiveFilters
                      ? AppTheme.accentColor
                      : AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _l10n.timelineFilterOnlyMyLogs.split(' ').first,
                  style: _theme.textTheme.bodyMedium?.copyWith(
                    color: _hasActiveFilters
                        ? AppTheme.accentColor
                        : AppTheme.textSecondary,
                    fontWeight: _hasActiveFilters
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                if (_onlyMyLogs)
                  _FilterChip(
                    label: 'Mine',
                    onRemove: () => setState(() => _onlyMyLogs = false),
                  ),
                if (_startDate != null)
                  _FilterChip(
                    label:
                        'From ${DateFormat.MMMd(_l10n.localeName).format(_startDate!)}',
                    onRemove: () => setState(() => _startDate = null),
                  ),
                if (_endDate != null)
                  _FilterChip(
                    label:
                        'To ${DateFormat.MMMd(_l10n.localeName).format(_endDate!)}',
                    onRemove: () => setState(() => _endDate = null),
                  ),
                if (_searchQuery.isNotEmpty)
                  _FilterChip(
                    label: '"${_searchQuery.length > 12 ? '${_searchQuery.substring(0, 10)}…' : _searchQuery}"',
                    onRemove: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  ),
                const Spacer(),
                AnimatedRotation(
                  turns: _filtersExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: _filtersExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Container(
            color: AppTheme.backgroundGray,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _l10n.timelineFilterOnlyMyLogs,
                      style: _theme.textTheme.bodyMedium,
                    ),
                    Switch(
                      value: _onlyMyLogs,
                      onChanged: (value) =>
                          setState(() => _onlyMyLogs = value),
                      activeColor: AppTheme.accentColor,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Text search
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search entries...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _DatePickerButton(
                      label: _startDate == null
                          ? _l10n.timelineFilterFromDate
                          : 'From: ${DateFormat.yMd(_l10n.localeName).format(_startDate!)}',
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null && mounted) {
                          setState(() => _startDate = d);
                        }
                      },
                      theme: _theme,
                    ),
                    _DatePickerButton(
                      label: _endDate == null
                          ? _l10n.timelineFilterToDate
                          : 'To: ${DateFormat.yMd(_l10n.localeName).format(_endDate!)}',
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null && mounted) {
                          setState(() => _endDate = d);
                        }
                      },
                      theme: _theme,
                    ),
                  ],
                ),
                if (_hasActiveFilters)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        _resetDateFilters();
                        setState(() => _filtersExpanded = false);
                      },
                      child: Text(
                        _l10n.timelineFilterResetDates,
                        style: const TextStyle(
                            color: AppTheme.accentColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final elderProv = Provider.of<ActiveElderProvider>(context);
    final activeElder = elderProv.activeElder;
    final isMultiView = elderProv.isMultiView;

    Stream<List<JournalEntry>>? journalEntriesStream;
    if (user != null) {
      final firestoreService = context.read<FirestoreService>();
      if (isMultiView && elderProv.allElderIds.isNotEmpty) {
        journalEntriesStream =
            firestoreService.getJournalEntriesStreamForElders(
          elderIds: elderProv.allElderIds,
          currentUserId: user.uid,
          startDate: _startDate,
          endDate: _endDate,
        );
      } else if (activeElder != null) {
        journalEntriesStream = firestoreService.getJournalEntriesStream(
          elderId: activeElder.id,
          currentUserId: user.uid,
          startDate: _startDate,
          endDate: _endDate,
          onlyMyLogs: _onlyMyLogs,
        );
      }
    }

    return Scaffold(
      // Hide FAB in multi-view (posting requires a specific elder context).
      floatingActionButton: !isMultiView && Provider.of<ActiveElderProvider>(context, listen: false).canLog
          ? FloatingActionButton.extended(
              heroTag: 'timelineLogFab',
              onPressed: () =>
                  showEntryDialog(context, onNewMessage: showNewMessageInput),
        tooltip: _l10n.timelineAddNewLogTooltip,
        icon: const Icon(Icons.add_comment_outlined),
            label: Text(_l10n.dialogTitleAddNewLog.split(' ').last),
            )
          : null,
      body: Column(
        children: [
          if (activeElder != null) _buildFilterBar(context),
          if (_showMessageInput && Provider.of<ActiveElderProvider>(context, listen: false).canMessage)
            TimelineMessageComposer(
              elderName: (activeElder?.preferredName?.isNotEmpty == true
                      ? activeElder!.preferredName
                      : activeElder?.profileName) ??
                  _l10n.timelineUnknownUser,
              associatedUsers: _elderAssociatedUsers,
              isLoadingUsers: _isLoadingUsers,
              editingMessageId: _editingMessageId,
              initialText: _editingMessageId != null
                  ? _messageController.text
                  : null,
              initialIsPublic: _isPublicMessage,
              initialSelectedUserIds: _selectedUserIdsForMessage,
              onSend: _handleComposerSend,
              onClose: _closeComposer,
            ),
          Expanded(
            child: StreamBuilder<List<JournalEntry>>(
              stream: journalEntriesStream,
              builder: (context,
                  AsyncSnapshot<List<JournalEntry>> snapshot) {
                if (journalEntriesStream == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        activeElder == null
                            ? _l10n.timelineSelectElderToView
                            : _l10n.timelinePleaseLogInToView,
                        style: AppStyles.emptyStateText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: List.generate(
                          5, (_) => const SkeletonListTile()),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  debugPrint(
                      'Timeline StreamBuilder Error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _l10n.timelineErrorLoading(
                            snapshot.error.toString()),
                        style: const TextStyle(
                            color: AppTheme.dangerColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final allDocs = snapshot.data ?? [];
                var docsToDisplay = _showOnlyHiddenMessages
                    ? allDocs
                        .where((e) =>
                            e.id != null &&
                            _hiddenMessageIds.contains(e.id!))
                        .toList()
                    : allDocs
                        .where((e) =>
                            e.id != null &&
                            !_hiddenMessageIds.contains(e.id!))
                        .toList();

                // Text search filter — matches against entry text,
                // data values, and the logged-by name.
                if (_searchQuery.isNotEmpty) {
                  final q = _searchQuery.toLowerCase();
                  docsToDisplay = docsToDisplay.where((e) {
                    final text = (e.text ?? '').toLowerCase();
                    final data = e.data?.values
                            .map((v) => v.toString().toLowerCase())
                            .join(' ') ??
                        '';
                    final loggedBy =
                        (e.loggedByDisplayName ?? '').toLowerCase();
                    return text.contains(q) ||
                        data.contains(q) ||
                        loggedBy.contains(q);
                  }).toList();
                }

                if (docsToDisplay.isEmpty) {
                  final emptyMessage = _showOnlyHiddenMessages
                      ? _l10n.timelineNoHiddenMessages
                      : _l10n.timelineNoEntriesYet(
                          (activeElder?.preferredName?.isNotEmpty == true
                                  ? activeElder!.preferredName
                                  : activeElder?.profileName) ??
                              _l10n.timelineUnknownUser,
                        );
                  return EmptyStateWidget(
                    icon: Icons.timeline_outlined,
                    title: 'No entries yet',
                    subtitle: emptyMessage,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Force a rebuild which re-subscribes to the Firestore stream.
                    // The stream is already real-time, so this is mainly a UX gesture
                    // that gives the user confidence the data is current.
                    if (mounted) setState(() {});
                    // Small delay so the indicator is visible
                    await Future.delayed(const Duration(milliseconds: 400));
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: docsToDisplay.length,
                    separatorBuilder: (_, __) => const SizedBox.shrink(),
                    itemBuilder: (context, index) {
                      try {
                        final entry = docsToDisplay[index];
                        final isOwned = user != null &&
                            entry.loggedByUserId == user.uid;

                        Widget card = _buildTimelineCard(
                          context,
                          entry,
                          user,
                          activeElder,
                        );

                        // In multi-view, prepend an elder badge.
                        if (isMultiView && entry.elderId != null) {
                          final matchedElder = elderProv.allElders
                              .where((e) => e.id == entry.elderId)
                              .firstOrNull;
                          if (matchedElder != null) {
                            final idx = elderProv.allElders
                                .indexOf(matchedElder);
                            card = Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, top: 6),
                                  child: MultiElderTimelineBadge(
                                    elder: matchedElder,
                                    elderIndex: idx,
                                  ),
                                ),
                                card,
                              ],
                            );
                          }
                        }

                        // Swipe-to-delete — only on entries the current user owns
                        if (!isOwned || entry.id == null) {
                          return StaggeredFadeIn(index: index, child: card);
                        }

                        return StaggeredFadeIn(
                          index: index,
                          child: Dismissible(
                          key: ValueKey(entry.id),
                          direction: DismissDirection.endToStart,
                          child: card,
                          confirmDismiss: (_) async {
                            // Show the same confirmation dialog used by the popup menu
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(_l10n.timelineConfirmDeleteMessageTitle),
                                content: Text(_l10n.timelineConfirmDeleteMessageContent),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text(_l10n.cancelButton),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    style: TextButton.styleFrom(
                                        foregroundColor: AppTheme.dangerColor),
                                    child: Text(_l10n.deleteButton),
                                  ),
                                ],
                              ),
                            );
                            return confirmed == true;
                          },
                          onDismissed: (_) async {
                            HapticUtils.warning();
                            try {
                              final firestoreService = context.read<FirestoreService>();
                              await firestoreService.deleteJournalEntry(entry.id!);
                              if (mounted) {
                                _showSnackBar(
                                    _l10n.timelineMessageDeletedSuccess,
                                    isError: false);
                              }
                            } catch (e) {
                              if (mounted) {
                                _showSnackBar(
                                    _l10n.timelineErrorDeletingMessage(e.toString()),
                                    isError: true);
                              }
                            }
                          },
                          background: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerColor,
                              borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.delete_outline,
                                    color: Colors.white, size: 22),
                              ],
                            ),
                          ),
                        ),
                        );
                      } catch (e, s) {
                        debugPrint(
                            'ERROR building timeline item at index $index: $e');
                        debugPrint('Stack trace: $s');
                        return _buildErrorCard(index, e);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    JournalEntry entry,
    User? user,
    dynamic activeElder,
  ) {
    final type = entry.type;
    final timestamp = entry.entryTimestamp;
    final messageText = entry.text;
    final loggedBy = _sanitizeDisplayName(
        entry.loggedByDisplayName ?? _l10n.timelineUnknownUser);
    final avatarUrl = entry.loggedByUserAvatarUrl;
    final data = entry.data;
    final isPublic = entry.isPublic ?? true;
    final displayTime = _formatFullTimestamp(timestamp, _l10n);

    final style = _entryTypeStyle(type);
    final color = style.accent;
    final backgroundColor = style.surface;

    String title;
    String summary;

    switch (type) {
      case EntryType.message:
        title = _l10n.timelineItemTitleMessage;
        summary = messageText ?? _l10n.timelineEmptyMessage;
        break;
      case EntryType.medication:
        title = _l10n.timelineItemTitleMedication;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.sleep:
        title = _l10n.timelineItemTitleSleep;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.meal:
        title = _l10n.timelineItemTitleMeal;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.mood:
        title = _l10n.timelineItemTitleMood;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.pain:
        title = _l10n.timelineItemTitlePain;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.activity:
        title = _l10n.timelineItemTitleActivity;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.vital:
        title = _l10n.timelineItemTitleVital;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.expense:
        title = _l10n.timelineItemTitleExpense;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.image:
        title = _l10n.timelineItemTitleImage;
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.caregiverJournal:
        title = _l10n.caregiverJournal;
        summary = data?['note'] as String? ?? _l10n.noContent;
        break;
      case EntryType.handoff:
        title = 'Shift Handoff';
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.incontinence:
        title = 'Incontinence';
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.nightWaking:
        title = 'Night Waking';
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.hydration:
        title = 'Fluid Intake';
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.visitor:
        title = 'Visitor';
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      case EntryType.custom:
        title = data?['customTypeName'] as String? ?? 'Custom Entry';
        summary = _extractSummaryFromData(data, type, _l10n);
        break;
      default:
        title = type.name.isNotEmpty
            ? '${type.name[0].toUpperCase()}${type.name.substring(1)}'
            : _l10n.timelineItemTitleEntry;
        summary = _extractSummaryFromData(data, type, _l10n);
    }

    final String initial = (loggedBy.isNotEmpty &&
            loggedBy != _l10n.timelineUnknownUser &&
            loggedBy != _l10n.timelineAnonymousUser)
        ? loggedBy[0].toUpperCase()
        : '';

    final Color avatarBg = initial.isNotEmpty
        ? _avatarColorForInitial(initial)
        : AppTheme.backgroundGray;
    final Color avatarFg = initial.isNotEmpty
        ? AppTheme.textOnPrimary
        : AppTheme.textSecondary;

    Widget avatarChild;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      avatarChild = const SizedBox.shrink();
    } else if (initial.isNotEmpty) {
      avatarChild = Text(
        initial,
        style: TextStyle(
            fontSize: 16, color: avatarFg, fontWeight: FontWeight.bold),
      );
    } else {
      avatarChild =
          Icon(Icons.person_outline, size: 20, color: avatarFg);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CachedAvatar(
                        imageUrl: avatarUrl,
                        radius: 22,
                        backgroundColor: avatarBg,
                        fallbackChild: avatarChild,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: AppStyles.timelineItemTitle
                                        .copyWith(color: color),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  displayTime,
                                  style: AppStyles.timelineItemMeta,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              summary.isEmpty
                                  ? (type == EntryType.message
                                      ? _l10n.timelineEmptyMessage
                                      : _l10n.timelineNoDetailsProvided)
                                  : summary,
                              style: AppStyles.timelineItemSubtitle
                                  .copyWith(
                                fontStyle: summary.isEmpty &&
                                        type != EntryType.message
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Image thumbnail — shown inline on image entries
                            if (type == EntryType.image) ...[  
                              const SizedBox(height: 8),
                              _ImageThumbnail(
                                imageUrl: data?['url'] as String? ?? '',
                                imageTitle: data?['title'] as String? ?? '',
                              ),
                            ],
                            if (!isPublic &&
                                (type == EntryType.message ||
                                    type ==
                                        EntryType.caregiverJournal)) ...[
                              const SizedBox(height: 6),
                              // NEW: lock icon + colored tag replacing
                              // the plain italic "Private Message" text.
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppTheme.tileBlueGrey
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(AppTheme.radiusXL),
                                      border: Border.all(
                                        color: AppTheme.tileBlueGrey
                                            .withValues(alpha: 0.35),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock_outline,
                                          size: 11,
                                          color: AppTheme.tileBlueGrey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _l10n
                                              .timelinePrivateMessageIndicator,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.tileBlueGrey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 6),
                            // FIX 3: "Logged by" text was unconstrained in a
                            // spaceBetween Row next to PopupMenuButton. A long
                            // display name (e.g. a full email address) pushed
                            // the menu button off-screen, causing the 14px
                            // overflow error. Wrapping in Expanded constrains
                            // the text and lets it ellipsis gracefully.
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    _l10n.timelineLoggedBy(loggedBy),
                                    style: AppStyles.timelineItemMeta,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      size: 20,
                                      color: AppTheme.textSecondary),
                                  onSelected: (value) {
                                    if (user == null) return;
                                    switch (value) {
                                      case 'delete':
                                        _deleteMessage(entry);
                                        break;
                                      case 'edit':
                                        if (type ==
                                                EntryType.message ||
                                            type ==
                                                EntryType
                                                    .caregiverJournal) {
                                          _startEditMessage(entry);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Editing this entry type is not yet supported.',
                                              ),
                                            ),
                                          );
                                        }
                                        break;
                                      case 'hide':
                                        _hideMessageAndPersist(entry);
                                        break;
                                      case 'unhide':
                                        _unhideMessageAndPersist(entry);
                                        break;
                                    }
                                  },
                                  itemBuilder: (BuildContext context) {
                                    final items =
                                        <PopupMenuEntry<String>>[];
                                    if (user == null) return items;
                                    if (_showOnlyHiddenMessages) {
                                      items.add(PopupMenuItem<String>(
                                        value: 'unhide',
                                        child: Text(_l10n
                                            .timelineUnhideMessage),
                                      ));
                                    } else {
                                      if (entry.loggedByUserId ==
                                          user.uid) {
                                        items.add(PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Text(_l10n
                                              .timelineEditMessage),
                                        ));
                                        items.add(PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text(
                                            _l10n.timelineDeleteMessage,
                                            style: const TextStyle(
                                                color: AppTheme
                                                    .dangerColor),
                                          ),
                                        ));
                                      } else if (type ==
                                          EntryType.message) {
                                        items.add(PopupMenuItem<String>(
                                          value: 'hide',
                                          child: Text(_l10n
                                              .timelineHideMessage),
                                        ));
                                      }
                                    }
                                    return items;
                                  },
                                ),
                              ],
                            ),
                            // ── Reaction row ────────────────────────
                            if (entry.id != null &&
                                user != null &&
                                entry.loggedByUserId != user.uid)
                              _buildReactionRow(entry, user),
                            // Show reaction count even on own entries
                            if (entry.id != null &&
                                user != null &&
                                entry.loggedByUserId == user.uid &&
                                entry.reactionCount > 0)
                              _buildReactionCount(entry),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReactionRow(JournalEntry entry, User user) {
    final hasReacted = entry.hasReactedBy(user.uid);
    final count = entry.reactionCount;
    final firestoreService = context.read<FirestoreService>();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              try {
                if (hasReacted) {
                  await firestoreService.removeReaction(entry.id!, user.uid);
                  HapticUtils.tap();
                } else {
                  await firestoreService.addReaction(entry.id!, user.uid);
                  HapticUtils.success();
                }
              } catch (e) {
                debugPrint('Reaction toggle error: $e');
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasReacted ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: hasReacted
                      ? AppTheme.tilePinkBright
                      : AppTheme.textLight,
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasReacted
                          ? AppTheme.tilePinkBright
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _reactionLabel(entry),
                style: TextStyle(
                    fontSize: 10, color: AppTheme.textLight),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReactionCount(JournalEntry entry) {
    final count = entry.reactionCount;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.favorite, size: 14, color: AppTheme.tilePinkBright),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.tilePinkBright),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _reactionLabel(entry),
              style: TextStyle(fontSize: 10, color: AppTheme.textLight),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _reactionLabel(JournalEntry entry) {
    final uids = entry.reactedByUids;
    if (uids.isEmpty) return '';
    // Try to resolve names from the entry's reactor UIDs.
    // For simplicity, show "N caregivers" — name resolution would require
    // an async lookup that's not worth the complexity for a label.
    if (uids.length == 1) return '1 caregiver acknowledged';
    return '${uids.length} caregivers acknowledged';
  }

  Widget _buildErrorCard(int index, Object error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border:
            Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        _l10n.timelineErrorRenderingItem(
            index.toString(), error.toString()),
        style: const TextStyle(color: AppTheme.dangerColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Thin wrapper around [extractEntrySummary] so existing call sites
  /// don't need to be touched. The shared implementation lives in
  /// `lib/utils/entry_summary.dart`.
  String _extractSummaryFromData(
    Map<String, dynamic>? entryData,
    EntryType type,
    AppLocalizations l10n,
  ) =>
      extractEntrySummary(entryData, type, l10n);
}


// ---------------------------------------------------------------------------
// _ImageThumbnail — shown on image-type timeline cards
// ---------------------------------------------------------------------------

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({
    required this.imageUrl,
    required this.imageTitle,
  });
  final String imageUrl;
  final String imageTitle;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(imageTitle)),
            body: Center(
              child: InteractiveViewer(
                child: CachedImage(imageUrl: imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 160),
          child: CachedImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 13,
              color: AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.calendar_today,
          size: 16, color: AppTheme.primaryColor),
      label: Text(label,
          style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 13)),
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          side: BorderSide(
              color: AppTheme.textLight.withValues(alpha: 0.5)),
        ),
        backgroundColor: AppTheme.backgroundColor,
      ),
    );
  }
}
