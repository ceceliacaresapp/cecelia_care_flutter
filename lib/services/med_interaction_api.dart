// lib/services/med_interaction_api.dart

import 'dart:convert';
import 'package:flutter/foundation.dart'; // for debugPrint
import 'package:http/http.dart' as http;

class MedInteractionApi {
  /// Base URL for RxNav REST services
  static const String _baseUrl = 'https://rxnav.nlm.nih.gov/REST';

  /// Fetch interactions for a list of RxCUI (RxNorm Concept Unique Identifier) codes.
  /// Returns a list of interaction descriptions, or an empty list if none found
  /// or on error.
  static Future<List<String>> fetchInteractions(List<String> rxcuis) async {
    if (rxcuis.isEmpty) return [];

    // Join codes with '+' exactly, per RxNav requirements
    final joined = rxcuis.join('+');
    // Note: the endpoint is /interaction/list (no .json extension)
    final url = '$_baseUrl/interaction/list?rxcuis=$joined';

    debugPrint('Fetching interactions from: $url');

    try {
      final resp = await http.get(Uri.parse(url));

      if (resp.statusCode != 200) {
        debugPrint('Failed to fetch interactions: '
            '${resp.statusCode} ${resp.body}');
        return [];
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final fullInteractionTypeGroups =
          data['fullInteractionTypeGroup'] as List<dynamic>? ?? [];

      final List<String> descriptions = [];
      for (var group in fullInteractionTypeGroups) {
        final types = (group['fullInteractionType'] as List<dynamic>?);
        if (types == null) continue;
        for (var type in types) {
          final pairs = (type['interactionPair'] as List<dynamic>?);
          if (pairs == null) continue;
          for (var pair in pairs) {
            final desc = pair['description'] as String?;
            if (desc != null && desc.isNotEmpty) {
              descriptions.add(desc);
            }
          }
        }
      }

      debugPrint('Parsed interactions: $descriptions');
      return descriptions;
    } catch (e, stack) {
      debugPrint('Error parsing interactions: $e\n$stack');
      return [];
    }
  }
}
