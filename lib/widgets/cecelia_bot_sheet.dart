// lib/widgets/cecelia_bot_sheet.dart

import 'package:flutter/material.dart';
import 'dart:async';
// Aliased to prevent conflicts with other 'Chat' classes in the project
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/services/gemini_service.dart';

class CeceliaBotSheet extends StatefulWidget {
  const CeceliaBotSheet({
    super.key,
    required this.contextForAI,
  });

  final Map<String, dynamic> contextForAI;

  @override
  State<CeceliaBotSheet> createState() => _CeceliaBotSheetState();
}

class _CeceliaBotSheetState extends State<CeceliaBotSheet> {
  final _messages = <types.Message>[];
  bool _busy = false;
  final _uuid = const Uuid();
  bool _isInit = false;

  // These will be initialized in didChangeDependencies
  late types.User _user;
  late types.User _bot;
  late AppLocalizations _l10n;

  final GeminiService _geminiService = GeminiService.instance;
  late StreamSubscription<types.Message> _messageSubscription;

  @override
  void initState() {
    super.initState();
    _geminiService.clearHistory();

    // Subscribe to the message stream from GeminiService
    _messageSubscription = _geminiService.messageStream.listen((message) {
      if (mounted) {
        setState(() {
          _messages.insert(0, message);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize context-dependent variables only once
    if (!_isInit) {
      _l10n = AppLocalizations.of(context)!;
      // Define users here using the localized name for the bot
      _user = const types.User(id: 'current_app_user_id', firstName: 'You');
      _bot = types.User(id: 'cecelia_bot_id', firstName: _l10n.ceceliaBotName);
      
      // Add the initial localized bot greeting
      _addBotMessageToChat(_l10n.ceceliaInitialGreeting);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _messageSubscription.cancel();
    _geminiService.dispose();
    super.dispose();
  }

  /// Called by the Chat UI when the user presses “send”
  Future<void> _handleSend(types.PartialText partial) async {
    setState(() => _busy = true);

    final text = partial.text;
    final String userId = _user.id;

    await _geminiService.sendPromptToBot(text, userId, _l10n, widget.contextForAI);

    if (mounted) {
      setState(() => _busy = false);
    }
  }

  /// Adds a bot message directly to the UI's message list.
  void _addBotMessageToChat(String text) {
    final botMessage = types.TextMessage(
      author: _bot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: _uuid.v4(),
      text: text,
    );
    if (mounted) {
      setState(() => _messages.insert(0, botMessage));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            Material(
              color: Theme.of(context).canvasColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      _l10n.chatWithCeceliaTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the IconButton
                ],
              ),
            ),
            Expanded(
              // Using chat_ui.Chat to avoid naming conflicts with other packages
              child: chat_ui.Chat(
                messages: _messages,
                onSendPressed: _handleSend,
                user: _user,
                isAttachmentUploading: _busy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}