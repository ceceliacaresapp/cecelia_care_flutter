// lib/widgets/orientation_board_card.dart
//
// Large, high-contrast, warm-toned card designed to be shown to the care
// recipient on a tablet. Shows today's date, weather, who's on duty, and
// upcoming events.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/calendar_event.dart';
import 'package:cecelia_care_flutter/models/shift_definition.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/widgets/cached_avatar.dart';
import 'package:cecelia_care_flutter/services/weather_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class OrientationBoardCard extends StatefulWidget {
  const OrientationBoardCard({super.key});

  @override
  State<OrientationBoardCard> createState() => _OrientationBoardCardState();
}

class _OrientationBoardCardState extends State<OrientationBoardCard> {
  final WeatherService _weather = WeatherService.instance;
  final FirestoreService _firestore = FirestoreService();
  WeatherData? _weatherData;
  bool _loadingWeather = false;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    setState(() => _loadingWeather = true);
    final data = await _weather.getWeather();
    if (mounted) setState(() { _weatherData = data; _loadingWeather = false; });
  }

  // ── Time-of-day gradient ────────────────────────────────────────

  List<Color> get _backgroundGradient {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return [const Color(0xFFFFF8E1), const Color(0xFFFFE0B2)]; // Morning
    } else if (hour >= 12 && hour < 17) {
      return [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)]; // Afternoon
    } else if (hour >= 17 && hour < 21) {
      return [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)]; // Evening
    } else {
      return [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)]; // Night
    }
  }

  // ── Seasonal emoji ──────────────────────────────────────────────

  String get _seasonalEmoji {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return '\uD83C\uDF37'; // 🌷
    if (month >= 6 && month <= 8) return '\uD83C\uDF3B'; // 🌻
    if (month >= 9 && month <= 11) return '\uD83C\uDF42'; // 🍂
    return '\u2744\uFE0F'; // ❄️
  }

  // ── Location setup dialog ───────────────────────────────────────

  Future<void> _showLocationDialog() async {
    final cityCtl = TextEditingController();
    final stateCtl = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Set your location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('For weather on the Orientation Board',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: cityCtl,
              decoration: const InputDecoration(
                labelText: 'City',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stateCtl,
              decoration: const InputDecoration(
                labelText: 'State / Region (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _LocationSaveButton(
              weather: _weather,
              cityCtl: cityCtl,
              stateCtl: stateCtl,
            ),
          ],
        ),
      ),
    );

    if (saved == true) _fetchWeather();
  }

  // ── Build ───────────────────────────────────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now);
    final fullDate = DateFormat('MMMM d, yyyy').format(now);
    final elderProvider = context.watch<ActiveElderProvider>();
    final isMultiView = elderProvider.isMultiView;
    final elderId = elderProvider.activeElder?.id ?? '';
    final elderName = isMultiView
        ? '${elderProvider.allElders.length} recipients'
        : elderProvider.activeElder?.preferredName?.isNotEmpty == true
            ? elderProvider.activeElder!.preferredName!
            : elderProvider.activeElder?.profileName ?? '';
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    final userName = userProfile?.displayName ?? 'Caregiver';
    final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : 'C';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _backgroundGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting row (absorbed from _GreetingCard) ─────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_greeting()}, $userName',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.entryExpenseAccent,
                          )),
                      if (elderName.isNotEmpty)
                        Text('Caring for $elderName today',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5D4037),
                            )),
                    ],
                  ),
                ),
                CachedAvatar(
                  imageUrl: userProfile?.avatarUrl,
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  fallbackChild: Text(userInitial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5D4037),
                      )),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Date row ──────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dayOfWeek,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.entryExpenseAccent,
                          )),
                      Text(fullDate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF5D4037),
                          )),
                    ],
                  ),
                ),
                Text(_seasonalEmoji, style: const TextStyle(fontSize: 36)),
              ],
            ),

            const SizedBox(height: 16),

            // ── Weather ───────────────────────────────────────
            _buildWeatherRow(),

            const SizedBox(height: 14),

            // ── Who's on duty ─────────────────────────────────
            if (!isMultiView && elderId.isNotEmpty)
              _buildShiftRow(elderId),

            // ── Upcoming events ───────────────────────────────
            if (!isMultiView && elderId.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildEventsRow(elderId),
            ],
            // In multi-view, show a summary count instead
            if (isMultiView)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Viewing all ${elderProvider.allElders.length} care recipients',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF8D6E63)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Weather row ─────────────────────────────────────────────────

  Widget _buildWeatherRow() {
    if (_loadingWeather) {
      return const Row(children: [
        const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Text('Loading weather...', style: TextStyle(color: Color(0xFF5D4037))),
      ]);
    }

    if (!_weather.hasLocation || _weatherData == null) {
      return GestureDetector(
        onTap: _showLocationDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF5D4037)),
              const SizedBox(width: 6),
              Text('Tap to add your location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5D4037),
                    fontWeight: FontWeight.w500,
                  )),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        Text(_weatherData!.emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(width: 10),
        Text('${_weatherData!.temperature.round()}\u00B0F',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.entryExpenseAccent,
            )),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_weatherData!.label,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF5D4037))),
              GestureDetector(
                onTap: _showLocationDialog,
                child: Text(_weather.locationLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8D6E63),
                      decoration: TextDecoration.underline,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Shift row ───────────────────────────────────────────────────

  Widget _buildShiftRow(String elderId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestore.getShiftDefinitionsStream(elderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final shifts = snapshot.data!
            .map((raw) =>
                ShiftDefinition.fromFirestore(raw['id'] as String, raw))
            .toList();
        final todayKey = ShiftDefinition.todayKey();

        final activeShift = shifts.where((s) => s.isCurrentShift).firstOrNull;
        if (activeShift == null) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text('No shift right now',
                style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63))),
          );
        }

        final caregiverName = activeShift.assignedNameForDay(todayKey);
        final displayText = caregiverName.isNotEmpty
            ? '$caregiverName is here (${activeShift.name} shift)'
            : '${activeShift.name} shift (unassigned)';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: activeShift.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(displayText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.entryExpenseAccent,
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Events row ──────────────────────────────────────────────────

  Widget _buildEventsRow(String elderId) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final endOfTomorrow = DateTime(
        tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);

    return StreamBuilder<List<CalendarEvent>>(
      stream: _firestore.getCalendarEventsStream(elderId, now, endOfTomorrow),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No upcoming events',
              style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63)));
        }

        // Filter to future events and take next 3.
        final upcoming = snapshot.data!
            .where((e) => e.startDateTime.toDate().isAfter(now))
            .take(3)
            .toList();

        if (upcoming.isEmpty) {
          return const Text('No more events today',
              style: TextStyle(fontSize: 14, color: Color(0xFF8D6E63)));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: upcoming.map((event) {
            final eventDate = event.startDateTime.toDate();
            final isToday = eventDate.day == now.day &&
                eventDate.month == now.month;
            final timeLabel = isToday
                ? DateFormat('h:mm a').format(eventDate)
                : 'Tomorrow';

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.schedule,
                      size: 16, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(timeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.entryExpenseAccent,
                      )),
                  const SizedBox(width: 6),
                  const Text('\u2014',
                      style: TextStyle(color: Color(0xFF8D6E63))),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(event.title,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF5D4037)),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Extracted as a StatefulWidget so `saving` and `error` survive rebuilds.
class _LocationSaveButton extends StatefulWidget {
  const _LocationSaveButton({
    required this.weather,
    required this.cityCtl,
    required this.stateCtl,
  });
  final WeatherService weather;
  final TextEditingController cityCtl;
  final TextEditingController stateCtl;

  @override
  State<_LocationSaveButton> createState() => _LocationSaveButtonState();
}

class _LocationSaveButtonState extends State<_LocationSaveButton> {
  bool _saving = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ElevatedButton(
          onPressed: _saving
              ? null
              : () async {
                  if (widget.cityCtl.text.trim().isEmpty) return;
                  setState(() { _saving = true; _error = null; });
                  final success = await widget.weather.setLocation(
                      widget.cityCtl.text, widget.stateCtl.text);
                  if (!mounted) return;
                  if (success) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {
                      _saving = false;
                      _error = 'Location not found. Try a different city name.';
                    });
                  }
                },
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
