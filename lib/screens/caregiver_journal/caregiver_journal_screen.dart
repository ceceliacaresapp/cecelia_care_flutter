// lib/screens/caregiver_journal/caregiver_journal_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/section.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

class CareGiverJournalScreen extends StatefulWidget {
  const CareGiverJournalScreen({super.key});

  @override
  State<CareGiverJournalScreen> createState() => _CareGiverJournalScreenState();
}

class _CareGiverJournalScreenState extends State<CareGiverJournalScreen> {
  final TextEditingController _journalEntryController = TextEditingController();
  final int _maxCharacters = 300;
  String? _editingEntryId;
  bool _isSubmitting = false; // To show a loading indicator

  @override
  void dispose() {
    _journalEntryController.dispose();
    super.dispose();
  }

  Future<void> _addOrUpdateEntry() async {
    final loc = AppLocalizations.of(context)!;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final currentUserId = AuthService.currentUser?.uid;

    if (currentUserId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.pleaseLogInToAccessJournal)),
      );
      return;
    }

    if (_journalEntryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.journalEntryCannotBeEmpty)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final data = {'note': _journalEntryController.text.trim()};

      if (_editingEntryId != null) {
        await firestoreService.updateJournalEntry(
          entryId: _editingEntryId!,
          elderId: null,
          type: EntryType.caregiverJournal,
          data: data,
          creatorId: currentUserId,
          timestamp: DateTime.now(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.journalEntryUpdatedSuccessfully)),
          );
        }
      } else {
        await firestoreService.addJournalEntry(
          elderId: null,
          creatorId: currentUserId,
          type: EntryType.caregiverJournal,
          data: data,
          timestamp: DateTime.now(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.journalEntryAddedSuccessfully)),
          );
        }
      }

      _journalEntryController.clear();
      _editingEntryId = null;
    } catch (e) {
      if (mounted) {
        // --- I18N UPDATE ---
        // Using a more descriptive localization key for the error.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.genericError(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _editEntry(JournalEntry entry) {
    setState(() {
      _editingEntryId = entry.id;
      // Using an empty string is fine here as it's data, not a UI label.
      _journalEntryController.text = entry.data?['note'] ?? '';
    });
  }

  void _deleteEntry(String entryId) async {
    final loc = AppLocalizations.of(context)!;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    try {
      await firestoreService.deleteJournalEntry(entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.journalEntryDeletedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.failedToDeleteJournalEntry)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final currentUserId = AuthService.currentUser?.uid;
    final loc = AppLocalizations.of(context)!;

    if (currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.caregiverJournal)),
        body: Center(child: Text(loc.pleaseLogInToAccessJournal)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.caregiverJournal),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingM),
        child: Column(
          children: [
            Section(
              title: _editingEntryId != null
                  ? loc.editJournalEntry
                  : loc.addJournalEntry,
              child: Column(
                children: [
                  TextField(
                    controller: _journalEntryController,
                    maxLines: 4,
                    maxLength: _maxCharacters,
                    decoration: InputDecoration(
                      hintText: loc.writeYourEntryHere,
                      border: const OutlineInputBorder(),
                      // --- I18N UPDATE ---
                      // Replaced a hardcoded format string with a localization key
                      // to allow for different formatting in other languages.
                      counterText: loc.characterCount(
                          _journalEntryController.text.length, _maxCharacters),
                    ),
                    onChanged: (text) => setState(() {}),
                  ),
                  const SizedBox(height: AppStyles.spacingS),
                  if (_isSubmitting)
                    const CircularProgressIndicator()
                  else
                    Btn(
                      title: _editingEntryId != null
                          ? loc.updateEntry
                          : loc.addEntry,
                      onPressed: _addOrUpdateEntry,
                      variant: BtnVariant.primary,
                    ),
                  if (_editingEntryId != null && !_isSubmitting)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Btn(
                        title: loc.cancelEdit,
                        onPressed: () {
                          setState(() {
                            _editingEntryId = null;
                            _journalEntryController.clear();
                          });
                        },
                        variant: BtnVariant.secondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
            Expanded(
              child: StreamBuilder<List<JournalEntry>>(
                stream: firestoreService.getJournalEntriesStream(
                  currentUserId: currentUserId,
                  elderId: null,
                  type: EntryType.caregiverJournal,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    // --- I18N UPDATE ---
                    // Using a parameterized localization key for the error message.
                    return Center(
                        child: Text(loc.genericError(snapshot.error.toString())));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text(loc.noJournalEntriesYet));
                  }

                  final entries = snapshot.data!;
                  entries
                      .sort((a, b) => b.entryTimestamp.compareTo(a.entryTimestamp));

                  return ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      // Using DateFormat for better locale-aware date formatting.
                      final formattedDate = DateFormat.yMMMd(loc.localeName)
                          .format(entry.entryTimestamp.toDate());

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: AppStyles.spacingS),
                        child: Padding(
                          padding: const EdgeInsets.all(AppStyles.spacingM),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- I18N UPDATE ---
                              // Replaced a hardcoded format string with a localized one.
                              Text(
                                loc.dateLabel(formattedDate),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: AppStyles.spacingS),
                              Text(
                                entry.data?['note'] ?? loc.noContent,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => _editEntry(entry),
                                    child: Text(loc.edit),
                                  ),
                                  TextButton(
                                    onPressed: () => _deleteEntry(entry.id!),
                                    child: Text(loc.delete,
                                        style:
                                            const TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}