// lib/screens/medical_glossary_screen.dart
//
// Searchable, alphabetical medical glossary for caregivers. Static data —
// no Firestore, no network. Filter matches term name OR definition.

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/models/glossary_term.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class MedicalGlossaryScreen extends StatefulWidget {
  const MedicalGlossaryScreen({super.key});

  @override
  State<MedicalGlossaryScreen> createState() => _MedicalGlossaryScreenState();
}

class _MedicalGlossaryScreenState extends State<MedicalGlossaryScreen> {
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const Map<String, Color> _categoryColors = {
    'general': Color(0xFF607D8B),
    'vitals': AppTheme.tilePinkBright,
    'medications': AppTheme.dangerColor,
    'conditions': AppTheme.tileOrange,
    'procedures': AppTheme.tileBlue,
    'care': AppTheme.tileTeal,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<GlossaryTerm> get _filtered {
    final all = [...kGlossaryTerms]
      ..sort((a, b) =>
          a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((t) =>
            t.term.toLowerCase().contains(q) ||
            t.definition.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    // Group by first letter for section headers.
    final Map<String, List<GlossaryTerm>> grouped = {};
    for (final t in filtered) {
      final letter = t.term.substring(0, 1).toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(t);
    }
    final letters = grouped.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Glossary'),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search terms or definitions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                ),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _query.isEmpty
                    ? '${kGlossaryTerms.length} terms'
                    : '${filtered.length} ${filtered.length == 1 ? 'result' : 'results'}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                    itemCount: letters.length,
                    itemBuilder: (_, idx) {
                      final letter = letters[idx];
                      final terms = grouped[letter]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          ...terms.map(_termTile),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _termTile(GlossaryTerm t) {
    final color =
        _categoryColors[t.category] ?? AppTheme.textSecondary;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        side: BorderSide(color: AppTheme.textLight.withValues(alpha: 0.3)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Text(
            t.term,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.definition,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusS),
                ),
                child: Text(
                  t.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off,
                size: 56, color: AppTheme.textLight),
            const SizedBox(height: 12),
            Text(
              'No terms match "$_query"',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try a shorter search, or check your spelling.',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
