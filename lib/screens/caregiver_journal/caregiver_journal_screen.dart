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
//     createdAt   : Timestamp
//     updatedAt   : Timestamp

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// Purple — matches the Self Care tab that hosts this screen.
const _kJournalColor = Color(0xFF8E24AA);
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

  static final _col =
      FirebaseFirestore.instance.collection('caregiverJournalEntries');

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _snack(AppLocalizations.of(context)!.journalEntryAddedSuccessfully);
      }
      _ctrl.clear();
      setState(() => _editingDocId = null);
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
      _ctrl.text = note;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingDocId = null;
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
      appBar: AppBar(title: Text(loc.caregiverJournal)),
      body: Column(
        children: [
          // ── Entry composer ────────────────────────────────────────────────
          _ComposerCard(
            ctrl: _ctrl,
            isEditing: _editingDocId != null,
            isSubmitting: _isSubmitting,
            onSave: _save,
            onCancel: _cancelEdit,
            color: _kJournalColor,
            loc: loc,
          ),

          // ── Journal entries list ──────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _col
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        loc.genericError(snapshot.error.toString()),
                        style:
                            const TextStyle(color: AppTheme.dangerColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book_outlined,
                              size: 52,
                              color: _kJournalColor.withOpacity(0.4)),
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
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final note = data['note'] as String? ?? '';
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
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Composer card — text field + save/cancel buttons
// ---------------------------------------------------------------------------

class _ComposerCard extends StatefulWidget {
  const _ComposerCard({
    required this.ctrl,
    required this.isEditing,
    required this.isSubmitting,
    required this.onSave,
    required this.onCancel,
    required this.color,
    required this.loc,
  });

  final TextEditingController ctrl;
  final bool isEditing;
  final bool isSubmitting;
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
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
                color: color.withOpacity(0.12),
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
          ]),

          const SizedBox(height: 12),

          // Text field
          TextField(
            controller: widget.ctrl,
            maxLines: 5,
            maxLength: _kMaxChars,
            decoration: InputDecoration(
              hintText: widget.loc.writeYourEntryHere,
              filled: true,
              fillColor: color.withOpacity(0.04),
              counterText: '$charCount / $_kMaxChars',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color.withOpacity(0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color.withOpacity(0.25)),
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
              if (widget.isEditing)
                TextButton(
                  onPressed:
                      widget.isSubmitting ? null : widget.onCancel,
                  child: Text(widget.loc.cancelEdit),
                ),
              if (widget.isEditing) const SizedBox(width: 8),
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
// Journal entry card — left accent strip, edit/delete actions
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
  });

  final String docId;
  final String note;
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
            ? color.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBeingEdited
              ? color
              : color.withOpacity(0.2),
          width: isBeingEdited ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
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
                      // Date
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 11, color: color.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 11,
                              color: color.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isBeingEdited) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
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
