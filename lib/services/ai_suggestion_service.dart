// lib/services/ai_suggestion_service.dart
//
// Thin, provider-agnostic abstraction for on-demand AI text suggestions.
//
// The app is not yet connected to a paid LLM provider, so this service
// currently returns an `unavailable` result for every request. Screens use
// the same method signatures they will keep once Gemini / Claude / OpenAI
// is wired in, which means wiring a real provider later is a single
// implementation swap — no UI changes required.
//
// When a real provider is integrated, either:
//   a) Replace the body of _generate() to call the provider directly, OR
//   b) Register a new implementation via `AiSuggestionService.configure()`
//      (e.g. from `locator.dart`) that delegates to a Cloud Function /
//      Firebase Extension. The existing GeminiService uses the
//      firestore-genai-chatbot extension pattern — production suggestions
//      should route through Cloud Functions so the API key stays server-side.
//
// Each public method returns a focused `AiSuggestionRequest` → the caller
// gets back an `AiSuggestionResult` describing availability, suggested
// text, a short rationale, and any error. UI treats an `unavailable`
// result as "show the Suggest button disabled with a coming-soon tooltip."

import 'package:flutter/foundation.dart';

/// Enumerates the succession-plan sections the UI can request a suggestion
/// for. Keeping these as an enum (vs free-form strings) means the server
/// side will be able to route to a section-specific prompt template.
enum AiSuggestionKind {
  dailyRoutine,
  medicationQuirks,
  behavioralTriggers,
  calmingTechniques,
  communicationTips,
  personalHistory,
  // Taper planner — given a medication + starting dose + reason + prescriber
  // preferences, returns a suggested schedule. The caller surfaces this
  // as a draft that the caregiver then confirms against the real
  // prescription note; it is *never* auto-applied.
  taperSuggestion,
  // Zarit burden insight — given the 12 item scores + recent history,
  // returns a short plain-language summary of where the burden is
  // concentrated and what specific support (respite, support group,
  // therapist) the caregiver might pursue. Never replaces clinical
  // guidance; surfaces alongside the raw score.
  zaritBurdenInsight,
  // Music reaction patterns — given the recent reaction log, returns a
  // plain-language summary of which songs / decades / contexts
  // consistently calm this person, plus specific suggestions for
  // upcoming sundowning or bathing windows. Falls back to the
  // rule-based MusicInsights computation when the provider is offline.
  musicPatternInsight,
  // Sleep-wake rhythm insight — given 7+ days of sleep / waking /
  // behavioral data, returns a plain-language summary of the rhythm
  // pattern plus specific chronobiology interventions (light therapy
  // timing, caffeine cutoff, bedtime anchor). Never replaces medical
  // guidance; surfaces alongside the radial chart.
  sleepRhythmInsight,
  // Insurance appeal letter draft — given a denial reason, claim
  // details, and carrier, drafts a structured appeal letter the
  // caregiver edits and mails. Always surface as a DRAFT, never
  // auto-send.
  insuranceAppealDraft,
  // Insurance coverage insight — scans claim history for under-billing
  // or patterns (e.g. "3 claims at the same provider were denied for
  // the same code — check plan's PT cap"). Rule-based fallback is the
  // status-count summary on the dashboard.
  insuranceCoverageInsight,
  // Incident report narrative polish — given the raw field values,
  // returns a grammatically polished, professional narrative paragraph
  // suitable for compliance filing. The caregiver always edits the
  // draft; it is never auto-saved.
  incidentNarrativeDraft,
  // Support group match — ranks the bundled + local support groups by
  // fit for this caregiver (primary condition, preferred format,
  // language, time-of-day availability). Client falls back to
  // unfiltered directory when no provider is wired.
  supportGroupMatch,
}

/// Input payload for a suggestion request. `context` holds the structured
/// hints the prompt template should condition on — e.g. recent behavioral
/// entries, known medications, mood trend. When a real provider exists,
/// the service will sanitize and redact PHI before sending.
class AiSuggestionRequest {
  final AiSuggestionKind kind;
  final String elderId;
  final String elderDisplayName;
  final Map<String, dynamic> context;

  const AiSuggestionRequest({
    required this.kind,
    required this.elderId,
    required this.elderDisplayName,
    this.context = const {},
  });
}

/// Response from the service. `available == false` means no provider is
/// configured yet — the UI should render the CTA as a disabled "Coming
/// soon" affordance. `suggestion` holds the generated draft text when
/// available; the caller decides whether to pre-fill, diff, or confirm.
class AiSuggestionResult {
  final bool available;
  final String? suggestion;
  final String? rationale;
  final String? errorMessage;

  const AiSuggestionResult._({
    required this.available,
    this.suggestion,
    this.rationale,
    this.errorMessage,
  });

  factory AiSuggestionResult.unavailable([String? reason]) =>
      AiSuggestionResult._(
        available: false,
        errorMessage: reason ??
            'AI-powered suggestions are coming soon. In the meantime, '
                'type from experience — you know them best.',
      );

  factory AiSuggestionResult.success(
    String suggestion, {
    String? rationale,
  }) =>
      AiSuggestionResult._(
        available: true,
        suggestion: suggestion,
        rationale: rationale,
      );

  factory AiSuggestionResult.error(String message) =>
      AiSuggestionResult._(available: true, errorMessage: message);
}

/// Contract that real providers implement. A future Gemini / Claude /
/// GPT-backed provider will replace the default `_UnavailableProvider`.
abstract class AiSuggestionProvider {
  /// True when the provider has credentials + network access and is ready
  /// to serve requests. UI can poll this before enabling the "Suggest"
  /// button to avoid an extra round-trip.
  bool get isAvailable;

  Future<AiSuggestionResult> generate(AiSuggestionRequest request);
}

/// Default no-op provider. Always returns `unavailable` — safe to ship.
class _UnavailableProvider implements AiSuggestionProvider {
  const _UnavailableProvider();

  @override
  bool get isAvailable => false;

  @override
  Future<AiSuggestionResult> generate(AiSuggestionRequest request) async {
    return AiSuggestionResult.unavailable();
  }
}

/// Singleton service. Injected by grabbing `AiSuggestionService.instance`.
/// Call `AiSuggestionService.configure(provider)` once at app startup when
/// a real provider is ready.
class AiSuggestionService {
  AiSuggestionService._();

  static final AiSuggestionService instance = AiSuggestionService._();

  AiSuggestionProvider _provider = const _UnavailableProvider();

  /// Swap in a real provider (e.g. a Cloud-Functions-backed LLM client).
  /// Idempotent — safe to call multiple times during hot-reload.
  static void configure(AiSuggestionProvider provider) {
    instance._provider = provider;
    if (kDebugMode) {
      debugPrint('AiSuggestionService.configure → ${provider.runtimeType}');
    }
  }

  /// True when a real provider is wired up and reachable.
  bool get isAvailable => _provider.isAvailable;

  /// Generic entry point used by all the section-specific helpers. Kept
  /// public so future features can add new kinds without touching the
  /// helper surface.
  Future<AiSuggestionResult> suggest(AiSuggestionRequest request) {
    try {
      return _provider.generate(request);
    } catch (e, s) {
      debugPrint('AiSuggestionService.suggest error: $e\n$s');
      return Future.value(AiSuggestionResult.error(e.toString()));
    }
  }

  // ---------------------------------------------------------------------------
  // Section-specific conveniences. UI calls these with the structured
  // context it already has on hand.
  // ---------------------------------------------------------------------------

  Future<AiSuggestionResult> suggestDailyRoutine({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.dailyRoutine,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  Future<AiSuggestionResult> suggestBehavioralTriggers({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.behavioralTriggers,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  Future<AiSuggestionResult> suggestCalmingTechniques({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.calmingTechniques,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  Future<AiSuggestionResult> suggestCommunicationTips({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.communicationTips,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  Future<AiSuggestionResult> suggestMedicationQuirks({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.medicationQuirks,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  Future<AiSuggestionResult> suggestPersonalHistory({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.personalHistory,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Draft an insurance appeal letter. [context] should include
  /// `carrier`, `claimNumber`, `provider`, `dateOfService`,
  /// `billedAmount`, `denialReason`, and the caregiver's
  /// `advocateName` for signing. Returns a plain-text draft the
  /// caregiver edits + mails — never auto-sends.
  Future<AiSuggestionResult> suggestAppealDraft({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.insuranceAppealDraft,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Polish a raw incident description into a professional compliance-
  /// ready narrative. [context] should include `type`, `severity`,
  /// `description`, `immediateActions`, `followUpPlan`, and
  /// `injuryDescription`. Returns a single paragraph draft the
  /// caregiver edits in the description field.
  Future<AiSuggestionResult> suggestIncidentNarrative({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.incidentNarrativeDraft,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Ask the AI to rank candidate support groups for best fit. [context]
  /// should include `primaryCondition`, preferred `format`, `language`,
  /// and optionally `timeWindow` (e.g. "weekday evenings"). Without a
  /// provider the UI falls back to the unfiltered directory.
  Future<AiSuggestionResult> suggestSupportGroupMatch({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.supportGroupMatch,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Ask the AI to scan a claims history for under-billing or pattern
  /// issues (repeat denials at one provider, benefit cap approaching,
  /// billing-code collisions). [context] should include a compact
  /// summary of recent claims + benefit counter state.
  Future<AiSuggestionResult> suggestCoverageInsight({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.insuranceCoverageInsight,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Ask the AI to turn a multi-day sleep rhythm into caregiver-facing
  /// guidance (bedtime-anchor, light therapy timing, nap-consolidation
  /// window). [context] should include `days` (list of per-day
  /// summaries), `averageFragmentation`, and `fragmentedNightsFollowedByBehavior`.
  Future<AiSuggestionResult> suggestSleepRhythmInsight({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.sleepRhythmInsight,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Ask the AI to synthesize a music-reaction pattern into a caregiver-
  /// facing recommendation. [context] should include recent entries
  /// (song, artist, decade, reaction, context) plus the computed
  /// insights summary. Returns a draft playlist + upcoming-window
  /// suggestion the UI renders alongside the rule-based insight card.
  Future<AiSuggestionResult> suggestMusicPattern({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.musicPatternInsight,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Ask the AI to turn a Zarit assessment into a short plain-language
  /// insight + suggested supports. [context] should include
  /// `itemScores` (`List<int>`), `total` (int), `personalStrain` (int),
  /// `roleStrain` (int), and optionally `history` (recent totals).
  /// Until a provider is wired, the caller gets an unavailable result
  /// and falls back to the rule-based guidance on `ZaritBurdenLevel`.
  Future<AiSuggestionResult> suggestZaritInsight({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.zaritBurdenInsight,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));

  /// Ask the AI to draft a taper schedule. [context] should include
  /// `medName`, `startingDose`, `doseUnit`, `reason`, and optionally
  /// `prescriberPreference` (e.g. "conservative", "standard"). The real
  /// provider will return a structured step list; until wired, the
  /// caller receives an unavailable result and falls back to presets.
  Future<AiSuggestionResult> suggestTaperSchedule({
    required String elderId,
    required String elderDisplayName,
    Map<String, dynamic> context = const {},
  }) =>
      suggest(AiSuggestionRequest(
        kind: AiSuggestionKind.taperSuggestion,
        elderId: elderId,
        elderDisplayName: elderDisplayName,
        context: context,
      ));
}
