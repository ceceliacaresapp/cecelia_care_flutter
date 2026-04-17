// lib/services/support_group_service.dart
//
// Search + submit layer for caregiver support groups. Mirrors
// RespiteCareService: queries the bundled static directory first
// (works offline, no delay), then folds in user-submitted groups
// from Firestore (zip-prefix matched for regional relevance).
//
// A third source — partner scrape / Google Places — is intentionally
// left as a documented extension point. When you eventually want it,
// add a `_searchExternal(...)` method and merge its results here
// with the same dedup-by-name convention.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'package:cecelia_care_flutter/models/support_group.dart';

class SupportGroupService {
  SupportGroupService._();
  static final instance = SupportGroupService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Main orchestrator. [zipCode] is optional — when empty, only the
  /// national directory is returned (still useful for virtual/phone
  /// groups). When supplied, we also pull user-submitted local groups
  /// that share the 3-digit zip prefix.
  Future<List<SupportGroup>> search({
    String zipCode = '',
    Iterable<SupportConditionType> conditions = const [],
    SupportFormat? format,
  }) async {
    final bundled = SupportGroupDirectory.filter(
      conditions: conditions,
      format: format,
    );

    final submitted = zipCode.trim().length >= 3
        ? await _searchUserSubmitted(
            zip: zipCode.trim(),
            conditions: conditions,
            format: format,
          )
        : <SupportGroup>[];

    // Dedup by lowercase name — bundled records win over local
    // submissions when they collide (bundled are curated + verified).
    final seen = <String>{};
    final merged = <SupportGroup>[];
    for (final g in [...bundled, ...submitted]) {
      final key = g.name.toLowerCase().trim();
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      merged.add(g);
    }
    return merged;
  }

  Future<List<SupportGroup>> _searchUserSubmitted({
    required String zip,
    Iterable<SupportConditionType> conditions = const [],
    SupportFormat? format,
  }) async {
    try {
      final prefix = zip.substring(0, 3);
      // Primary filter is zipPrefix — Firestore can't do arrayContainsAny
      // + equality on different fields efficiently, so we narrow by zip
      // and then filter client-side for condition / format.
      final snap = await _db
          .collection('supportGroups')
          .where('zipPrefix', isEqualTo: prefix)
          .limit(50)
          .get();

      var results = snap.docs
          .map((d) => SupportGroup.fromFirestore(d.id, d.data()))
          .toList();

      final conds = conditions.toSet();
      if (conds.isNotEmpty) {
        results = results
            .where((g) => g.conditions.any(conds.contains))
            .toList();
      }
      if (format != null) {
        results = results.where((g) => g.format == format).toList();
      }
      return results;
    } catch (e) {
      debugPrint('SupportGroupService._searchUserSubmitted error: $e');
      return [];
    }
  }

  /// Submit a new community group. Writes to the `supportGroups`
  /// collection; rules restrict to any authenticated user. No client-
  /// side edit/delete so spammers can't delete legit entries.
  Future<String> submitGroup(SupportGroup group) async {
    final ref = await _db
        .collection('supportGroups')
        .add(group.toFirestore());
    return ref.id;
  }
}
