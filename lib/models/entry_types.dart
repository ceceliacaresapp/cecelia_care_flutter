/// Represents a field within an entry type that can be filled by voice.
///
/// This class defines the "contract" for a single piece of data we want the AI to extract.
class EntryField {
  /// The programmatic key for this field (e.g., 'pain-location').
  /// This MUST match the parameter name in Dialogflow.
  final String key;

  /// The human-readable label for the field (used for UI elements).
  final String label;

  /// Whether this field is required for a valid entry.
  final bool isRequired;

  /// A description to help the AI understand what kind of information to extract.
  /// This can be used for generating prompts or for fine-tuning the AI model.
  final String? descriptionForAI;

  const EntryField(
    this.key,
    this.label, {
    this.isRequired = true,
    this.descriptionForAI,
  });
}

/// Defines the schema for a specific journal entry type, including all its fields.
class EntrySchema {
  /// The name of the entry type (e.g., "Pain", "Meal"). This corresponds to the
  /// Dialogflow Intent name.
  final String type;

  /// A list of all fields that belong to this entry type.
  final List<EntryField> fields;

  const EntrySchema(this.type, this.fields);
}

/// A centralized list of predefined schemas for all voice-enabled entry types.
///
/// This list is the single source of truth for the "contract" between the Flutter app
/// and the Dialogflow agent. The `key` for each field is intentionally in kebab-case
/// (e.g., 'pain-location') to match standard Dialogflow parameter naming conventions.
const List<EntrySchema> entrySchemas = <EntrySchema>[
  EntrySchema('Pain', [
    EntryField(
      'pain-location',
      'Location',
      isRequired: true,
      descriptionForAI:
          'Specific body part where the pain is felt. Examples: Head, back, stomach, knee, left arm, neck, lower back.',
    ),
    EntryField(
      'pain-intensity',
      'Intensity (1-10)',
      isRequired: true,
      descriptionForAI:
          'Numeric scale for pain from 1 (mild) to 10 (severe). Extract ONLY an integer. Keywords: scale of, level, intensity.',
    ),
    EntryField(
      'pain-description',
      'Description of Pain',
      isRequired: true,
      descriptionForAI:
          'Qualitative description of the pain. Match to one of: Aching, Burning, Dull, Sharp, Shooting, Stabbing, Throbbing, Tender.',
    ),
    EntryField(
      'pain-note',
      'Notes (optional)',
      isRequired: false,
      descriptionForAI:
          'Any additional details or the original transcribed sentence about the pain.',
    ),
  ]),
  EntrySchema('Meal', [
    EntryField(
      'meal-description',
      'Description / Amount',
      isRequired: true,
      descriptionForAI:
          'For Food, describe items (e.g., "Chicken sandwich"). For Water, specify amount (e.g., "250ml", "1 glass").',
    ),
    EntryField(
      'meal-calories',
      'Calories (optional)',
      isRequired: false,
      descriptionForAI: 'Estimated calorie count. Extract ONLY an integer.',
    ),
    EntryField(
      'meal-note',
      'Notes (optional)',
      isRequired: false,
      descriptionForAI: 'Any additional notes about the food or drink.',
    ),
  ]),
  EntrySchema('Mood', [
    EntryField(
      'mood-level',
      'Overall Mood',
      isRequired: true,
      descriptionForAI: 'The dominant mood level from 1-5.',
    ),
    EntryField(
      'mood-note',
      'Notes (optional)',
      isRequired: false,
      descriptionForAI: 'General notes about the mood or its context.',
    ),
  ]),
  EntrySchema('Medication', [
    EntryField(
        'medication-name', 'Medication Name', isRequired: true,
        descriptionForAI:
            'The name of the medication. Keywords: meds, medicine, drug, pill, tablet, Tylenol, aspirin, ibuprofen, melatonin.'),
    EntryField('medication-dosage', 'Dosage (e.g., 500mg)',
        isRequired: true, descriptionForAI: 'The dosage taken. Keywords: dose.'),
  ]),
  EntrySchema('Sleep', [
    EntryField('sleep-duration', 'Sleep Duration in Hours (optional)',
        isRequired: false,
        descriptionForAI:
            'Total sleep duration in hours (e.g., 7.5). Provide ONLY a number (can be decimal).'),
    EntryField('sleep-quality', 'Sleep Quality (1-5)',
        isRequired: false,
        descriptionForAI:
            'Rate sleep quality on a scale of 1 (poor) to 5 (excellent). Provide ONLY an integer number.'),
    EntryField('sleep-note', 'Notes (optional)',
        isRequired: false,
        descriptionForAI:
            'Any additional notes about sleep. Keywords: slept well, bad night, restless sleep.'),
  ]),
  EntrySchema('Activity', [
    EntryField('activity-type', 'Activity Description',
        isRequired: true,
        descriptionForAI:
            'Description of the activity. Examples: Walk, Exercise, Physical Therapy, Social Visit, Reading, Watching TV.'),
    EntryField('activity-duration', 'Duration (minutes)',
        isRequired: false,
        descriptionForAI:
            'Duration of the activity in minutes. Provide ONLY an integer number.'),
    EntryField('activity-note', 'Notes (optional)',
        isRequired: false,
        descriptionForAI: 'Any additional notes about the activity.'),
  ]),
  EntrySchema('Expense', [
    EntryField('expense-description', 'Expense Description',
        isRequired: true,
        descriptionForAI:
            'Description of the expense. Keywords: bought, paid for, spent on.'),
    EntryField('expense-amount', 'Amount',
        isRequired: true,
        descriptionForAI:
            'Amount spent. Provide ONLY a number (can be decimal). Do not include currency symbols. Keywords: cost, price, total.'),
    EntryField('expense-category', 'Category',
        isRequired: true,
        descriptionForAI:
            'Category of the expense. Examples: Medical, Groceries, Supplies, Household, Personal Care, Other.'),
    EntryField('expense-note', 'Notes (optional)',
        isRequired: false,
        descriptionForAI: 'Any additional notes about the expense.'),
  ]),
  EntrySchema('Vital', [
    EntryField('vital-type', 'Vital Type',
        isRequired: true,
        descriptionForAI:
            'Description of the vital. Examples: Heart Rate, Blood Pressure, Temperature, Weight, Oxygen Saturation, Blood Glucose.'),
    EntryField('vital-value', 'Vital Value',
        isRequired: true,
        descriptionForAI:
            'Value of the vital measurement. Can be a number (e.g., 70, 98.6) or a string for compound values like Blood Pressure (e.g., "120/80").'),
    EntryField('vital-note', 'Vital Notes (optional)',
        isRequired: false,
        descriptionForAI:
            'Any additional notes about the vital measurement.'),
  ]),
  EntrySchema('Calendar Event', [
    EntryField('calendar-event-title', 'Event Title',
        isRequired: true,
        descriptionForAI:
            'Title of the calendar event. Keywords: schedule, create an appointment for, remind me to.'),
    EntryField('calendar-event-start-time', 'Start Time',
        isRequired: true,
        descriptionForAI: 'Start time of the calendar event. e.g.,YYYY-MM-DDTHH:mm:ss'),
    EntryField('calendar-event-end-time', 'End Time',
        isRequired: false,
        descriptionForAI: 'End time of the calendar event. e.g.,YYYY-MM-DDTHH:mm:ss'),
    EntryField('calendar-event-all-day', 'All Day Event?',
        isRequired: true,
        descriptionForAI:
            'Is this an all-day event? Respond with ONLY the boolean true or false.'),
  ]),
  EntrySchema('Message', [
    EntryField('message-text', 'Message Text',
        isRequired: true,
        descriptionForAI:
            'The content of a message to be posted on the timeline.'),
  ]),
  // FIX: Added a schema for the caregiver journal entry
  EntrySchema('Caregiver Journal', [
    EntryField('caregiver-journal-note', 'Note',
        isRequired: true,
        descriptionForAI:
            'The content of a private caregiver journal entry.'),
  ]),
  EntrySchema('Handoff Note', [
    EntryField('handoff-shift', 'Shift',
        isRequired: false,
        descriptionForAI:
            'Which shift this handoff covers: Morning, Afternoon, Evening, or Overnight.'),
    EntryField('handoff-completed', 'Tasks Completed',
        isRequired: true,
        descriptionForAI:
            'What was done during this shift — meds given, meals served, activities, etc.'),
    EntryField('handoff-pending', 'Tasks Pending',
        isRequired: true,
        descriptionForAI:
            'What still needs to be done by the next caregiver.'),
    EntryField('handoff-concerns', 'Concerns / Notes',
        isRequired: true,
        descriptionForAI:
            'Anything the next caregiver should know — mood changes, pain complaints, visitors expected.'),
  ]),
];

/// A standardized enum for all journal entry types used in the app.
enum EntryType {
  message,
  medication,
  sleep,
  meal,
  mood,
  pain,
  activity,
  vital,
  expense,
  image,
  calendarEvent,
  caregiverJournal, // FIX: Added the missing enum member
  handoff,
  custom,
  unknown; // A fallback for safety

  /// Creates an EntryType from a string, ignoring case.
  /// Defaults to 'unknown' if the string doesn't match any known type.
  static EntryType fromString(String? typeString) {
    if (typeString == null) {
      return EntryType.unknown;
    }
    // Standardize the string for matching
    final lowercasedType = typeString.toLowerCase().replaceAll(' ', '');

    for (EntryType type in EntryType.values) {
      if (type.name.toLowerCase() == lowercasedType) {
        return type;
      }
    }
    
    // Handle plural 'expenses' from old schema if necessary
    if (lowercasedType == 'expenses') {
      return EntryType.expense;
    }
    // Handle alternate spellings stored in Firestore
    if (lowercasedType == 'handoffnote') {
      return EntryType.handoff;
    }
    if (lowercasedType == 'custom') {
      return EntryType.custom;
    }

    return EntryType.unknown;
  }
}
