// lib/models/communication_card.dart
//
// Data model + built-in library for communication picture cards with ASL
// sign descriptions. 30+ cards for non-verbal care recipients.

import 'package:flutter/material.dart';

class CommunicationCard {
  final String id;
  final String label;
  final String emoji;
  final String category;
  final String aslDescription;
  final String aslHandShape;
  final Color color;
  final String speakText;

  const CommunicationCard({
    required this.id,
    required this.label,
    required this.emoji,
    required this.category,
    required this.aslDescription,
    required this.aslHandShape,
    required this.color,
    required this.speakText,
  });

  // ── Category metadata ───────────────────────────────────────────

  static const Map<String, CommunicationCardCategory> categories = {
    'needs': CommunicationCardCategory(
        'Basic Needs', Icons.favorite, Color(0xFFE53935)),
    'feelings': CommunicationCardCategory(
        'Feelings', Icons.mood, Color(0xFF8E24AA)),
    'responses': CommunicationCardCategory(
        'Responses', Icons.check_circle_outline, Color(0xFF00897B)),
    'daily': CommunicationCardCategory(
        'Daily Life', Icons.wb_sunny_outlined, Color(0xFFF57C00)),
    'medical': CommunicationCardCategory(
        'Medical', Icons.medical_services_outlined, Color(0xFFD32F2F)),
  };

  // ── Full card library ───────────────────────────────────────────

  static const List<CommunicationCard> all = [
    // ── Needs ─────────────────────────────────────────────────────
    CommunicationCard(
      id: 'pain', label: 'Pain', emoji: '\uD83D\uDE23',
      category: 'needs', color: Color(0xFFE53935),
      aslDescription: 'Both fists twist in opposite directions near body.',
      aslHandShape: 'Fists \u2192 twist \u2192 opposite',
      speakText: 'I am in pain.',
    ),
    CommunicationCard(
      id: 'thirsty', label: 'Thirsty', emoji: '\uD83D\uDCA7',
      category: 'needs', color: Color(0xFF1E88E5),
      aslDescription: 'Index finger traces line down throat.',
      aslHandShape: 'Index \u2192 throat \u2192 down',
      speakText: 'I am thirsty.',
    ),
    CommunicationCard(
      id: 'hungry', label: 'Hungry', emoji: '\uD83C\uDF7D\uFE0F',
      category: 'needs', color: Color(0xFFF57C00),
      aslDescription: 'Cup hand moves down from chin to chest.',
      aslHandShape: 'Cup hand \u2192 chin \u2192 chest',
      speakText: 'I am hungry.',
    ),
    CommunicationCard(
      id: 'bathroom', label: 'Bathroom', emoji: '\uD83D\uDEBB',
      category: 'needs', color: Color(0xFF795548),
      aslDescription: 'Shake fist with thumb between index and middle finger (letter T).',
      aslHandShape: 'T-hand \u2192 shake',
      speakText: 'I need to use the bathroom.',
    ),
    CommunicationCard(
      id: 'cold', label: 'Cold', emoji: '\uD83E\uDD76',
      category: 'needs', color: Color(0xFF1565C0),
      aslDescription: 'Both fists shake near shoulders (shivering).',
      aslHandShape: 'Fists \u2192 shoulders \u2192 shake',
      speakText: 'I am cold.',
    ),
    CommunicationCard(
      id: 'hot', label: 'Hot', emoji: '\uD83E\uDD75',
      category: 'needs', color: Color(0xFFE53935),
      aslDescription: 'Claw hand pulls away from mouth, turning outward.',
      aslHandShape: 'Claw \u2192 mouth \u2192 away',
      speakText: 'I am hot.',
    ),
    CommunicationCard(
      id: 'help', label: 'Help', emoji: '\uD83C\uDD98',
      category: 'needs', color: Color(0xFFD32F2F),
      aslDescription: 'Closed fist (A-hand) on flat palm, both rise together.',
      aslHandShape: 'A-hand on palm \u2192 rise',
      speakText: 'I need help.',
    ),

    // ── Feelings ──────────────────────────────────────────────────
    CommunicationCard(
      id: 'happy', label: 'Happy', emoji: '\uD83D\uDE0A',
      category: 'feelings', color: Color(0xFF43A047),
      aslDescription: 'Both flat hands brush up chest repeatedly.',
      aslHandShape: 'Flat hands \u2192 chest \u2192 up',
      speakText: 'I am happy.',
    ),
    CommunicationCard(
      id: 'sad', label: 'Sad', emoji: '\uD83D\uDE22',
      category: 'feelings', color: Color(0xFF5C6BC0),
      aslDescription: 'Both open hands move down face.',
      aslHandShape: 'Open hands \u2192 face \u2192 down',
      speakText: 'I am sad.',
    ),
    CommunicationCard(
      id: 'scared', label: 'Scared', emoji: '\uD83D\uDE28',
      category: 'feelings', color: Color(0xFF8E24AA),
      aslDescription: 'Both fists open suddenly toward body (startled).',
      aslHandShape: 'Fists \u2192 open \u2192 toward body',
      speakText: 'I am scared.',
    ),
    CommunicationCard(
      id: 'tired', label: 'Tired', emoji: '\uD83D\uDE34',
      category: 'feelings', color: Color(0xFF546E7A),
      aslDescription: 'Both bent hands touch chest then fall outward.',
      aslHandShape: 'Bent hands \u2192 chest \u2192 fall',
      speakText: 'I am tired.',
    ),
    CommunicationCard(
      id: 'love', label: 'Love', emoji: '\u2764\uFE0F',
      category: 'feelings', color: Color(0xFFE91E63),
      aslDescription: 'Cross arms over chest (hugging yourself).',
      aslHandShape: 'Arms \u2192 cross \u2192 chest',
      speakText: 'I love you.',
    ),
    CommunicationCard(
      id: 'angry', label: 'Angry', emoji: '\uD83D\uDE20',
      category: 'feelings', color: Color(0xFFE53935),
      aslDescription: 'Claw hands pull away from face outward.',
      aslHandShape: 'Claws \u2192 face \u2192 outward',
      speakText: 'I am angry.',
    ),
    CommunicationCard(
      id: 'confused', label: 'Confused', emoji: '\uD83D\uDE15',
      category: 'feelings', color: Color(0xFF7E57C2),
      aslDescription: 'Curved hand circles near forehead.',
      aslHandShape: 'Curved hand \u2192 forehead \u2192 circle',
      speakText: 'I am confused.',
    ),

    // ── Responses ─────────────────────────────────────────────────
    CommunicationCard(
      id: 'yes', label: 'Yes', emoji: '\u2705',
      category: 'responses', color: Color(0xFF43A047),
      aslDescription: 'Fist nods forward (like nodding head with hand).',
      aslHandShape: 'Fist \u2192 nod forward',
      speakText: 'Yes.',
    ),
    CommunicationCard(
      id: 'no', label: 'No', emoji: '\u274C',
      category: 'responses', color: Color(0xFFE53935),
      aslDescription: 'Index and middle finger close onto thumb (snap).',
      aslHandShape: 'Index + middle \u2192 thumb \u2192 snap',
      speakText: 'No.',
    ),
    CommunicationCard(
      id: 'more', label: 'More', emoji: '\u2795',
      category: 'responses', color: Color(0xFF00897B),
      aslDescription: 'Fingertips of both flat hands tap together.',
      aslHandShape: 'Fingertips \u2192 tap together',
      speakText: 'More, please.',
    ),
    CommunicationCard(
      id: 'all_done', label: 'All Done', emoji: '\u270B',
      category: 'responses', color: Color(0xFF00897B),
      aslDescription: 'Both open hands twist outward (finished).',
      aslHandShape: 'Open hands \u2192 twist outward',
      speakText: 'I am all done.',
    ),
    CommunicationCard(
      id: 'wait', label: 'Wait', emoji: '\u23F3',
      category: 'responses', color: Color(0xFFF57C00),
      aslDescription: 'Wiggle fingers of both raised hands.',
      aslHandShape: 'Raised hands \u2192 wiggle fingers',
      speakText: 'Please wait.',
    ),
    CommunicationCard(
      id: 'thank_you', label: 'Thank You', emoji: '\uD83D\uDE4F',
      category: 'responses', color: Color(0xFF00897B),
      aslDescription: 'Flat hand touches chin then moves outward.',
      aslHandShape: 'Flat hand \u2192 chin \u2192 outward',
      speakText: 'Thank you.',
    ),

    // ── Daily Life ────────────────────────────────────────────────
    CommunicationCard(
      id: 'eat', label: 'Eat', emoji: '\uD83C\uDF74',
      category: 'daily', color: Color(0xFFF57C00),
      aslDescription: 'Fingertips tap mouth repeatedly.',
      aslHandShape: 'Fingertips \u2192 mouth \u2192 tap',
      speakText: 'I want to eat.',
    ),
    CommunicationCard(
      id: 'drink', label: 'Drink', emoji: '\uD83E\uDD64',
      category: 'daily', color: Color(0xFF1E88E5),
      aslDescription: 'Curved hand tips toward mouth (cup).',
      aslHandShape: 'Cup hand \u2192 tip \u2192 mouth',
      speakText: 'I want a drink.',
    ),
    CommunicationCard(
      id: 'sleep', label: 'Sleep', emoji: '\uD83D\uDE34',
      category: 'daily', color: Color(0xFF5C6BC0),
      aslDescription: 'Open hand draws down over face, closing.',
      aslHandShape: 'Open hand \u2192 face \u2192 close',
      speakText: 'I want to sleep.',
    ),
    CommunicationCard(
      id: 'medicine', label: 'Medicine', emoji: '\uD83D\uDC8A',
      category: 'daily', color: Color(0xFFE53935),
      aslDescription: 'Middle finger circles on flat palm.',
      aslHandShape: 'Middle finger \u2192 palm \u2192 circle',
      speakText: 'I need my medicine.',
    ),
    CommunicationCard(
      id: 'tv_music', label: 'TV / Music', emoji: '\uD83D\uDCFA',
      category: 'daily', color: Color(0xFF7E57C2),
      aslDescription: 'Flat hand waves side to side near ear.',
      aslHandShape: 'Flat hand \u2192 ear \u2192 wave',
      speakText: 'I want to watch TV or listen to music.',
    ),
    CommunicationCard(
      id: 'outside', label: 'Outside', emoji: '\uD83C\uDF33',
      category: 'daily', color: Color(0xFF43A047),
      aslDescription: 'Claw hand pulls out from fist (extracting).',
      aslHandShape: 'Claw \u2192 fist \u2192 pull out',
      speakText: 'I want to go outside.',
    ),
    CommunicationCard(
      id: 'hug', label: 'Hug', emoji: '\uD83E\uDD17',
      category: 'daily', color: Color(0xFFE91E63),
      aslDescription: 'Cross arms and squeeze (hugging gesture).',
      aslHandShape: 'Arms \u2192 cross \u2192 squeeze',
      speakText: 'I want a hug.',
    ),

    // ── Medical ───────────────────────────────────────────────────
    CommunicationCard(
      id: 'doctor', label: 'Doctor', emoji: '\uD83D\uDC68\u200D\u2695\uFE0F',
      category: 'medical', color: Color(0xFFD32F2F),
      aslDescription: 'Tap wrist with fingertips (taking pulse).',
      aslHandShape: 'Fingertips \u2192 wrist \u2192 tap',
      speakText: 'I need to see the doctor.',
    ),
    CommunicationCard(
      id: 'nauseous', label: 'Nauseous', emoji: '\uD83E\uDD22',
      category: 'medical', color: Color(0xFF43A047),
      aslDescription: 'Claw hand circles near stomach.',
      aslHandShape: 'Claw \u2192 stomach \u2192 circle',
      speakText: 'I feel nauseous.',
    ),
    CommunicationCard(
      id: 'dizzy', label: 'Dizzy', emoji: '\uD83D\uDE35',
      category: 'medical', color: Color(0xFF7E57C2),
      aslDescription: 'Index finger circles beside temple.',
      aslHandShape: 'Index \u2192 temple \u2192 circle',
      speakText: 'I feel dizzy.',
    ),
    CommunicationCard(
      id: 'cant_breathe', label: "Can't Breathe", emoji: '\uD83D\uDE24',
      category: 'medical', color: Color(0xFFD32F2F),
      aslDescription: 'Both hands grip chest, pulling outward.',
      aslHandShape: 'Hands \u2192 chest \u2192 pull out',
      speakText: 'I cannot breathe well.',
    ),
    CommunicationCard(
      id: 'fall', label: 'Fall', emoji: '\u26A0\uFE0F',
      category: 'medical', color: Color(0xFFF57C00),
      aslDescription: 'V-fingers stand on palm, then topple over.',
      aslHandShape: 'V-fingers \u2192 palm \u2192 topple',
      speakText: 'I fell down.',
    ),
  ];
}

class CommunicationCardCategory {
  final String label;
  final IconData icon;
  final Color color;

  const CommunicationCardCategory(this.label, this.icon, this.color);
}
