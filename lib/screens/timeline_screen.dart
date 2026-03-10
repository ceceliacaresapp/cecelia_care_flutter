// lib/screens/timeline_screen.dart

import 'package:cecelia_care_flutter/widgets/show_entry_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/widgets/user_selector_widget.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => TimelineScreenState();
}

class TimelineScreenState extends State<TimelineScreen> {
  late AppLocalizations _l10n;
  late ThemeData _theme;

  final TextEditingController _messageController = TextEditingController();
  bool _showMessageInput = false;
  List<String> _selectedUserIdsForMessage = [];
  bool _isPublicMessage = true;

  List<UserProfile> _elderAssociatedUsers = [];
  bool _isLoadingUsers = false;

  bool _isPosting = false;
  String? _editingMessageId;

  Set<String> _hiddenMessageIds = {};
  static const String _hiddenMessagesKeyPrefix = 'hiddenMessages_';
  bool _showOnlyHiddenMessages = false;

  bool _onlyMyLogs = false;
  DateTime? _startDate;
  DateTime? _endDate;

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
        if (mounted) {
          setState(() => _hiddenMessageIds.clear());
        }
      }
      if (_elderAssociatedUsers.isNotEmpty) {
        if (mounted) {
          setState(() => _elderAssociatedUsers.clear());
        }
      }
      if (_showOnlyHiddenMessages) {
        if (mounted) {
          setState(() => _showOnlyHiddenMessages = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
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

  void _resetDateFilters() {
    if (mounted) {
      setState(() {
        _startDate = null;
        _endDate = null;
      });
    }
  }

  Future<void> _fetchElderAssociatedUsers(String elderId) async {
    if (_isLoadingUsers) return;
    if (mounted) {
      setState(() => _isLoadingUsers = true);
    }
    try {
      final firestoreService = context.read<FirestoreService>();
      final users = await firestoreService.getAssociatedUsersForElder(elderId);
      if (mounted) {
        setState(() {
          _elderAssociatedUsers = users;
        });
      }
    } catch (e) {
      debugPrint('Error fetching associated users: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  String _formatFullTimestamp(Timestamp? timestamp, AppLocalizations l10n) {
    if (timestamp == null) return l10n.timelineUnknownTime;
    try {
      final dt = timestamp.toDate();
      return DateFormat('MMM d, y, hh:mm a', l10n.localeName).format(dt);
    } catch (_) {
      return l10n.timelineInvalidTime;
    }
  }

  Future<void> _submitMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _editingMessageId == null) {
      return;
    }

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

    if (mounted) {
      setState(() => _isPosting = true);
    }

    try {
      List<String> visibleToUserIds = [];
      final String currentUserId = user.uid;

      if (_isPublicMessage) {
        visibleToUserIds.add('all');
      } else {
        visibleToUserIds.addAll(_selectedUserIdsForMessage);
        if (!visibleToUserIds.contains(currentUserId)) {
          visibleToUserIds.add(currentUserId);
        }
      }

      final firestoreService = context.read<FirestoreService>();

      if (_editingMessageId != null) {
        await firestoreService.updateJournalEntry(
          entryId: _editingMessageId!,
          type: EntryType.message,
          text: text,
          visibleToUserIds: visibleToUserIds,
          isPublic: _isPublicMessage,
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
          visibleToUserIds: visibleToUserIds,
          isPublic: _isPublicMessage,
        );
      }

      _messageController.clear();
      if (mounted) {
        setState(() {
          _showMessageInput = false;
          _isPublicMessage = true;
          _selectedUserIdsForMessage.clear();
          _editingMessageId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          _editingMessageId != null
              ? _l10n.timelineErrorUpdatingMessage(e.toString())
              : _l10n.timelineCouldNotPostMessage(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
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
      bool changed = _hiddenMessageIds.length != newHiddenSet.length ||
          !_hiddenMessageIds.containsAll(newHiddenSet);
      if (changed) {
        setState(() => _hiddenMessageIds = newHiddenSet);
      }
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
            (entry.visibleToUserIds as List<dynamic>?)?.where((id) => id != 'all') ?? []);
        _showMessageInput = true;

        final activeElder =
            Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
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
          _showSnackBar(_l10n.timelineMessageDeletedSuccess, isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar(_l10n.timelineErrorDeletingMessage(e.toString()), isError: true);
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

    if (mounted) {
      setState(() {
        _hiddenMessageIds.add(entry.id!);
      });
    }

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

    if (mounted) {
      setState(() {
        _hiddenMessageIds.remove(entry.id!);
      });
    }

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

  Widget _buildFilterExpansionTile() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text('Timeline Filters', style: AppStyles.sectionTitle),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_l10n.timelineFilterOnlyMyLogs, style: _theme.textTheme.bodyMedium),
              Switch(
                value: _onlyMyLogs,
                onChanged: (value) => setState(() => _onlyMyLogs = value),
                activeThumbColor: AppTheme.accentColor,
              ),
            ],
          ),
          const Divider(),
          Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.center,
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
                  if (d != null) {
                    if (mounted) {
                      setState(() => _startDate = d);
                    }
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
                  if (d != null) {
                    if (mounted) {
                      setState(() => _endDate = d);
                    }
                  }
                },
                theme: _theme,
              ),
            ],
          ),
          if (_startDate != null || _endDate != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetDateFilters,
                child: Text(_l10n.timelineFilterResetDates),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final activeElder = Provider.of<ActiveElderProvider>(context).activeElder;

    Stream<List<JournalEntry>>? journalEntriesStream;

    if (user != null && activeElder != null) {
      final firestoreService = context.read<FirestoreService>();
      journalEntriesStream = firestoreService.getJournalEntriesStream(
        elderId: activeElder.id,
        currentUserId: user.uid,
        startDate: _startDate,
        endDate: _endDate,
        onlyMyLogs: _onlyMyLogs,
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEntryDialog(context, onNewMessage: showNewMessageInput),
        tooltip: _l10n.timelineAddNewLogTooltip,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(_l10n.dialogTitleAddNewLog.split(' ').last),
      ),
      body: Column(
        children: [
          if (activeElder != null) _buildFilterExpansionTile(),

          if (_showMessageInput)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    UserSelectorWidget(
                      allUsers: _elderAssociatedUsers,
                      isLoadingUsers: _isLoadingUsers,
                      initialSelectedUserIds: _selectedUserIdsForMessage,
                      initialIsPublic: _isPublicMessage,
                      onSelectionChanged: (selectedIds, isPublic) {
                        setState(() {
                          _selectedUserIdsForMessage = selectedIds;
                          _isPublicMessage = isPublic;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isPublicMessage
                          ? _l10n.timelinePostingToAll
                          : _l10n.timelinePostingToCount(
                              _selectedUserIdsForMessage.length.toString(),
                            ),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: _l10n.timelineWriteMessageHint(
                          (activeElder?.preferredName?.isNotEmpty == true
                                  ? activeElder!.preferredName
                                  : activeElder?.profileName) ??
                              _l10n.timelineUnknownUser,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        // Removed Voice Icon Suffix here
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: _isPosting ? null : _submitMessage,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentColor),
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
                                  _editingMessageId != null
                                      ? _l10n.timelineUpdateButton
                                      : _l10n.timelinePostButton,
                                ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: _isPosting
                              ? null
                              : () => setState(() {
                                    _showMessageInput = false;
                                    _messageController.clear();
                                    _isPublicMessage = true;
                                    _selectedUserIdsForMessage.clear();
                                    _editingMessageId = null;
                                  }),
                          child: Text(_l10n.timelineCancelButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<JournalEntry>>(
              stream: journalEntriesStream,
              builder: (context, AsyncSnapshot<List<JournalEntry>> snapshot) {
                if (journalEntriesStream == null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('Timeline StreamBuilder Error: ${snapshot.error}');
                  debugPrint('Timeline StreamBuilder StackTrace: ${snapshot.stackTrace}');
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _l10n.timelineErrorLoading(snapshot.error.toString()),
                        style: const TextStyle(color: AppTheme.dangerColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final allDocs = snapshot.data ?? [];
                final docsToDisplay = _showOnlyHiddenMessages
                    ? allDocs.where((e) => e.id != null && _hiddenMessageIds.contains(e.id!)).toList()
                    : allDocs.where((e) => e.id != null && !_hiddenMessageIds.contains(e.id!)).toList();

                if (docsToDisplay.isEmpty) {
                  final emptyMessage = _showOnlyHiddenMessages
                      ? _l10n.timelineNoHiddenMessages
                      : _l10n.timelineNoEntriesYet(
                          (activeElder?.preferredName?.isNotEmpty == true
                                  ? activeElder!.preferredName
                                  : activeElder?.profileName) ??
                              _l10n.timelineUnknownUser,
                        );
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        emptyMessage,
                        textAlign: TextAlign.center,
                        style: AppStyles.emptyStateText,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docsToDisplay.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    try {
                      final entry = docsToDisplay[index];
                      final type = entry.type;
                      final timestamp = entry.entryTimestamp;
                      final messageText = entry.text;
                      final loggedBy = entry.loggedByDisplayName ?? _l10n.timelineUnknownUser;
                      final avatarUrl = entry.loggedByUserAvatarUrl;
                      final data = entry.data;

                      final isPublic = entry.isPublic ?? true;
                      final displayTime = _formatFullTimestamp(timestamp, _l10n);

                      String title;
                      Color color;
                      String summary;

                      switch (type) {
                        case EntryType.message:
                          title = _l10n.timelineItemTitleMessage;
                          color = Colors.orange.shade700;
                          summary = messageText ?? _l10n.timelineEmptyMessage;
                          break;
                        case EntryType.medication:
                          title = _l10n.timelineItemTitleMedication;
                          color = AppTheme.primaryColor;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.sleep:
                          title = _l10n.timelineItemTitleSleep;
                          color = Colors.blue.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.meal:
                          title = _l10n.timelineItemTitleMeal;
                          color = Colors.green.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.mood:
                          title = _l10n.timelineItemTitleMood;
                          color = Colors.purple.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.pain:
                          title = _l10n.timelineItemTitlePain;
                          color = Colors.red.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.activity:
                          title = _l10n.timelineItemTitleActivity;
                          color = Colors.teal.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.vital:
                          title = _l10n.timelineItemTitleVital;
                          color = Colors.cyan.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.expense:
                          title = _l10n.timelineItemTitleExpense;
                          color = Colors.brown.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.image:
                          title = _l10n.timelineItemTitleImage;
                          color = Colors.indigo.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                          break;
                        case EntryType.caregiverJournal:
                          title = _l10n.caregiverJournal;
                          color = Colors.grey.shade600;
                          summary = data?['note'] ?? _l10n.noContent;
                          break;
                        default:
                          title = type.name.isNotEmpty
                              ? '${type.name[0].toUpperCase()}${type.name.substring(1)}'
                              : _l10n.timelineItemTitleEntry;
                          color = Colors.grey.shade700;
                          summary = _extractSummaryFromData(data, type, _l10n);
                      }

                      String initial = '';
                      Color bg;
                      Color fg = AppTheme.textOnPrimary;

                      if (loggedBy.isNotEmpty &&
                          loggedBy != _l10n.timelineUnknownUser &&
                          loggedBy != _l10n.timelineAnonymousUser) {
                        initial = loggedBy[0].toUpperCase();
                        bg = (initial == 'C') ? AppTheme.primaryColor : Colors.teal;
                      } else {
                        bg = AppTheme.backgroundGray;
                        fg = AppTheme.textSecondary;
                      }

                      Widget avatarChild;
                      if (avatarUrl != null && avatarUrl.isNotEmpty) {
                        avatarChild = Image.network(avatarUrl, fit: BoxFit.cover);
                      } else if (initial.isNotEmpty) {
                        avatarChild = Text(
                          initial,
                          style: TextStyle(
                            fontSize: 20,
                            color: fg,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      } else {
                        avatarChild = Icon(
                          Icons.person_outline,
                          size: 22,
                          color: fg,
                        );
                      }

                      final backgroundColor = (type == EntryType.message ||
                              type == EntryType.caregiverJournal)
                          ? Colors.orange.shade50
                          : AppTheme.backgroundColor;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(width: 6, color: color),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                                              ? NetworkImage(avatarUrl)
                                              : null,
                                          backgroundColor: bg,
                                          child: (avatarUrl != null && avatarUrl.isNotEmpty)
                                              ? null
                                              : avatarChild,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      title,
                                                      style: AppStyles.timelineItemTitle.copyWith(color: color),
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
                                              const SizedBox(height: 4),
                                              Text(
                                                summary.isEmpty
                                                    ? (type == EntryType.message
                                                        ? _l10n.timelineEmptyMessage
                                                        : _l10n.timelineNoDetailsProvided)
                                                    : summary,
                                                style: AppStyles.timelineItemSubtitle.copyWith(
                                                  fontStyle: summary.isEmpty && type != EntryType.message
                                                      ? FontStyle.italic
                                                      : FontStyle.normal,
                                                ),
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (!isPublic &&
                                                  (type == EntryType.message || type == EntryType.caregiverJournal)) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  _l10n.timelinePrivateMessageIndicator,
                                                  style: AppStyles.timelineItemMeta.copyWith(
                                                    fontStyle: FontStyle.italic,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                              const SizedBox(height: 6),
                                              Text(
                                                _l10n.timelineLoggedBy(loggedBy),
                                                style: AppStyles.timelineItemMeta,
                                              ),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: PopupMenuButton<String>(
                                                  icon: const Icon(Icons.more_vert, size: 20),
                                                  onSelected: (value) {
                                                    if (user == null) return;
                                                    switch (value) {
                                                      case 'delete':
                                                        _deleteMessage(entry);
                                                        break;
                                                      case 'edit':
                                                        if (type == EntryType.message ||
                                                            type == EntryType.caregiverJournal) {
                                                          _startEditMessage(entry);
                                                        } else {
                                                          ScaffoldMessenger.of(context).showSnackBar(
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
                                                    final items = <PopupMenuEntry<String>>[];
                                                    if (user == null) return items;
                                                    if (_showOnlyHiddenMessages) {
                                                      items.add(
                                                        PopupMenuItem<String>(
                                                          value: 'unhide',
                                                          child: Text(_l10n.timelineUnhideMessage),
                                                        ),
                                                      );
                                                    } else {
                                                      if (entry.loggedByUserId == user.uid) {
                                                        items.add(
                                                          PopupMenuItem<String>(
                                                            value: 'edit',
                                                            child: Text(_l10n.timelineEditMessage),
                                                          ),
                                                        );
                                                        items.add(
                                                          PopupMenuItem<String>(
                                                            value: 'delete',
                                                            child: Text(
                                                              _l10n.timelineDeleteMessage,
                                                              style:
                                                                  const TextStyle(color: AppTheme.dangerColor),
                                                            ),
                                                          ),
                                                        );
                                                      } else if (type == EntryType.message) {
                                                        items.add(
                                                          PopupMenuItem<String>(
                                                            value: 'hide',
                                                            child: Text(_l10n.timelineHideMessage),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                    return items;
                                                  },
                                                ),
                                              ),
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
                    } catch (e, s) {
                      debugPrint('ERROR building timeline item at index $index: $e');
                      debugPrint('Stack trace for item error: $s');
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _l10n.timelineErrorRenderingItem(index.toString(), e.toString()),
                          style: const TextStyle(color: AppTheme.dangerColor),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _extractSummaryFromData(
    Map<String, dynamic>? entryData,
    EntryType type,
    AppLocalizations l10n,
  ) {
    if (entryData == null || entryData.isEmpty) {
      return l10n.timelineSummaryDetailsUnavailable;
    }

    try {
      switch (type) {
        case EntryType.medication:
          final name =
              entryData['name'] as String? ?? l10n.timelineSummaryNotApplicable;
          final dose = entryData['dose'] as String? ?? '';
          final taken = entryData['taken'] as bool?;
          final status = taken == true
              ? l10n.timelineSummaryMedicationStatusTaken
              : taken == false
                  ? l10n.timelineSummaryMedicationStatusNotTaken
                  : '';
          return l10n.timelineSummaryMedicationFormat(name, dose, status).trim();

        case EntryType.sleep:
          final duration = entryData['totalDuration'] as String? ??
              l10n.timelineSummaryNotApplicable;
          final qualityValue = entryData['quality']?.toString();
          final quality = (qualityValue != null && qualityValue.isNotEmpty)
              ? l10n.timelineSummarySleepQualityFormat(qualityValue)
              : '';
          final notes = entryData['notes'] as String? ?? '';
          return l10n.timelineSummarySleepFormat(duration, quality, notes);

        case EntryType.meal:
          final description = entryData['description'] as String? ??
              l10n.timelineSummaryNotApplicable;
          final caloriesValue = entryData['calories']?.toString();
          final calories = (caloriesValue != null && caloriesValue.isNotEmpty)
              ? l10n.timelineSummaryMealCaloriesFormat(caloriesValue)
              : '';
          return l10n.timelineSummaryMealFormat(description, calories);

        case EntryType.mood:
          final moodLevel = entryData['moodLevel']?.toString() ??
              l10n.timelineSummaryNotApplicable;
          final notesValue = entryData['note'] as String?;
          final notes = (notesValue != null && notesValue.isNotEmpty)
              ? l10n.timelineSummaryMoodNotesFormat(notesValue)
              : '';
          return l10n.timelineSummaryMoodFormat(moodLevel, notes);

        case EntryType.pain:
          final intensity = entryData['intensity']?.toString() ??
              l10n.timelineSummaryNotApplicable;
          final locationValue = entryData['location'] as String? ?? '';
          final location = locationValue.isNotEmpty
              ? l10n.timelineSummaryPainLocationFormat(locationValue)
              : '';
          return l10n.timelineSummaryPainFormat(intensity, location).trim();

        case EntryType.activity:
          final activityType = entryData['activityType'] as String? ??
              l10n.timelineItemTitleActivity;
          final durationValue = entryData['duration']?.toString() ?? '';
          final duration = durationValue.isNotEmpty
              ? l10n.timelineSummaryActivityDurationFormat(durationValue)
              : '';
          return l10n.timelineSummaryActivityFormat(activityType, duration);

        case EntryType.vital:
          final vitalType = entryData['vitalType'] as String? ?? '';
          final value =
              entryData['value'] as String? ?? l10n.timelineSummaryNotApplicable;
          final unit = entryData['unit'] as String? ?? '';
          return l10n.timelineSummaryVitalFormatGeneric(vitalType, value, unit);

        case EntryType.expense:
          final category = entryData['category'] as String? ??
              l10n.timelineItemTitleExpense;
          final amount =
              entryData['amount']?.toString() ?? l10n.timelineSummaryNotApplicable;
          final descriptionValue = entryData['description'] as String? ?? '';
          final description = descriptionValue.isNotEmpty
              ? l10n.timelineSummaryExpenseDescriptionFormat(descriptionValue)
              : '';
          return l10n
              .timelineSummaryExpenseFormat(category, amount, description)
              .trim();

        case EntryType.image:
          final title =
              entryData['title'] as String? ?? l10n.imageUploadDefaultTitle;
          return l10n.timelineSummaryImageFormat(title);

        case EntryType.caregiverJournal:
          return entryData['note'] as String? ?? l10n.noContent;

        default:
          return entryData['text'] as String? ?? l10n.timelineNoDetailsProvided;
      }
    } catch (e, s) {
      debugPrint(
          "Error in _extractSummaryFromData for type '${type.name}' with data $entryData: $e");
      debugPrint('Stack trace for summary error: $s');
      return l10n.timelineSummaryErrorProcessing;
    }
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
      icon:
          const Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
      label: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: theme.textTheme.bodyLarge?.color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.textLight.withOpacity(0.5)),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 1,
      ),
    );
  }
}