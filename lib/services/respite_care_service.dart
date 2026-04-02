// lib/services/respite_care_service.dart
//
// Abstraction layer for respite care provider search. Queries multiple
// data sources and merges results:
//   1. Bundled static data (instant, always works offline)
//   2. CMS Socrata API — free, no API key required (hospice + home health)
//   3. Firestore user-submitted providers (crowdsource)
//
// Architecture is pluggable — adding Google Places or 211 NDP later
// requires only adding a new _searchX() method and merging results.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cecelia_care_flutter/models/respite_provider.dart';

class RespiteCareService {
  RespiteCareService._();
  static final instance = RespiteCareService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Main search orchestrator ────────────────────────────────────

  /// Searches all sources for respite providers near [zipCode].
  /// Returns merged, deduplicated results sorted by relevance.
  Future<List<RespiteProvider>> search(String zipCode) async {
    final zip = zipCode.trim();
    if (zip.length < 5) {
      return RespiteResourceDirectory.searchByZip(zip);
    }

    // Fire all searches in parallel
    final results = await Future.wait([
      Future.value(_searchBundled(zip)),
      _searchCmsHospice(zip),
      _searchCmsHomeHealth(zip),
      _searchUserSubmitted(zip),
    ]);

    final merged = <RespiteProvider>[];
    final seenNames = <String>{};

    // Add results in priority order, dedup by lowercase name
    for (final list in results) {
      for (final provider in list) {
        final key = provider.name.toLowerCase().trim();
        if (!seenNames.contains(key)) {
          seenNames.add(key);
          merged.add(provider);
        }
      }
    }

    return merged;
  }

  // ── Bundled static data ─────────────────────────────────────────

  List<RespiteProvider> _searchBundled(String zip) {
    return RespiteResourceDirectory.searchByZip(zip);
  }

  // ── CMS Socrata API — Hospice providers ─────────────────────────
  //
  // Dataset: Hospice - Provider Data (3xeb-u9wp)
  // Endpoint: https://data.cms.gov/provider-data/api/1/datastore/query/3xeb-u9wp/0
  // Cost: $0 — completely free, no API key required
  // Docs: https://data.cms.gov/provider-data/dataset/3xeb-u9wp

  Future<List<RespiteProvider>> _searchCmsHospice(String zip) async {
    try {
      final uri = Uri.parse(
        'https://data.cms.gov/provider-data/api/1/datastore/query/3xeb-u9wp/0',
      ).replace(queryParameters: {
        'conditions[0][property]': 'zip_code',
        'conditions[0][value]': zip,
        'conditions[0][operator]': '=',
        'limit': '25',
      });

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>? ?? [];

      return results.map<RespiteProvider>((item) {
        final m = item as Map<String, dynamic>;
        return RespiteProvider(
          id: 'cms_hospice_${m['ccn'] ?? m['cms_certification_number_ccn'] ?? ''}',
          name: _titleCase(m['facility_name'] ?? m['provider_name'] ?? 'Unknown Facility'),
          organizationName: null,
          description: 'Medicare-certified hospice provider offering inpatient respite care.',
          serviceTypes: const ['hospiceRespite', 'inpatientRespite'],
          address: _titleCase(m['address_line_1'] ?? m['address'] ?? ''),
          city: _titleCase(m['city'] ?? ''),
          state: (m['state'] ?? '').toString().toUpperCase(),
          zipCode: (m['zip_code'] ?? zip).toString(),
          phone: m['phone_number'] ?? m['phone'] ?? '',
          website: null,
          source: 'cms_api',
        );
      }).toList();
    } catch (e) {
      debugPrint('RespiteCareService._searchCmsHospice error: $e');
      return [];
    }
  }

  // ── CMS Socrata API — Home Health agencies ──────────────────────
  //
  // Dataset: Home Health Care - Provider Data (6jpm-sxkc)
  // These agencies often provide in-home respite workers.

  Future<List<RespiteProvider>> _searchCmsHomeHealth(String zip) async {
    try {
      final uri = Uri.parse(
        'https://data.cms.gov/provider-data/api/1/datastore/query/6jpm-sxkc/0',
      ).replace(queryParameters: {
        'conditions[0][property]': 'zip',
        'conditions[0][value]': zip,
        'conditions[0][operator]': '=',
        'limit': '25',
      });

      final response = await http.get(uri).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final results = data['results'] as List<dynamic>? ?? [];

      return results.map<RespiteProvider>((item) {
        final m = item as Map<String, dynamic>;
        return RespiteProvider(
          id: 'cms_hh_${m['ccn'] ?? m['cms_certification_number_ccn'] ?? ''}',
          name: _titleCase(m['provider_name'] ?? 'Unknown Agency'),
          organizationName: null,
          description: 'Medicare-certified home health agency. May offer in-home respite services.',
          serviceTypes: const ['inHomeRespite', 'skilledNursing'],
          address: _titleCase(m['address'] ?? ''),
          city: _titleCase(m['city'] ?? ''),
          state: (m['state'] ?? '').toString().toUpperCase(),
          zipCode: (m['zip'] ?? zip).toString(),
          phone: m['phone'] ?? '',
          website: null,
          source: 'cms_api',
        );
      }).toList();
    } catch (e) {
      debugPrint('RespiteCareService._searchCmsHomeHealth error: $e');
      return [];
    }
  }

  // ── Firestore user-submitted providers ──────────────────────────

  Future<List<RespiteProvider>> _searchUserSubmitted(String zip) async {
    try {
      final prefix = zip.length >= 3 ? zip.substring(0, 3) : zip;
      final snapshot = await _db
          .collection('respiteProviders')
          .where('zipPrefix', isEqualTo: prefix)
          .limit(25)
          .get();

      return snapshot.docs
          .map((doc) =>
              RespiteProvider.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('RespiteCareService._searchUserSubmitted error: $e');
      return [];
    }
  }

  // ── Submit a new provider (crowdsource) ─────────────────────────

  Future<String> submitProvider(RespiteProvider provider) async {
    final ref = await _db
        .collection('respiteProviders')
        .add(provider.toFirestore());
    return ref.id;
  }

  // ── Helpers ─────────────────────────────────────────────────────

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    // CMS data is often ALL CAPS — convert to title case
    return text
        .toLowerCase()
        .split(' ')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}
