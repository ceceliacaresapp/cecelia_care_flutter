// lib/utils/gratitude_prompts.dart
//
// Static banks of caregiver-specific content:
//   1. Gratitude journal prompts — 50+ rotating daily prompts
//   2. Affirmations — 40+ caregiver-specific affirmations
//
// Daily rotation uses a deterministic hash of the date so every user
// sees the same prompt/affirmation on a given day, but each day is
// different. No Firestore dependency — pure Dart.

/// Returns today's prompt index for a list of [length] items.
/// Deterministic: same date → same index, but varies day-to-day.
int _dailyIndex(int length, {int offset = 0}) {
  final now = DateTime.now();
  final seed = now.year * 10000 + now.month * 100 + now.day + offset;
  return seed % length;
}

// ---------------------------------------------------------------------------
// Gratitude prompts — shown at the top of the Caregiver Journal screen.
// The user taps "Use this prompt" and it pre-fills the journal composer.
// ---------------------------------------------------------------------------

class GratitudePrompts {
  GratitudePrompts._();

  static const List<String> _prompts = [
    // Care recipient focused
    "What's one thing your care recipient did today that made you smile?",
    "Describe a moment of connection you shared with your care recipient recently.",
    "What's something your care recipient taught you — about life, patience, or love?",
    "What's a favorite memory you have with the person you're caring for?",
    "What's one small victory your care recipient had today?",
    "What's something about your care recipient that you admire?",
    "Describe a moment today when your care recipient seemed peaceful or content.",
    "What's a funny or heartwarming thing your care recipient said or did recently?",
    "What's one way your care recipient has shown gratitude, even in a small way?",
    "What's something about your care recipient's personality that hasn't changed?",

    // Self-appreciation
    "What's one thing you did today that you're proud of as a caregiver?",
    "Name three things about yourself that make you a good caregiver.",
    "What's a difficult situation you handled well recently?",
    "What's a skill you've developed since becoming a caregiver?",
    "When did you last surprise yourself with how strong you are?",
    "What's one boundary you've set that you're glad about?",
    "What's something kind you did for yourself this week?",
    "What part of caregiving feels most natural to you?",
    "What would your care recipient say they appreciate most about you?",
    "What's one thing you've learned about yourself through caregiving?",

    // Support system
    "Who helped you this week, even in a small way? How did it feel?",
    "What's one relationship that has grown stronger because of your caregiving journey?",
    "Name someone who checks in on you. What does their support mean?",
    "What's the most helpful thing someone has said to you recently?",
    "Who makes you laugh when things are hard?",
    "What community or resource has been unexpectedly helpful?",
    "Describe a moment when someone understood what you're going through.",
    "What's one act of kindness you received this week?",

    // Finding meaning
    "What gives you the most purpose in your caregiving role?",
    "What's one way caregiving has made you a better person?",
    "What values guide you through the hardest days?",
    "What would you tell a new caregiver about finding meaning in this role?",
    "What's something beautiful you noticed today that you might have missed before?",
    "What's one way your perspective on life has changed for the better?",
    "Describe a moment this week when you felt at peace.",
    "What's something simple that brought you joy today?",

    // Daily life
    "What's the best thing you ate or drank today?",
    "What made you laugh today?",
    "What's one thing in your home that brings you comfort?",
    "Describe the best part of your morning routine.",
    "What's a song, show, or book that lifted your spirits recently?",
    "What's one thing you're looking forward to this week?",
    "What's the most relaxing thing you did in the past few days?",
    "What's a sound, smell, or sight that always makes you feel better?",

    // Resilience
    "What's a challenge you've overcome that you didn't think you could?",
    "What keeps you going on the really tough days?",
    "What's one thing that went better than expected today?",
    "How have you grown in the past month?",
    "What's something that felt impossible a year ago that's routine now?",
    "When was the last time you asked for help? How did it go?",
    "What's one coping strategy that actually works for you?",
    "What would you say to comfort yourself on a bad day?",
    "What's one thing you've let go of that has brought you peace?",
    "Describe a time when a hard day ended up having a silver lining.",
  ];

  /// Today's gratitude prompt. Changes daily.
  static String get todayPrompt => _prompts[_dailyIndex(_prompts.length)];

  /// A second prompt option (different from todayPrompt).
  static String get alternatePrompt =>
      _prompts[_dailyIndex(_prompts.length, offset: 7)];

  /// The full prompt bank for display or shuffle.
  static List<String> get all => List.unmodifiable(_prompts);

  /// Total number of prompts available.
  static int get count => _prompts.length;
}

// ---------------------------------------------------------------------------
// Affirmations — shown in the swipeable carousel.
// Users can save favorites (stored in SharedPreferences by index).
// ---------------------------------------------------------------------------

class CaregiverAffirmations {
  CaregiverAffirmations._();

  static const List<String> _affirmations = [
    // Worth & identity
    "You are making a difference in someone's life every single day.",
    "Your care matters more than you know.",
    "You are enough — even on the days it doesn't feel like it.",
    "Being a caregiver doesn't define you, but it reveals your strength.",
    "You are worthy of the same love and care you give to others.",
    "Your compassion is a gift to everyone around you.",
    "You don't have to be perfect to be an amazing caregiver.",
    "Your presence alone is a comfort to the person you care for.",

    // Strength & resilience
    "You are stronger than you think and braver than you feel.",
    "Difficult days don't erase the incredible work you've done.",
    "Every small act of care adds up to something extraordinary.",
    "You have survived every hard day so far — and you will survive this one too.",
    "It's okay to rest. Rest is not quitting.",
    "You are doing the best you can with what you have, and that is enough.",
    "Your strength inspires the people around you, even when you can't see it.",
    "Hard doesn't mean impossible. You've proven that already.",

    // Self-care permission
    "Taking care of yourself is not selfish — it's necessary.",
    "You deserve breaks, joy, and moments just for you.",
    "It's okay to not be okay sometimes.",
    "Your feelings are valid. Every single one of them.",
    "You are allowed to ask for help. Asking is a sign of wisdom, not weakness.",
    "Rest when you need to. The world can wait.",
    "Caring for yourself is how you sustain your ability to care for others.",
    "You don't owe anyone an explanation for setting boundaries.",

    // Hope & perspective
    "This season of life is challenging, but it won't last forever.",
    "Even in the hardest moments, there is something to hold onto.",
    "Tomorrow is a new day with new possibilities.",
    "You are not alone in this journey, even when it feels lonely.",
    "Small progress is still progress.",
    "Joy can coexist with difficulty. Let yourself feel both.",
    "The love you give comes back to you in ways you might not expect.",
    "You are planting seeds of kindness that will bloom in time.",

    // Specific to caregiving
    "Your patience is extraordinary, even when it's running thin.",
    "The person you care for is lucky to have someone who cares so deeply.",
    "You notice the little things — and that's what makes the biggest difference.",
    "Your care team is stronger because you're part of it.",
    "Every medication given, every meal prepared, every hand held — it all matters.",
    "You are the advocate your care recipient needs.",
    "The routines you've built provide stability and comfort.",
    "You show up, day after day. That consistency is love in action.",
    "You handle the hard conversations with grace.",
    "Your dedication to someone else's wellbeing is truly remarkable.",
  ];

  /// Today's featured affirmation. Changes daily.
  static String get todayAffirmation =>
      _affirmations[_dailyIndex(_affirmations.length)];

  /// Returns a set of [count] affirmations starting from today's rotation.
  static List<String> dailySet({int count = 5}) {
    final start = _dailyIndex(_affirmations.length);
    return List.generate(
      count,
      (i) => _affirmations[(start + i) % _affirmations.length],
    );
  }

  /// The full affirmation bank.
  static List<String> get all => List.unmodifiable(_affirmations);

  /// Total number of affirmations available.
  static int get count => _affirmations.length;
}
