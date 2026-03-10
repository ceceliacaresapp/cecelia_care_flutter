// lib/services/gemini_service.dart
import 'dart:async'; // Required for StreamController
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:cecelia_care_flutter/l10n/app_localizations.dart'; // Import AppLocalizations

/// Thin wrapper for interacting with the Gemini API via the Firebase Extension.
/// This version writes prompts to Firestore and listens for responses in real-time.
class GeminiService {
  // Private constructor
  GeminiService._();
  // Singleton instance
  static final GeminiService instance = GeminiService._();

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // The Firestore collection name configured for the 'firestore-genai-chatbot' extension
  final String _chatCollection = 'generate'; // This should match your extension config!

  // Local history to manage messages displayed in the UI.
  final List<types.Message> _localHistory = [];

  // StreamController to provide a stream of messages to the UI (e.g., CeceliaBotSheet)
  final StreamController<types.Message> _messageStreamController =
      StreamController<types.Message>.broadcast();
  Stream<types.Message> get messageStream => _messageStreamController.stream;

  /// Clears the local conversation history.
  void clearHistory() {
    _localHistory.clear();
  }

  /* ---------------- Public API ------------------- */

  /// Sends a user prompt to the AI bot via the Firebase Extension.
  /// It writes to Firestore and listens for the bot's response.
  Future<void> sendPromptToBot(
    String userPrompt,
    String userId,
    // --- I18N UPDATE ---
    // AppLocalizations is now required to generate localized error messages.
    AppLocalizations l10n, [
    Map<String, dynamic>? context,
  ]) async {
    // 1. Add user message to local history and stream it for immediate UI update
    final userMessage = types.TextMessage(
      author: types.User(id: userId),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: userPrompt,
    );
    _localHistory.add(userMessage);
    _messageStreamController.add(userMessage);

    // --- I18N UPDATE ---
    // Use a localized name for the bot.
    final botUser = types.User(id: 'cecelia_bot_id', firstName: l10n.ceceliaBotName);

    try {
      // 2. Create a new document in the configured Firestore collection
      final Map<String, dynamic> firestoreData = {
        'prompt': userPrompt,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (context != null) {
        firestoreData['context'] = context;
      }
      final DocumentReference docRef =
          await _firestore.collection(_chatCollection).add(firestoreData);

      debugPrint('Firestore document created with ID: ${docRef.id} for prompt: "$userPrompt"');

      // 3. Listen for real-time updates on this specific document
      final Completer<types.Message> completer = Completer();
      late StreamSubscription subscription;

      subscription = docRef.snapshots().listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data()! as Map<String, dynamic>;
          debugPrint('Document snapshot received for ${docRef.id}: $data');

          if (data.containsKey('response') && data['response'] != null) {
            final String botResponse = data['response'] as String;
            debugPrint('Bot response received: "$botResponse"');
            final botMessage = types.TextMessage(
              author: botUser,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: docRef.id,
              text: botResponse,
            );
            _localHistory.add(botMessage);
            _messageStreamController.add(botMessage);
            completer.complete(botMessage);
            subscription.cancel();
          } else if (data.containsKey('status') && (data['status'] as Map<String, dynamic>)['state'] == 'ERROR') {
            // Handle errors reported by the extension
            // --- I18N UPDATE ---
            final String errorMessage = (data['status'] as Map<String, dynamic>)['error'] ?? l10n.geminiUnknownError;
            debugPrint('Firebase Extension reported error for ${docRef.id}: $errorMessage');
            final errorMessageBot = types.TextMessage(
              author: botUser,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: docRef.id,
              text: l10n.geminiFirebaseError(errorMessage),
            );
            _localHistory.add(errorMessageBot);
            _messageStreamController.add(errorMessageBot);
            completer.complete(errorMessageBot);
            subscription.cancel();
          }
        }
      }, onError: (error) {
        // Handle errors during Firestore listening
        debugPrint('Error listening to Firestore document ${docRef.id}: $error');
        // --- I18N UPDATE ---
        final errorMessageBot = types.TextMessage(
          author: botUser,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: docRef.id,
          text: l10n.geminiCommunicationError(error.toString()),
        );
        _localHistory.add(errorMessageBot);
        _messageStreamController.add(errorMessageBot);
        completer.completeError(error);
        subscription.cancel();
      });

      await completer.future;
    } catch (e) {
      // Handle any other unexpected errors during the process
      debugPrint('Unexpected error in GeminiService.sendPromptToBot: $e');
      // --- I18N UPDATE ---
      final errorMessageBot = types.TextMessage(
        author: botUser,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: l10n.geminiUnexpectedError(e.toString()),
      );
      _localHistory.add(errorMessageBot);
      _messageStreamController.add(errorMessageBot);
    }
  }

  bool isToolCall(Map<String, dynamic>? m) {
    // This logic is for structured function calls, which are not used with the Firestore extension.
    return false;
  }

  /// Returns a copy of the current local chat history for UI display.
  List<types.Message> get localHistory => List.unmodifiable(_localHistory);

  /// Disposes of the stream controller when the service is no longer needed.
  void dispose() {
    _messageStreamController.close();
  }
}