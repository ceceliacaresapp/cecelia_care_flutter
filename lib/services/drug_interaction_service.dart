import 'dart:convert';
import 'package:http/http.dart' as http;

/// A service to check for drug interactions using the NIH RxNav API.
///
/// This service queries the RxNav API to find potential interactions
/// among a list of drugs. It requires an [http.Client] to be injected
/// for making network requests, which decouples the service from the HTTP
/// implementation and makes it easier to test.
class DrugInteractionService {
  /// The base URL for the RxNav interaction API.
  static const String _baseUrl =
      'https://rxnav.nlm.nih.gov/REST/interaction/list.json';

  /// The HTTP client used for making API requests.
  final http.Client _client;

  /// Creates an instance of [DrugInteractionService].
  ///
  /// Requires an [http.Client] which will be used for all network requests.
  DrugInteractionService({required http.Client client}) : _client = client;

  /// Checks for interactions among a list of RxCUI codes.
  ///
  /// Given a list of RxCUI codes (drug identifiers), this function queries
  /// the RxNav API. If interactions are found, it returns a comma-separated
  /// string of the interaction descriptions.
  ///
  /// Returns `null` if:
  /// - Fewer than two RxCUIs are provided.
  /// - No interactions are found.
  /// - An error occurs during the API call or parsing.
  ///
  /// [rxCuis] A list of drug RxCUI strings. Must contain at least two.
  Future<String?> checkInteractions(List<String> rxCuis) async {
    if (rxCuis.length < 2) {
      return null; // Not enough drugs to check for interactions
    }

    final String rxcuisParam = rxCuis.join('+');
    final url = Uri.parse('$_baseUrl?rxcuis=$rxcuisParam');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Safely parse the complex JSON structure to extract descriptions.
        final List<dynamic> interactionTypeGroups =
            data['interactionTypeGroup'] as List? ?? [];

        final List<String> descriptions = interactionTypeGroups
            .expand((group) {
              final g = group as Map<String, dynamic>?;
              return g?['interactionType'] as List? ?? [];
            })
            .expand((type) {
              final t = type as Map<String, dynamic>?;
              return t?['interactionPair'] as List? ?? [];
            })
            .map((pair) {
              final p = pair as Map<String, dynamic>?;
              return p?['description'] as String?;
            })
            .whereType<String>() // Filters out nulls and ensures String type.
            .toList();

        return descriptions.isNotEmpty ? descriptions.join(', ') : null;
      } else {
        print(
            'RxNav DrugInteractionService API request failed with status ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error in DrugInteractionService.checkInteractions: $e');
      return null;
    }
  }
}