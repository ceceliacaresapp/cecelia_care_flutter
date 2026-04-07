// lib/utils/prefs_keys.dart
//
// Single source of truth for every SharedPreferences key the app reads or
// writes. Centralizing these:
//
//   • Prevents typos that silently lose data
//   • Lets you grep one file to see everything the app persists
//   • Makes it easy to audit what would need to be cleared on logout
//   • Catches future key collisions at compile time
//
// Convention: keys with `{...}` placeholders are *prefix* helpers — call
// the corresponding `for*()` factory to build the full key.
//
// Some constants intentionally duplicate existing private constants in
// individual files. The plan is to migrate those files to use these
// constants over time; for now both can coexist without breaking anything.

class PrefsKeys {
  PrefsKeys._();

  // ── Identity / session ─────────────────────────────────────
  static const String activeElderId = 'activeElderId';
  static const String selectedLanguageCode = 'selected_language_code';
  static const String themeMode = 'theme_mode';

  // ── Theme + accessibility ──────────────────────────────────
  static const String accessibilityVisualOnly = 'accessibility_visual_only';

  // ── Notifications ──────────────────────────────────────────
  static const String notificationPreferences = 'notification_preferences';

  /// Per-elder, per-month flag tracking whether a weight-loss alert
  /// has already fired (so we don't spam the user).
  static String weightAlertFor(String elderId, String yyyyMm) =>
      'weight_alert_${elderId}_$yyyyMm';

  // ── Dashboard / care screen layout ─────────────────────────
  static const String dashboardSections = 'dashboard_sections_config';
  static const String careScreenTileOrder = 'care_screen_tile_order';

  // ── Training / education ───────────────────────────────────
  static const String viewedTrainingResources = 'viewed_training_resources';

  /// Per-elder cached current stage on a disease progression roadmap.
  static String diseaseRoadmapStage(String elderId, String diseaseId) =>
      'roadmap_stage_${elderId}_$diseaseId';

  // ── Hydration ──────────────────────────────────────────────
  static const String hydrationGoal = 'hydration_goal_oz';
  static const String hydrationUnit = 'hydration_unit';

  // ── Insurance + budget ─────────────────────────────────────
  /// Annual insurance plan keyed by year. Use `forInsurancePlan(2025)`.
  static String insurancePlanFor(int year) => 'insurance_plan_$year';

  // ── Emergency / rescue meds ────────────────────────────────
  /// Per-elder set of rescue-medication IDs the caregiver has marked
  /// "in use" on the emergency card screen.
  static String rescueMedsFor(String elderId) => 'rescue_meds_$elderId';

  // ── Messaging / timeline ───────────────────────────────────
  /// Per-user, per-elder timestamp of the last message read on the
  /// timeline tab. Used to compute the unread badge.
  static String messageLastSeenFor(String userId, String elderId) =>
      'msg_last_seen_${userId}_$elderId';

  /// Per-user, per-elder list of message IDs hidden from the timeline
  /// (caregiver "remove from my view" action).
  static String hiddenMessagesFor(String userId, String elderId) =>
      'hidden_messages_${userId}_$elderId';

  // ── Self-care ──────────────────────────────────────────────
  static const String affirmationFavorites = 'affirmation_favorites';

  // ── Burnout intervention suppression ───────────────────────
  /// "Don't show me this again today" flag for the burnout intervention
  /// modal. The exact key is owned by BurnoutInterventionScreen but is
  /// listed here for visibility into all persisted state.
  static const String burnoutInterventionSuppressedUntil =
      'burnout_intervention_suppressed_until';

  // ── Weather cache ──────────────────────────────────────────
  static const String weatherLat = 'weather_lat';
  static const String weatherLon = 'weather_lon';
  static const String weatherCache = 'weather_cache';
}
