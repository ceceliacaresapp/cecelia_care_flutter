// lib/screens/communication_cards_screen.dart
//
// Large picture+text+ASL communication cards for non-verbal care recipients.
// Two modes: Card Mode (for the care recipient) and ASL Guide (for the
// caregiver to learn signs).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/models/communication_card.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class CommunicationCardsScreen extends StatefulWidget {
  const CommunicationCardsScreen({super.key});

  @override
  State<CommunicationCardsScreen> createState() =>
      _CommunicationCardsScreenState();
}

class _CommunicationCardsScreenState extends State<CommunicationCardsScreen> {
  bool _aslMode = false;
  String _selectedCategory = 'all';
  String? _tappedCardId;
  Set<String> _learnedSigns = {};

  @override
  void initState() {
    super.initState();
    _loadLearnedSigns();
  }

  Future<void> _loadLearnedSigns() async {
    final sp = await SharedPreferences.getInstance();
    final learned = sp.getStringList('asl_learned_signs') ?? [];
    setState(() => _learnedSigns = learned.toSet());
  }

  Future<void> _markLearned(String cardId) async {
    _learnedSigns.add(cardId);
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList('asl_learned_signs', _learnedSigns.toList());
    setState(() {});
  }

  List<CommunicationCard> get _filteredCards {
    if (_selectedCategory == 'all') return CommunicationCard.all;
    return CommunicationCard.all
        .where((c) => c.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_aslMode ? 'ASL Sign Guide' : 'Communication Cards'),
        actions: [
          IconButton(
            icon: Icon(_aslMode ? Icons.grid_view : Icons.sign_language),
            tooltip: _aslMode ? 'Card Mode' : 'ASL Guide',
            onPressed: () => setState(() => _aslMode = !_aslMode),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── ASL progress bar ──────────────────────────────────
          if (_aslMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: CommunicationCard.all.isEmpty
                            ? 0
                            : _learnedSigns.length /
                                CommunicationCard.all.length,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF43A047)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_learnedSigns.length}/${CommunicationCard.all.length} signs learned',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

          // ── Category tabs ─────────────────────────────────────
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _categoryChip('all', 'All', Icons.apps, AppTheme.textSecondary),
                ...CommunicationCard.categories.entries.map((e) =>
                    _categoryChip(e.key, e.value.label, e.value.icon,
                        e.value.color)),
              ],
            ),
          ),

          // ── Cards ─────────────────────────────────────────────
          Expanded(
            child: _aslMode ? _buildAslGuide() : _buildCardGrid(),
          ),
        ],
      ),
    );
  }

  // ── Category chip ───────────────────────────────────────────────

  Widget _categoryChip(
      String key, String label, IconData icon, Color color) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12,
                color: isSelected ? Colors.white : null)),
          ],
        ),
        selectedColor: color,
        backgroundColor: Colors.grey.shade100,
        onSelected: (_) => setState(() => _selectedCategory = key),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  // ── Card Mode (2-column grid for care recipients) ───────────────

  Widget _buildCardGrid() {
    final cards = _filteredCards;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildTapCard(cards[i]),
    );
  }

  Widget _buildTapCard(CommunicationCard card) {
    final isTapped = _tappedCardId == card.id;
    return GestureDetector(
      onTap: () {
        HapticUtils.success();
        setState(() => _tappedCardId = card.id);
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted && _tappedCardId == card.id) {
            setState(() => _tappedCardId = null);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: isTapped
            ? (Matrix4.identity()..scale(1.05))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: card.color.withValues(alpha: isTapped ? 0.25 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: card.color.withValues(alpha: isTapped ? 0.6 : 0.2),
            width: isTapped ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(card.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 8),
            Text(card.label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: card.color,
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── ASL Guide Mode (single-column list) ─────────────────────────

  Widget _buildAslGuide() {
    final cards = _filteredCards;
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cards.length,
      itemBuilder: (_, i) => _buildAslCard(cards[i]),
    );
  }

  Widget _buildAslCard(CommunicationCard card) {
    final isLearned = _learnedSigns.contains(card.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (!isLearned) _markLearned(card.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(card.emoji,
                    style: const TextStyle(fontSize: 28)),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(card.label,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                        if (!isLearned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E88E5)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('New',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF1E88E5),
                                    fontWeight: FontWeight.w600)),
                          ),
                        if (isLearned)
                          const Icon(Icons.check_circle,
                              size: 16, color: Color(0xFF43A047)),
                      ],
                    ),
                    Text('"${card.speakText}"',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            fontStyle: FontStyle.italic)),
                    const SizedBox(height: 6),
                    Text(card.aslDescription,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(card.aslHandShape,
                          style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
