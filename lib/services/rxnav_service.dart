import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom exception for errors originating from the RxNavService.
class RxNavApiException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;

  RxNavApiException(this.message, {this.statusCode, this.uri});

  @override
  String toString() {
    return 'RxNavApiException: $message ${statusCode != null ? "(Status Code: $statusCode)" : ""} ${uri != null ? "(URI: $uri)" : ""}';
  }
}

/// A service to interact with the NLM RxNav REST API.
///
/// It provides methods for searching drugs and checking for interactions.
/// Learn more at: https://rxnav.nlm.nih.gov/
class RxNavService {
  static const _base = 'https://rxnav.nlm.nih.gov/REST';
  static const _drugSearchPath = '/drugs.json';
  static const _interactionPath =
      '/interaction/list.json'; // Adjusted for consistency if needed

  final http.Client _client;

  /// Creates an [RxNavService].
  ///
  /// An [http.Client] must be provided, which will be used for all
  /// network requests. This allows for dependency injection and easier testing.
  RxNavService({required http.Client client}) : _client = client;

  /// Autocompletes a drug name using the RxNav API.
  Future<List<DrugSuggestion>> searchByName(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final url = Uri.parse(
        '$_base$_drugSearchPath?name=${Uri.encodeQueryComponent(query)}');

    try {
      final res = await _client.get(url);
      if (res.statusCode != 200) {
        throw RxNavApiException('Failed to search for drug by name.',
            statusCode: res.statusCode, uri: url);
      }
      final root = jsonDecode(res.body);
      final conceptGroups = root['drugGroup']['conceptGroup'] as List? ?? [];

      return conceptGroups
          .expand((g) => g['conceptProperties'] as List? ?? [])
          .map((c) => DrugSuggestion(
                name: c['name'] as String,
                rxCui: c['rxcui'] as String,
              ))
          .toList();
    } catch (e) {
      // Re-throw as a specific exception if it's not one already
      throw RxNavApiException(
          'An unexpected error occurred during drug search: ${e.toString()}',
          uri: url);
    }
  }

  /// Given a list of two or more RxCUIs, returns a list of interaction pairs.
  Future<List<DrugInteraction>> checkInteractions(List<String> rxcuis) async {
    if (rxcuis.length < 2) return [];

    final url = Uri.parse('$_base$_interactionPath?rxcuis=${rxcuis.join('+')}');
    
    try {
      final res = await _client.get(url);
      if (res.statusCode != 200) {
        throw RxNavApiException('Failed to check for drug interactions.',
            statusCode: res.statusCode, uri: url);
      }
      final root = jsonDecode(res.body);

      // The key can be 'fullInteractionTypeGroup' or 'interactionTypeGroup'
      // depending on the API version and request. Safely check for both.
      final groups = (root['fullInteractionTypeGroup'] ?? root['interactionTypeGroup']) as List? ?? [];
      
      return groups
          .expand((g) => (g['fullInteractionType'] ?? g['interactionType']) as List? ?? [])
          .expand((t) => t['interactionPair'] as List? ?? [])
          .map((p) {
            final interactionConcepts = p['interactionConcept'] as List? ?? [];
            String? drug1Name, drug2Name;

            if (interactionConcepts.isNotEmpty &&
                interactionConcepts[0]['minConceptItem'] != null) {
              drug1Name =
                  interactionConcepts[0]['minConceptItem']['name'] as String?;
            }
            if (interactionConcepts.length > 1 &&
                interactionConcepts[1]['minConceptItem'] != null) {
              drug2Name =
                  interactionConcepts[1]['minConceptItem']['name'] as String?;
            }

            return DrugInteraction(
              description: p['description'] as String,
              severity: p['severity'] as String? ?? 'N/A',
              drug1Name: drug1Name,
              drug2Name: drug2Name,
            );
          })
          .toList();
    } catch (e) {
      throw RxNavApiException(
          'An unexpected error occurred during interaction check: ${e.toString()}',
          uri: url);
    }
  }
}

/// Represents a drug suggestion from the RxNav API search.
class DrugSuggestion {
  final String name;
  final String rxCui;

  DrugSuggestion({required this.name, required this.rxCui});
}

/// Represents a potential interaction between two drugs.
class DrugInteraction {
  final String description;
  final String severity;
  final String? drug1Name;
  final String? drug2Name;

  DrugInteraction({
    required this.description,
    required this.severity,
    this.drug1Name,
    this.drug2Name,
  });
}