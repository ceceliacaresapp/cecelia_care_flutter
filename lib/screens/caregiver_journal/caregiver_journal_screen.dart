// lib/screens/caregiver_journal/caregiver_journal_screen.dart
//
// Private caregiver journal — entries are stored in the top-level
// `caregiverJournalEntries` collection (NOT in `journalEntries`), so they
// never appear on the shared care-recipient timeline.
//
// Firestore document shape:
//   caregiverJournalEntries/{id}
//     userId      : String   — author's UID (rules enforce author-only access)
//     note        : String   — journal body text
//     prompt      : String?  — the gratitude prompt used (null if free-form)
//     createdAt   : Timestamp
//     updatedAt   : Timestamp

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/gratitude_prompts.dart';
import 'package:cecelia_care_flutter/providers/gamification_provider.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';

// Purple — matches the Self Care tab that hosts this screen.
const _kJournalColor = AppTheme.tilePurple;
const _kPromptColor = AppTheme.tileTeal; // teal for the prompt card
const _kMaxChars = 1000;

class CareGiverJournalScreen extends StatefulWidget {
  const CareGiverJournalScreen({super.key});

  @override
  State<CareGiverJournalScreen> createState() =>
      _CareGiverJournalScreenState();
}

class _CareGiverJournalScreenState extends State<CareGiverJournalScreen> {
  final _ctrl = TextEditingController();
  String? _editingDocId;
  bool _isSubmitting = false;

  /// The gratitude prompt attached to the current composition (null = free-form).
  String? _activePrompt;

  static final _col =
      FirebaseFirestore.instance.collection('caregiverJournalEntries');

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Gratitude prompt helpers
  // ---------------------------------------------------------------------------

  void _usePrompt(String prompt) {
    setState(() {
      _activePrompt = prompt;
      _editingDocId = null;
      _ctrl.text = '';
    });
    // Auto-focus the text field so the user can start typing immediately.
  }

  void _clearPrompt() {
    setState(() => _activePrompt = null);
  }

  void _showAllPrompts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AllPromptsSheet(
        onSelect: (prompt) {
          Navigator.of(ctx).pop();
          _usePrompt(prompt);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Write helpers
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) {
      _snack(AppLocalizations.of(context)!.journalEntryCannotBeEmpty);
      return;
    }
    final uid = _currentUserId;
    if (uid == null) {
      _snack(AppLocalizations.of(context)!.pleaseLogInToAccessJournal);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      if (_editingDocId != null) {
        await _col.doc(_editingDocId!).update({
          'note': text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _snack(AppLocalizations.of(context)!.journalEntryUpdatedSuccessfully);
      } else {
        await _col.add({
          'userId': uid,
          'note': text,
          if (_activePrompt != null) 'prompt': _activePrompt,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _snack(AppLocalizations.of(context)!.journalEntryAddedSuccessfully);

        // Award points for journaling
        try {
          final gam = context.read<GamificationProvider>();
          await gam.onJournalWritten();
          final badges = context.read<BadgeProvider>();
          await badges.checkTierProgress(
            journalCount: gam.lifetimeJournals,
            streakDays: gam.longestStreak,
            breathingCount: gam.lifetimeBreathingSessions,
            careLogCount: gam.lifetimeCareLogs,
            challengeCount: gam.lifetimeChallengesCompleted,
            totalPoints: gam.totalPoints,
            moodDays: gam.lifetimeCheckins,
          );
        } catch (e) {
          debugPrint('Journal: error awarding points: $e');
        }
      }
      _ctrl.clear();
      setState(() {
        _editingDocId = null;
        _activePrompt = null;
      });
    } catch (e) {
      debugPrint('CareGiverJournalScreen._save error: $e');
      _snack(AppLocalizations.of(context)!.genericError(e.toString()));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _delete(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry'),
        content: const Text(
            'This entry will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _col.doc(docId).delete();
      if (mounted) {
        _snack(AppLocalizations.of(context)!.journalEntryDeletedSuccessfully);
        if (_editingDocId == docId) {
          setState(() {
            _editingDocId = null;
            _ctrl.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _snack(AppLocalizations.of(context)!.failedToDeleteJournalEntry);
      }
    }
  }

  void _startEdit(String docId, String note) {
    setState(() {
      _editingDocId = docId;
      _activePrompt = null;
      _ctrl.text = note;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingDocId = null;
      _activePrompt = null;
      _ctrl.clear();
    });
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final uid = _currentUserId;
    final theme = Theme.of(context);

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.caregiverJournal)),
        body: Center(child: Text(loc.pleaseLogInToAccessJournal)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.caregiverJournal),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Gratitude prompt card ─────────────────────────────────────
          _GratitudePromptCard(
            prompt: GratitudePrompts.todayPrompt,
            isActive: _activePrompt != null,
            onUsePrompt: () => _usePrompt(GratitudePrompts.todayPrompt),
            onSeeAll: _showAllPrompts,
            onClear: _clearPrompt,
          ),

          // ── Entry composer ────────────────────────────────────────────
          _ComposerCard(
            ctrl: _ctrl,
            isEditing: _editingDocId != null,
            isSubmitting: _isSubmitting,
            activePrompt: _activePrompt,
            onSave: _save,
            onCancel: _editingDocId != null ? _cancelEdit : _clearPrompt,
            color: _kJournalColor,
            loc: loc,
          ),

          // ── Journal entries list ──────────────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: _col
                .where('userId', isEqualTo: uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    loc.genericError(snapshot.error.toString()),
                    style: const TextStyle(color: AppTheme.dangerColor),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 52,
                          color: _kJournalColor.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        loc.noJournalEntriesYet,
                        style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final note = data['note'] as String? ?? '';
                  final prompt = data['prompt'] as String?;
                  final ts = data['createdAt'] as Timestamp?;
                  final date = ts != null
                      ? DateFormat.yMMMd(loc.localeName)
                          .add_jm()
                          .format(ts.toDate())
                      : '';
                  final isBeingEdited = _editingDocId == doc.id;

                  return _JournalCard(
                    docId: doc.id,
                    note: note,
                    prompt: prompt,
                    date: date,
                    isBeingEdited: isBeingEdited,
                    color: _kJournalColor,
                    theme: theme,
                    onEdit: () => _startEdit(doc.id, note),
                    onDelete: () => _delete(doc.id),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Gratitude prompt card — shown at the top of the journal
// ---------------------------------------------------------------------------

class _GratitudePromptCard extends StatelessWidget {
  const _GratitudePromptCard({
    required this.prompt,
    required this.isActive,
    required this.onUsePrompt,
    required this.onSeeAll,
    required this.onClear,
  });

  final String prompt;
  final bool isActive;
  final VoidCallback onUsePrompt;
  final VoidCallback onSeeAll;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kPromptColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? _kPromptColor : _kPromptColor.withValues(alpha: 0.2),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kPromptColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_outline,
                    color: _kPromptColor, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                "TODAY'S GRATITUDE PROMPT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: _kPromptColor,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'More prompts',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kPromptColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Prompt text
          Text(
            prompt,
            style: TextStyle(
              fontSize: 14,
              color: _kPromptColor.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Action button
          if (!isActive)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onUsePrompt,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Use this prompt',
                    style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: _kPromptColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                        color: _kPromptColor.withValues(alpha: 0.3)),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle,
                      size: 14, color: _kPromptColor),
                  const SizedBox(width: 4),
                  Text(
                    'Writing with this prompt',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _kPromptColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.close,
                        size: 14,
                        color: _kPromptColor.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// All prompts sheet — scrollable list of all 50+ prompts
// ---------------------------------------------------------------------------

class _AllPromptsSheet extends StatelessWidget {
  const _AllPromptsSheet({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final prompts = GratitudePrompts.all;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: _kPromptColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Choose a prompt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPromptColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${prompts.length} prompts',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: prompts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final isToday = prompts[i] == GratitudePrompts.todayPrompt;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday
                          ? _kPromptColor.withValues(alpha: 0.12)
                          : AppTheme.backgroundGray,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? _kPromptColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    prompts[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontWeight:
                          isToday ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isToday
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _kPromptColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _kPromptColor,
                            ),
                          ),
                        )
                      : null,
                  onTap: () => onSelect(prompts[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Composer card — text field + save/cancel buttons + active prompt indicator
// ---------------------------------------------------------------------------

class _ComposerCard extends StatefulWidget {
  const _ComposerCard({
    required this.ctrl,
    required this.isEditing,
    required this.isSubmitting,
    required this.activePrompt,
    required this.onSave,
    required this.onCancel,
    required this.color,
    required this.loc,
  });

  final TextEditingController ctrl;
  final bool isEditing;
  final bool isSubmitting;
  final String? activePrompt;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final Color color;
  final AppLocalizations loc;

  @override
  State<_ComposerCard> createState() => _ComposerCardState();
}

class _ComposerCardState extends State<_ComposerCard> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.ctrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charCount = widget.ctrl.text.length;
    final color = widget.color;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isEditing
                    ? Icons.edit_outlined
                    : Icons.create_outlined,
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isEditing
                  ? widget.loc.editJournalEntry
                  : widget.loc.addJournalEntry,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: color,
              ),
            ),
            // Points hint for new entries
            if (!widget.isEditing) ...[
              const Spacer(),
              Text(
                '+15 pts',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color.withValues(alpha: 0.5),
                ),
              ),
            ],
          ]),

          // Active prompt indicator
          if (widget.activePrompt != null && !widget.isEditing) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _kPromptColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline,
                      size: 13, color: _kPromptColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.activePrompt!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _kPromptColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Text field
          TextField(
            controller: widget.ctrl,
            maxLines: 5,
            maxLength: _kMaxChars,
            autofocus: widget.activePrompt != null,
            decoration: InputDecoration(
              hintText: widget.activePrompt != null
                  ? 'Write your response...'
                  : widget.loc.writeYourEntryHere,
              filled: true,
              fillColor: color.withValues(alpha: 0.04),
              counterText: '$charCount / $_kMaxChars',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color.withValues(alpha: 0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color.withValues(alpha: 0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.isEditing || widget.activePrompt != null)
                TextButton(
                  onPressed:
                      widget.isSubmitting ? null : widget.onCancel,
                  child: Text(widget.isEditing
                      ? widget.loc.cancelEdit
                      : 'Clear prompt'),
                ),
              if (widget.isEditing || widget.activePrompt != null)
                const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: widget.isSubmitting ? null : widget.onSave,
                icon: widget.isSubmitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(
                        widget.isEditing
                            ? Icons.check_outlined
                            : Icons.add_outlined,
                        size: 16),
                label: Text(widget.isEditing
                    ? widget.loc.updateEntry
                    : widget.loc.addEntry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Journal entry card — left accent strip, prompt badge, edit/delete actions
// ---------------------------------------------------------------------------

class _JournalCard extends StatelessWidget {
  const _JournalCard({
    required this.docId,
    required this.note,
    required this.date,
    required this.isBeingEdited,
    required this.color,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
    this.prompt,
  });

  final String docId;
  final String note;
  final String? prompt;
  final String date;
  final bool isBeingEdited;
  final Color color;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isBeingEdited
            ? color.withValues(alpha: 0.06)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBeingEdited
              ? color
              : color.withValues(alpha: 0.2),
          width: isBeingEdited ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date + editing badge
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 11, color: color.withValues(alpha: 0.7)),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: color.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isBeingEdited) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Editing',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: color,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Prompt badge — shown on entries that used a gratitude prompt
                      if (prompt != null && prompt!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _kPromptColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  size: 12, color: _kPromptColor),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  prompt!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: _kPromptColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Note body
                      Text(
                        note,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: onEdit,
                            icon: Icon(Icons.edit_outlined,
                                size: 14, color: color),
                            label: Text('Edit',
                                style: TextStyle(
                                    fontSize: 12, color: color)),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 4),
                          TextButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline,
                                size: 14,
                                color: AppTheme.dangerColor),
                            label: const Text('Delete',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.dangerColor)),
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
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
}
