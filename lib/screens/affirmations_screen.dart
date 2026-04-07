// lib/screens/affirmations_screen.dart
//
// Swipeable caregiver-specific affirmations carousel.
//
// Features:
//   • PageView with snap-to-card physics
//   • Daily set of 5 affirmations (rotates each day)
//   • Heart icon to save/unsave favorites
//   • "View all favorites" toggle
//   • Gentle gradient background per card
//   • No backend — favorites stored in SharedPreferences
//
// Launched from the Relief Tools grid on the Self Care tab.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cecelia_care_flutter/utils/gratitude_prompts.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

const _kAccent = Color(0xFF00897B); // teal — matches the relief tile

// Card gradient pairs — gentle, calming
const _kCardGradients = [
  [Color(0xFFE8F5E9), Color(0xFFC8E6C9)], // green
  [Color(0xFFE3F2FD), Color(0xFFBBDEFB)], // blue
  [Color(0xFFF3E5F5), Color(0xFFE1BEE7)], // purple
  [Color(0xFFFFF3E0), Color(0xFFFFE0B2)], // amber
  [Color(0xFFE0F2F1), Color(0xFFB2DFDB)], // teal
];

// Matching dark text colors for each gradient
const _kCardTextColors = [
  Color(0xFF1B5E20), // green 900
  Color(0xFF0D47A1), // blue 900
  Color(0xFF4A148C), // purple 900
  Color(0xFFE65100), // orange 900
  Color(0xFF004D40), // teal 900
];

class AffirmationsScreen extends StatefulWidget {
  const AffirmationsScreen({super.key});

  @override
  State<AffirmationsScreen> createState() => _AffirmationsScreenState();
}

class _AffirmationsScreenState extends State<AffirmationsScreen> {
  late PageController _pageCtrl;
  int _currentPage = 0;
  bool _showFavorites = false;
  Set<int> _favoriteIndices = {};
  bool _loadedPrefs = false;

  // Today's daily set OR all favorites
  List<String> _displayList = [];
  List<int> _displayIndices = []; // global indices into CaregiverAffirmations.all

  static const String _prefsKey = 'affirmation_favorites';

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(viewportFraction: 0.88);
    _loadFavorites();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    _favoriteIndices = saved.map((s) => int.tryParse(s) ?? -1).where((i) => i >= 0).toSet();
    _buildDisplayList();
    setState(() => _loadedPrefs = true);
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _favoriteIndices.map((i) => i.toString()).toList());
  }

  void _toggleFavorite(int globalIndex) {
    setState(() {
      if (_favoriteIndices.contains(globalIndex)) {
        _favoriteIndices.remove(globalIndex);
      } else {
        _favoriteIndices.add(globalIndex);
        HapticFeedback.lightImpact();
      }
    });
    _saveFavorites();

    // If in favorites view and we just unfavorited, rebuild the list
    if (_showFavorites) {
      _buildDisplayList();
      // Reset page if current is out of bounds
      if (_currentPage >= _displayList.length) {
        _currentPage = _displayList.isEmpty ? 0 : _displayList.length - 1;
      }
    }
  }

  void _toggleView() {
    setState(() {
      _showFavorites = !_showFavorites;
      _currentPage = 0;
    });
    _buildDisplayList();
    if (_pageCtrl.hasClients) {
      _pageCtrl.jumpToPage(0);
    }
  }

  void _buildDisplayList() {
    final all = CaregiverAffirmations.all;
    if (_showFavorites) {
      final sortedFavs = _favoriteIndices.toList()..sort();
      _displayIndices = sortedFavs.where((i) => i < all.length).toList();
      _displayList = _displayIndices.map((i) => all[i]).toList();
    } else {
      // Daily set of 5
      final dailyTexts = CaregiverAffirmations.dailySet(count: 5);
      _displayList = dailyTexts;
      _displayIndices = dailyTexts.map((t) => all.indexOf(t)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loadedPrefs) {
      return Scaffold(
        appBar: AppBar(title: const Text('Affirmations')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Affirmations'),
        centerTitle: true,
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
        actions: [
          if (_favoriteIndices.isNotEmpty)
            IconButton(
              icon: Icon(
                _showFavorites
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: _showFavorites ? const Color(0xFFE91E63) : null,
              ),
              tooltip:
                  _showFavorites ? 'Show daily set' : 'Show favorites',
              onPressed: _toggleView,
            ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 24),

          // Header
          Text(
            _showFavorites ? 'Your saved affirmations' : "Today's affirmations",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kAccent,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _showFavorites
                ? '${_displayList.length} saved'
                : 'Swipe to read all 5 — new set each day',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 24),

          // Cards
          if (_displayList.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 48, color: _kAccent.withValues(alpha: 0.3)),
                    const SizedBox(height: 12),
                    const Text(
                      'No favorites saved yet.\nTap the heart on any affirmation to save it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _toggleView,
                      child: const Text("Show today's set"),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                itemCount: _displayList.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) {
                  final gradientIndex = i % _kCardGradients.length;
                  final globalIndex = _displayIndices[i];
                  final isFav = _favoriteIndices.contains(globalIndex);

                  return _AffirmationCard(
                    text: _displayList[i],
                    gradientColors: _kCardGradients[gradientIndex],
                    textColor: _kCardTextColors[gradientIndex],
                    isFavorite: isFav,
                    onToggleFavorite: () => _toggleFavorite(globalIndex),
                    cardNumber: i + 1,
                    totalCards: _displayList.length,
                  );
                },
              ),
            ),

          // Page dots
          if (_displayList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _displayList.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentPage ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage
                        ? _kAccent
                        : _kAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Affirmation card — large, calming, gradient background
// ---------------------------------------------------------------------------
class _AffirmationCard extends StatelessWidget {
  const _AffirmationCard({
    required this.text,
    required this.gradientColors,
    required this.textColor,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.cardNumber,
    required this.totalCards,
  });

  final String text;
  final List<Color> gradientColors;
  final Color textColor;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final int cardNumber;
  final int totalCards;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quote icon
            Icon(
              Icons.format_quote,
              size: 36,
              color: textColor.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 20),

            // Affirmation text
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),

            const Spacer(),

            // Bottom row: page indicator + favorite button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$cardNumber / $totalCards',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: onToggleFavorite,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      key: ValueKey(isFavorite),
                      size: 28,
                      color: isFavorite
                          ? const Color(0xFFE91E63)
                          : textColor.withValues(alpha: 0.3),
                    ),
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
