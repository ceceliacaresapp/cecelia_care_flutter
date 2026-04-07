# Localization TODO

This file tracks user-facing English strings in newer screens that
haven't been wired through `AppLocalizations` yet. It exists because
extracting all of these in a single pass would either:

1. Force me to fabricate translations into es/ja/ko/zh (the project has 5
   locales — Flutter's gen-l10n complains if any locale is missing keys
   that exist in `app_en.arb`), or
2. Drop the strings into a halfway state where some screens are
   localized and others aren't, with no clear migration plan.

The right fix is a focused localization sprint: extract all the strings
listed below to ARB keys in one session, then send the English ARB to a
human translator for the other 4 locales. This file is the sprint plan.

## Audit summary (from explore agent, 2025-11)

| File | Hardcoded strings | Severity |
| ---- | ----------------- | -------- |
| `lib/screens/cognitive_assessment_screen.dart` | ~35 | HIGH |
| `lib/screens/discharge_checklist_screen.dart` | ~25 | MEDIUM-HIGH |
| `lib/screens/task_delegation_screen.dart` | ~20 | MEDIUM-HIGH |
| `lib/screens/forms/incontinence_form.dart` | ~15 | MEDIUM |
| `lib/screens/forms/visitor_form.dart` | ~12 | MEDIUM |
| `lib/screens/forms/night_waking_form.dart` | ~10 | MEDIUM |
| `lib/screens/forms/hydration_form.dart` | ~8 | LOW |
| **Total** | **~125** | |

## Suggested ARB key naming convention

Match the existing pattern:

```
{screenName}{ElementType}{Detail}
```

Examples:
- `cognitiveScreenTitle` → "Cognitive Screen"
- `cognitiveAssessmentEmptyTitle` → "No assessments yet"
- `cognitiveAssessmentEmptyHint` → "7 brain games — about 10–15 minutes."
- `cognitiveAssessmentSaveSuccess` → "Assessment saved"
- `cognitiveAssessmentSaveError` → "Save failed: {error}"
- `dischargeChecklistTitle` → "Discharge Plan"
- `taskBoardTitle` → "Task Board"

## Migration steps for a future session

1. Read each file in the table above and tag every user-facing English
   string literal (skip log messages, debug prints, and Firestore field
   names — those should stay in English).
2. Add a key to `lib/l10n/app_en.arb` for each tagged string with a
   `description` field explaining the context.
3. Run `flutter gen-l10n` to regenerate `AppLocalizations`.
4. Replace the inline strings with `AppLocalizations.of(context)!.foo`.
5. For each of `app_es.arb`, `app_ja.arb`, `app_ko.arb`, `app_zh.arb`,
   either send the new English keys to a translator OR add them with the
   English value as a placeholder so gen-l10n doesn't fail (Flutter's
   fallback behavior will use the English version automatically when a
   locale-specific value is missing).
6. Re-run `flutter analyze` to confirm no key is referenced before being
   added to `app_en.arb`.

## Strings already wired correctly

These existing forms are good examples of how the rest should look:

- `lib/screens/forms/pain_form.dart` — uses `_l10n.painFormLabelLocation`,
  `_l10n.painFormHintLocation`, etc.
- `lib/screens/forms/sleep_form.dart` — same pattern.
- `lib/screens/forms/mood_form.dart` — same pattern.

Each pulls `_l10n = AppLocalizations.of(context)!` in
`didChangeDependencies` and references it throughout `build()`.
