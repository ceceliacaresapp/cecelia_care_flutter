// lib/utils/entry_summary.dart
//
// Pure summary-extraction helper for journal entries. Takes the raw
// Firestore data map and returns a one-line human-readable summary.
//
// Lifted out of timeline_screen.dart so it can be unit-tested and reused
// from other screens (notifications, dashboard, etc.) without dragging in
// the timeline's massive state class.

import 'package:flutter/foundation.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';

/// Generates a one-line summary from a journal entry's data map.
///
/// All localized strings come through [l10n] so this function stays free
/// of any UI state.
String extractEntrySummary(
  Map<String, dynamic>? entryData,
  EntryType type,
  AppLocalizations l10n,
) {
  if (entryData == null || entryData.isEmpty) {
    return l10n.timelineSummaryDetailsUnavailable;
  }
  try {
    switch (type) {
      case EntryType.medication:
        final name =
            entryData['name'] as String? ?? l10n.timelineSummaryNotApplicable;
        final dose = entryData['dose'] as String? ?? '';
        final taken = entryData['taken'] as bool?;
        final status = taken == true
            ? l10n.timelineSummaryMedicationStatusTaken
            : taken == false
                ? l10n.timelineSummaryMedicationStatusNotTaken
                : '';
        return l10n
            .timelineSummaryMedicationFormat(name, dose, status)
            .trim();
      case EntryType.sleep:
        final duration = entryData['totalDuration'] as String? ??
            l10n.timelineSummaryNotApplicable;
        final qualityValue = entryData['quality']?.toString();
        final quality = (qualityValue != null && qualityValue.isNotEmpty)
            ? l10n.timelineSummarySleepQualityFormat(qualityValue)
            : '';
        final notes = entryData['notes'] as String? ?? '';
        return l10n.timelineSummarySleepFormat(duration, quality, notes);
      case EntryType.meal:
        final description = entryData['description'] as String? ??
            l10n.timelineSummaryNotApplicable;
        final caloriesValue = entryData['calories']?.toString();
        final calories = (caloriesValue != null && caloriesValue.isNotEmpty)
            ? l10n.timelineSummaryMealCaloriesFormat(caloriesValue)
            : '';
        return l10n.timelineSummaryMealFormat(description, calories);
      case EntryType.mood:
        final moodLevel = entryData['moodLevel']?.toString() ??
            l10n.timelineSummaryNotApplicable;
        final notesValue = entryData['note'] as String?;
        final notes = (notesValue != null && notesValue.isNotEmpty)
            ? l10n.timelineSummaryMoodNotesFormat(notesValue)
            : '';
        return l10n.timelineSummaryMoodFormat(moodLevel, notes);
      case EntryType.pain:
        // Prefer the new painPoints body-map data when present.
        final points = entryData['painPoints'] as List?;
        if (points != null && points.isNotEmpty) {
          final regions = <String>{};
          int peak = 0;
          for (final raw in points) {
            if (raw is Map) {
              final region = raw['bodyRegion']?.toString() ?? '';
              if (region.isNotEmpty) regions.add(region);
              final i = (raw['intensity'] as num?)?.toInt() ?? 0;
              if (i > peak) peak = i;
            }
          }
          final regionLabel = regions.length == 1
              ? regions.first
              : '${regions.length} locations';
          return '$regionLabel \u00B7 Peak $peak/10';
        }
        // Fallback for legacy text-only entries.
        final intensity = entryData['intensity']?.toString() ??
            l10n.timelineSummaryNotApplicable;
        final locationValue = entryData['location'] as String? ?? '';
        final location = locationValue.isNotEmpty
            ? l10n.timelineSummaryPainLocationFormat(locationValue)
            : '';
        return l10n.timelineSummaryPainFormat(intensity, location).trim();
      case EntryType.activity:
        final activityType = entryData['activityType'] as String? ??
            l10n.timelineItemTitleActivity;
        final durationValue = entryData['duration']?.toString() ?? '';
        final duration = durationValue.isNotEmpty
            ? l10n.timelineSummaryActivityDurationFormat(durationValue)
            : '';
        return l10n.timelineSummaryActivityFormat(activityType, duration);
      case EntryType.vital:
        final vitalType = entryData['vitalType'] as String? ?? '';
        final value = entryData['value'] as String? ??
            l10n.timelineSummaryNotApplicable;
        final unit = entryData['unit'] as String? ?? '';
        return l10n.timelineSummaryVitalFormatGeneric(vitalType, value, unit);
      case EntryType.expense:
        final category = entryData['category'] as String? ??
            l10n.timelineItemTitleExpense;
        final amount = entryData['amount']?.toString() ??
            l10n.timelineSummaryNotApplicable;
        final descriptionValue = entryData['description'] as String? ?? '';
        final description = descriptionValue.isNotEmpty
            ? l10n.timelineSummaryExpenseDescriptionFormat(descriptionValue)
            : '';
        return l10n
            .timelineSummaryExpenseFormat(category, amount, description)
            .trim();
      case EntryType.image:
        final title =
            entryData['title'] as String? ?? l10n.imageUploadDefaultTitle;
        return l10n.timelineSummaryImageFormat(title);
      case EntryType.caregiverJournal:
        return entryData['note'] as String? ?? l10n.noContent;
      case EntryType.handoff:
        final shift = entryData['shift'] as String?;
        final shiftPrefix =
            (shift != null && shift.isNotEmpty) ? '$shift shift — ' : '';
        final completed = entryData['completed'] as String? ?? '';
        final pending = entryData['pending'] as String? ?? '';
        final completedLines =
            completed.isNotEmpty ? completed.trim().split('\n').length : 0;
        final pendingLines =
            pending.isNotEmpty ? pending.trim().split('\n').length : 0;
        return '$shiftPrefix$completedLines task${completedLines == 1 ? '' : 's'} done, '
            '$pendingLines pending';
      case EntryType.incontinence:
        final iType = entryData['incontinenceType'] as String? ?? '';
        final severity = entryData['severity'] as String? ?? '';
        final skin = entryData['skinCondition'] as String? ?? '';
        final bristol = entryData['bristolType'] as int?;
        final urine = entryData['urineColor'] as String?;
        final typeLabel = iType.isNotEmpty
            ? '${iType[0].toUpperCase()}${iType.substring(1)}'
            : 'Logged';
        final sevLabel = severity.isNotEmpty ? ' \u00B7 $severity' : '';
        final bristolLabel =
            bristol != null ? ' \u00B7 Bristol $bristol' : '';
        final urineLabel = urine != null ? ' \u00B7 Urine: $urine' : '';
        final skinLabel = (skin == 'irritated' || skin == 'broken')
            ? ' \u00B7 Skin: $skin'
            : '';
        return '$typeLabel$sevLabel$bristolLabel$urineLabel$skinLabel';
      case EntryType.visitor:
        final name = entryData['visitorName'] as String? ?? 'Unknown';
        final relationship = entryData['relationship'] as String? ?? '';
        final duration = entryData['duration'] as String? ?? '';
        final response = entryData['response'] as String? ?? '';
        final relLabel =
            relationship.isNotEmpty ? ' ($relationship)' : '';
        final respLabel = response.isNotEmpty
            ? ' \u00B7 ${response[0].toUpperCase()}${response.substring(1)}'
            : '';
        final durLabel = duration.isNotEmpty ? ' \u00B7 $duration' : '';
        return '$name$relLabel$durLabel$respLabel';
      case EntryType.nightWaking:
        final duration = entryData['duration'] as String? ?? '';
        final cause = entryData['cause'] as String? ?? 'Unknown';
        final returned = entryData['returnedToSleep'] as bool? ?? false;
        final causeLabel = cause.isNotEmpty
            ? '${cause[0].toUpperCase()}${cause.substring(1)}'
            : 'Unknown';
        return '$causeLabel \u00B7 $duration \u00B7 ${returned ? 'Returned to sleep' : 'Did not return'}';
      case EntryType.hydration:
        final volume = entryData['volume']?.toString() ?? '';
        final unit = entryData['unit'] as String? ?? 'oz';
        final fluidType = entryData['fluidType'] as String? ?? '';
        final typeLabel = fluidType.isNotEmpty
            ? '${fluidType[0].toUpperCase()}${fluidType.substring(1)}'
            : 'Fluid';
        return '$typeLabel \u00B7 $volume $unit';
      case EntryType.custom:
        // Build summary from custom field values, skipping metadata keys
        const metaKeys = {
          'customTypeId',
          'customTypeName',
          'customTypeColor',
          'customTypeIcon',
          'elderId',
          'date',
          'loggedByUserId',
          'loggedBy',
          'updatedAt',
          'isPublic',
          'visibleToUserIds',
          'text',
        };
        final parts = <String>[];
        for (final key in entryData.keys) {
          if (metaKeys.contains(key)) continue;
          final val = entryData[key];
          if (val != null && val.toString().isNotEmpty && val != false) {
            parts.add(val.toString());
          }
        }
        return parts.isNotEmpty
            ? parts.join(' · ')
            : entryData['text'] as String? ?? l10n.timelineNoDetailsProvided;
      default:
        return entryData['text'] as String? ?? l10n.timelineNoDetailsProvided;
    }
  } catch (e, s) {
    debugPrint(
        "Error in extractEntrySummary for type '${type.name}': $e");
    debugPrint('Stack trace: $s');
    return l10n.timelineSummaryErrorProcessing;
  }
}
