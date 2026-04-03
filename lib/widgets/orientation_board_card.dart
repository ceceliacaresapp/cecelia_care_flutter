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
import 'package:cecelia_care_flutter/services/firestore_service.dart';
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
            ElevatedButton(
              onPressed: () async {
                if (cityCtl.text.trim().isEmpty) return;
                final success = await _weather.setLocation(
                    cityCtl.text, stateCtl.text);
                if (ctx.mounted) Navigator.pop(ctx, success);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) _fetchWeather();
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayOfWeek = DateFormat('EEEE').format(now);
    final fullDate = DateFormat('MMMM d, yyyy').format(now);
    final elderProvider = context.watch<ActiveElderProvider>();
    final elderId = elderProvider.activeElder?.id ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
            // ── Row 1: Date ────────────────────────────────────
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
                            color: Color(0xFF4E342E),
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

            // ── Row 2: Weather ─────────────────────────────────
            _buildWeatherRow(),

            const SizedBox(height: 14),

            // ── Row 3: Who's on duty ───────────────────────────
            if (elderId.isNotEmpty) _buildShiftRow(elderId),

            // ── Row 4: Upcoming events ─────────────────────────
            if (elderId.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildEventsRow(elderId),
            ],
          ],
        ),
      ),
    );
  }

  // ── Weather row ─────────────────────────────────────────────────

  Widget _buildWeatherRow() {
    if (_loadingWeather) {
      return const Row(children: [
        SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        SizedBox(width: 8),
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
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF5D4037)),
              SizedBox(width: 6),
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
              color: Color(0xFF4E342E),
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
            borderRadius: BorderRadius.circular(10),
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
                      color: Color(0xFF4E342E),
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
                        color: Color(0xFF4E342E),
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
