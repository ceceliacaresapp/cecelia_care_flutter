// lib/services/weather_service.dart
//
// Lightweight wrapper around the free Open-Meteo API.
// Handles geocoding (city/state -> lat/lon) and weather fetching with
// SharedPreferences-based caching. Zero API keys needed.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherData {
  final double temperature;
  final int weatherCode;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.fetchedAt,
  });

  String get emoji {
    if (weatherCode == 0) return '\u2600\uFE0F'; // ☀️
    if (weatherCode <= 2) return '\u26C5'; // ⛅
    if (weatherCode == 3) return '\u2601\uFE0F'; // ☁️
    if (weatherCode <= 48) return '\uD83C\uDF2B\uFE0F'; // 🌫️
    if (weatherCode <= 57) return '\uD83C\uDF26\uFE0F'; // 🌦️
    if (weatherCode <= 67) return '\uD83C\uDF27\uFE0F'; // 🌧️
    if (weatherCode <= 77) return '\u2744\uFE0F'; // ❄️
    if (weatherCode <= 82) return '\uD83C\uDF26\uFE0F'; // 🌦️
    if (weatherCode <= 86) return '\uD83C\uDF28\uFE0F'; // 🌨️
    return '\u26C8\uFE0F'; // ⛈️
  }

  String get label {
    if (weatherCode == 0) return 'Clear sky';
    if (weatherCode == 1) return 'Mostly clear';
    if (weatherCode == 2) return 'Partly cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode <= 48) return 'Fog';
    if (weatherCode <= 55) return 'Drizzle';
    if (weatherCode <= 57) return 'Freezing drizzle';
    if (weatherCode <= 65) return 'Rain';
    if (weatherCode <= 67) return 'Freezing rain';
    if (weatherCode <= 77) return 'Snow';
    if (weatherCode <= 82) return 'Rain showers';
    if (weatherCode <= 86) return 'Snow showers';
    return 'Thunderstorm';
  }

  Map<String, dynamic> toJson() => {
        'temperature': temperature,
        'weatherCode': weatherCode,
        'fetchedAt': fetchedAt.millisecondsSinceEpoch,
      };

  factory WeatherData.fromJson(Map<String, dynamic> json) => WeatherData(
        temperature: (json['temperature'] as num).toDouble(),
        weatherCode: json['weatherCode'] as int,
        fetchedAt:
            DateTime.fromMillisecondsSinceEpoch(json['fetchedAt'] as int),
      );
}

class WeatherService {
  WeatherService._();
  static final WeatherService instance = WeatherService._();

  static const String _latKey = 'weather_lat';
  static const String _lonKey = 'weather_lon';
  static const String _cityKey = 'weather_city';
  static const String _stateKey = 'weather_state';
  static const String _cacheKey = 'weather_cache';
  static const Duration _cacheDuration = Duration(minutes: 30);

  WeatherData? _memoryCache;

  bool get hasLocation =>
      _latCached != null && _lonCached != null;

  String get locationLabel {
    if (_cityCached == null) return '';
    return _stateCached != null && _stateCached!.isNotEmpty
        ? '$_cityCached, $_stateCached'
        : _cityCached!;
  }

  double? _latCached;
  double? _lonCached;
  String? _cityCached;
  String? _stateCached;

  Future<void> _loadLocationFromPrefs() async {
    final sp = await SharedPreferences.getInstance();
    _latCached = sp.getDouble(_latKey);
    _lonCached = sp.getDouble(_lonKey);
    _cityCached = sp.getString(_cityKey);
    _stateCached = sp.getString(_stateKey);
  }

  Future<bool> setLocation(String city, String state) async {
    if (city.trim().isEmpty) return false;
    try {
      final query = state.trim().isNotEmpty
          ? '${city.trim()}+${state.trim()}'
          : city.trim();
      final uri = Uri.parse(
          'https://geocoding-api.open-meteo.com/v1/search?name=$query&count=1');
      final response = await http.get(uri);
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return false;

      final result = results[0] as Map<String, dynamic>;
      final lat = (result['latitude'] as num).toDouble();
      final lon = (result['longitude'] as num).toDouble();
      final resolvedName = result['name'] as String? ?? city.trim();

      final sp = await SharedPreferences.getInstance();
      await sp.setDouble(_latKey, lat);
      await sp.setDouble(_lonKey, lon);
      await sp.setString(_cityKey, resolvedName);
      await sp.setString(_stateKey, state.trim());

      _latCached = lat;
      _lonCached = lon;
      _cityCached = resolvedName;
      _stateCached = state.trim();

      // Clear weather cache so next fetch gets fresh data for new location.
      _memoryCache = null;
      await sp.remove(_cacheKey);

      debugPrint('WeatherService: Location set to $resolvedName '
          '($lat, $lon)');
      return true;
    } catch (e) {
      debugPrint('WeatherService.setLocation error: $e');
      return false;
    }
  }

  Future<void> clearLocation() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_latKey);
    await sp.remove(_lonKey);
    await sp.remove(_cityKey);
    await sp.remove(_stateKey);
    await sp.remove(_cacheKey);
    _latCached = null;
    _lonCached = null;
    _cityCached = null;
    _stateCached = null;
    _memoryCache = null;
  }

  Future<WeatherData?> getWeather() async {
    // Ensure location coords are loaded.
    if (_latCached == null || _lonCached == null) {
      await _loadLocationFromPrefs();
    }
    if (_latCached == null || _lonCached == null) return null;

    // Check memory cache.
    if (_memoryCache != null &&
        DateTime.now().difference(_memoryCache!.fetchedAt) < _cacheDuration) {
      return _memoryCache;
    }

    // Check disk cache.
    try {
      final sp = await SharedPreferences.getInstance();
      final cacheStr = sp.getString(_cacheKey);
      if (cacheStr != null) {
        final cached = WeatherData.fromJson(
            jsonDecode(cacheStr) as Map<String, dynamic>);
        if (DateTime.now().difference(cached.fetchedAt) < _cacheDuration) {
          _memoryCache = cached;
          return cached;
        }
      }
    } catch (_) {}

    // Fetch fresh weather.
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$_latCached&longitude=$_lonCached'
        '&current=temperature_2m,weather_code'
        '&temperature_unit=fahrenheit&timezone=auto',
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return _memoryCache;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final current = data['current'] as Map<String, dynamic>;

      final weather = WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        weatherCode: current['weather_code'] as int,
        fetchedAt: DateTime.now(),
      );

      // Cache to disk + memory.
      _memoryCache = weather;
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_cacheKey, jsonEncode(weather.toJson()));

      return weather;
    } catch (e) {
      debugPrint('WeatherService.getWeather error: $e');
      return _memoryCache; // Stale > none.
    }
  }
}
