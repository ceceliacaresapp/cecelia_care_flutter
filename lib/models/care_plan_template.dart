// lib/models/care_plan_template.dart
//
// Data model for pre-built care plan templates. Each template contains a
// list of TemplateItems that get converted to CalendarEvents when applied.
//
// Templates are hardcoded — no Firestore collection needed for v1.
// Can be migrated to a remote config or Firestore later for OTA updates.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// TemplateItem — a single scheduled event within a care plan
// ---------------------------------------------------------------------------
class TemplateItem {
  final String title;
  final String? notes;
  final String eventType; // maps to CalendarEvent.eventType
  final String timeOfDay; // 24h format 'HH:mm'
  final int durationMinutes;
  final String? recurrenceRule; // 'daily', 'weekly', 'monthly', or null
  final bool allDay;

  const TemplateItem({
    required this.title,
    this.notes,
    this.eventType = 'other',
    required this.timeOfDay,
    this.durationMinutes = 30,
    this.recurrenceRule = 'daily',
    this.allDay = false,
  });
}

// ---------------------------------------------------------------------------
// CarePlanTemplate — the template container
// ---------------------------------------------------------------------------
class CarePlanTemplate {
  final String id;
  final String name;
  final String description;
  final String conditionTag;
  final IconData icon;
  final Color color;
  final List<TemplateItem> items;
  final int defaultDurationDays;

  const CarePlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.conditionTag,
    required this.icon,
    required this.color,
    required this.items,
    this.defaultDurationDays = 30,
  });
}

// ---------------------------------------------------------------------------
// Hardcoded template library
// ---------------------------------------------------------------------------
const List<CarePlanTemplate> carePlanTemplates = [
  // ─── 1. Alzheimer's / Dementia Daily Care ───────────────────────
  CarePlanTemplate(
    id: 'alzheimers_daily',
    name: "Alzheimer's / Dementia Care",
    description:
        'Structured daily routine with cognitive activities, meal schedules, '
        'and sundowning prevention for dementia patients.',
    conditionTag: 'dementia',
    icon: Icons.psychology_outlined,
    color: Color(0xFF8E24AA),
    defaultDurationDays: 30,
    items: [
      TemplateItem(
        title: 'Morning routine check',
        notes: 'Assist with hygiene, dressing, and orientation. '
            'Greet warmly and confirm the date/day.',
        eventType: 'other',
        timeOfDay: '07:00',
        durationMinutes: 45,
      ),
      TemplateItem(
        title: 'Breakfast + morning meds',
        notes: 'Serve familiar foods. Verify all morning medications taken.',
        eventType: 'medication_reminder',
        timeOfDay: '08:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Cognitive stimulation',
        notes: 'Puzzles, photo albums, music therapy, or reminiscence '
            'activity. Keep sessions short (20-30 min).',
        eventType: 'activity',
        timeOfDay: '10:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Lunch',
        notes: 'Simple, nutrient-dense meal. Monitor fluid intake.',
        eventType: 'other',
        timeOfDay: '12:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Afternoon walk / exercise',
        notes: 'Gentle exercise reduces agitation. Stay in familiar areas. '
            '15-20 minutes is sufficient.',
        eventType: 'activity',
        timeOfDay: '14:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Snack + hydration check',
        notes: 'Offer water/juice and a light snack. Dehydration worsens confusion.',
        eventType: 'other',
        timeOfDay: '15:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Sundowning prevention activity',
        notes: 'Start calming activities before late afternoon. Close curtains, '
            'reduce noise, play soft music. Redirect if agitated.',
        eventType: 'activity',
        timeOfDay: '16:30',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Dinner',
        notes: 'Serve dinner early. Avoid caffeine and sugar.',
        eventType: 'other',
        timeOfDay: '18:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Evening medication',
        notes: 'Administer evening medications. Confirm swallowed.',
        eventType: 'medication_reminder',
        timeOfDay: '19:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Calming activity / music',
        notes: 'Familiar music, gentle hand massage, or reading aloud. '
            'Avoid screens close to bedtime.',
        eventType: 'activity',
        timeOfDay: '20:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Bedtime routine',
        notes: 'Assist with hygiene, pajamas, and settling in. '
            'Use nightlights for safety. Check door/window locks.',
        eventType: 'other',
        timeOfDay: '21:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Overnight safety check',
        notes: 'Verify bed rails, nightlights on, doors secured. '
            'Check if awake or wandering.',
        eventType: 'other',
        timeOfDay: '23:00',
        durationMinutes: 15,
      ),
    ],
  ),

  // ─── 2. Post-Surgery Recovery ───────────────────────────────────
  CarePlanTemplate(
    id: 'post_surgery',
    name: 'Post-Surgery Recovery',
    description:
        'Wound care, pain monitoring, medication schedule, and physical '
        'therapy for recovering surgical patients.',
    conditionTag: 'post-surgery',
    icon: Icons.healing_outlined,
    color: Color(0xFFE53935),
    defaultDurationDays: 14,
    items: [
      TemplateItem(
        title: 'Morning pain assessment',
        notes: 'Rate pain 1-10. Note location and character. '
            'Log in app for doctor review.',
        eventType: 'other',
        timeOfDay: '08:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Morning medication',
        notes: 'Administer prescribed pain meds and antibiotics on schedule. '
            'Take with food if directed.',
        eventType: 'medication_reminder',
        timeOfDay: '08:30',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Wound care check',
        notes: 'Inspect incision site for redness, swelling, drainage, or odor. '
            'Change dressing per surgeon instructions. Take photo for tracking.',
        eventType: 'other',
        timeOfDay: '09:00',
        durationMinutes: 20,
      ),
      TemplateItem(
        title: 'Physical therapy exercises',
        notes: 'Follow prescribed exercises. Start gentle — stop if sharp pain. '
            'Log duration and any difficulty.',
        eventType: 'activity',
        timeOfDay: '10:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Lunch + fluid intake',
        notes: 'High-protein meal for healing. Track fluid intake — aim for 8+ cups/day.',
        eventType: 'other',
        timeOfDay: '12:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Afternoon pain assessment',
        notes: 'Rate pain again. Compare to morning. Adjust position for comfort.',
        eventType: 'other',
        timeOfDay: '14:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Afternoon medication',
        notes: 'Midday dose if prescribed. Do not skip antibiotics.',
        eventType: 'medication_reminder',
        timeOfDay: '14:30',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Gentle movement',
        notes: 'Short walk or standing exercises to prevent blood clots. '
            '5-10 minutes, with assistance if needed.',
        eventType: 'activity',
        timeOfDay: '16:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Evening medication',
        notes: 'Evening dose of pain meds and antibiotics.',
        eventType: 'medication_reminder',
        timeOfDay: '20:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Evening pain assessment',
        notes: 'Final pain check. Ensure comfortable sleeping position. '
            'Set up pillows for elevation if required.',
        eventType: 'other',
        timeOfDay: '21:00',
        durationMinutes: 15,
      ),
    ],
  ),

  // ─── 3. Hospice / Palliative Care ──────────────────────────────
  CarePlanTemplate(
    id: 'hospice',
    name: 'Hospice / Palliative Care',
    description:
        'Comfort-focused care with pain management, repositioning schedule, '
        'and emotional support for end-of-life care.',
    conditionTag: 'hospice',
    icon: Icons.spa_outlined,
    color: Color(0xFF5C6BC0),
    defaultDurationDays: 30,
    items: [
      TemplateItem(
        title: 'Morning comfort assessment',
        notes: 'Assess pain level, comfort, breathing, and skin integrity. '
            'Note any overnight changes.',
        eventType: 'other',
        timeOfDay: '08:00',
        durationMinutes: 20,
      ),
      TemplateItem(
        title: 'Morning medication',
        notes: 'Administer comfort medications. Ensure pain is managed before care.',
        eventType: 'medication_reminder',
        timeOfDay: '08:30',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Mouth care',
        notes: 'Gently swab mouth with moist sponge. Apply lip balm. '
            'Even if not eating, mouth care prevents discomfort.',
        eventType: 'other',
        timeOfDay: '09:00',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Repositioning',
        notes: 'Turn every 2 hours to prevent pressure sores. '
            'Use pillows for support. Check skin at each turn.',
        eventType: 'other',
        timeOfDay: '10:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Emotional / spiritual check-in',
        notes: 'Sit with patient. Read, play music, or simply hold hands. '
            'Ask about comfort and wishes. Contact chaplain if requested.',
        eventType: 'social',
        timeOfDay: '11:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Midday repositioning + comfort check',
        notes: 'Reposition, check skin, assess pain. Offer small sips if able to swallow.',
        eventType: 'other',
        timeOfDay: '12:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Afternoon medication',
        notes: 'Scheduled comfort meds. Report any breakthrough pain to hospice nurse.',
        eventType: 'medication_reminder',
        timeOfDay: '14:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Family visit coordination',
        notes: 'Coordinate family visits. Prepare the space — quiet, comfortable, '
            'private. Brief visitors on patient status.',
        eventType: 'social',
        timeOfDay: '15:00',
        durationMinutes: 60,
        recurrenceRule: 'weekly',
      ),
      TemplateItem(
        title: 'Evening comfort routine',
        notes: 'Evening medications, mouth care, repositioning. '
            'Dim lights, play soft music. Ensure room is peaceful.',
        eventType: 'other',
        timeOfDay: '20:00',
        durationMinutes: 30,
      ),
    ],
  ),

  // ─── 4. General Elder Care ──────────────────────────────────────
  CarePlanTemplate(
    id: 'general_elder',
    name: 'General Care',
    description:
        'Basic daily routine for any care recipient — meals, medications, '
        'activity, and check-ins. A great starting template.',
    conditionTag: 'general',
    icon: Icons.favorite_outline,
    color: Color(0xFF00897B),
    defaultDurationDays: 30,
    items: [
      TemplateItem(
        title: 'Morning check-in',
        notes: 'How did they sleep? Any pain or discomfort? Check mood.',
        eventType: 'other',
        timeOfDay: '08:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Breakfast + morning meds',
        notes: 'Prepare breakfast. Administer morning medications with food.',
        eventType: 'medication_reminder',
        timeOfDay: '08:30',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Morning hydration',
        notes: 'Offer water, juice, or tea. Aim for 8 cups throughout the day.',
        eventType: 'other',
        timeOfDay: '10:00',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Daily walk / activity',
        notes: 'Gentle exercise appropriate to ability. '
            'Walking, stretching, or chair exercises.',
        eventType: 'activity',
        timeOfDay: '10:30',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Lunch',
        notes: 'Balanced meal. Note appetite and any dietary concerns.',
        eventType: 'other',
        timeOfDay: '12:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Afternoon hydration',
        notes: 'Another glass of water or juice.',
        eventType: 'other',
        timeOfDay: '14:00',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Social / leisure time',
        notes: 'Phone call with family, TV, reading, crafts, or games.',
        eventType: 'social',
        timeOfDay: '15:00',
        durationMinutes: 60,
      ),
      TemplateItem(
        title: 'Dinner',
        notes: 'Evening meal. Lighter portions if preferred.',
        eventType: 'other',
        timeOfDay: '18:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Evening meds',
        notes: 'Administer evening medications.',
        eventType: 'medication_reminder',
        timeOfDay: '20:00',
        durationMinutes: 15,
      ),
      TemplateItem(
        title: 'Bedtime routine',
        notes: 'Assist with hygiene, pajamas, and settling in for the night.',
        eventType: 'other',
        timeOfDay: '21:00',
        durationMinutes: 30,
      ),
    ],
  ),

  // ─── 5. Diabetes Management ─────────────────────────────────────
  CarePlanTemplate(
    id: 'diabetes',
    name: 'Diabetes Management',
    description:
        'Blood glucose monitoring, insulin/medication schedule, meal planning, '
        'foot care, and exercise for diabetic patients.',
    conditionTag: 'diabetes',
    icon: Icons.bloodtype_outlined,
    color: Color(0xFFF57C00),
    defaultDurationDays: 30,
    items: [
      TemplateItem(
        title: 'Fasting blood glucose check',
        notes: 'Check blood sugar before breakfast. Log reading in vitals. '
            'Target range per doctor orders (typically 80-130 mg/dL).',
        eventType: 'other',
        timeOfDay: '07:00',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Breakfast + insulin/meds',
        notes: 'Balanced meal with controlled carbs. Administer insulin or '
            'oral medication as prescribed.',
        eventType: 'medication_reminder',
        timeOfDay: '07:30',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Daily foot inspection',
        notes: 'Check both feet for cuts, blisters, redness, swelling, or sores. '
            'Report any changes immediately. Moisturize but not between toes.',
        eventType: 'other',
        timeOfDay: '08:30',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Exercise',
        notes: 'At least 30 min of moderate activity. Walking, swimming, or '
            'chair exercises. Check blood sugar before and after if on insulin.',
        eventType: 'activity',
        timeOfDay: '10:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Pre-lunch blood glucose check',
        notes: 'Check blood sugar before lunch. Log reading.',
        eventType: 'other',
        timeOfDay: '11:45',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Lunch',
        notes: 'Controlled-carb meal. Track portions. '
            'Include vegetables and lean protein.',
        eventType: 'other',
        timeOfDay: '12:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Afternoon snack',
        notes: 'Small snack if needed to prevent hypoglycemia. '
            'Cheese, nuts, or fruit with protein.',
        eventType: 'other',
        timeOfDay: '15:00',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Pre-dinner blood glucose check',
        notes: 'Check blood sugar before dinner. Log reading.',
        eventType: 'other',
        timeOfDay: '17:45',
        durationMinutes: 10,
      ),
      TemplateItem(
        title: 'Dinner + evening meds',
        notes: 'Balanced dinner. Administer evening insulin or oral meds.',
        eventType: 'medication_reminder',
        timeOfDay: '18:00',
        durationMinutes: 30,
      ),
      TemplateItem(
        title: 'Bedtime blood glucose check',
        notes: 'Final reading of the day. Target per doctor orders '
            '(typically 100-140 mg/dL). Have a small snack if low.',
        eventType: 'other',
        timeOfDay: '22:00',
        durationMinutes: 10,
      ),
    ],
  ),
];
