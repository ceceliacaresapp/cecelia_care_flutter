// lib/models/rescue_med.dart
//
// Static reference data for common rescue medications. This is read-only
// reference content for emergencies — it is NOT prescribing advice. Caregivers
// should always follow the prescribing physician's instructions and call 911.

import 'package:flutter/material.dart';

class RescueMed {
  final String id;
  final String name;
  final String indication;
  final String route;
  final List<String> steps;
  final String warning;
  final IconData icon;
  final Color color;

  const RescueMed({
    required this.id,
    required this.name,
    required this.indication,
    required this.route,
    required this.steps,
    required this.warning,
    required this.icon,
    required this.color,
  });
}

const List<RescueMed> kRescueMeds = [
  RescueMed(
    id: 'epipen',
    name: 'EpiPen (Epinephrine)',
    indication: 'Severe allergic reaction (anaphylaxis)',
    route: 'Intramuscular — outer thigh',
    icon: Icons.vaccines_outlined,
    color: Color(0xFFE53935),
    steps: [
      'Remove the blue safety cap.',
      'Press the orange tip firmly against the middle of the outer thigh (through clothing is OK).',
      'Hold in place for 10 seconds.',
      'Massage the injection area for 10 seconds.',
      'Call 911 immediately. Tell dispatch: "anaphylaxis, epinephrine given."',
      'Note the time given. A second dose may be needed in 5–15 minutes if symptoms persist.',
    ],
    warning:
        'Always call 911 even if symptoms improve — biphasic reactions can occur hours later. Never inject into a vein, buttock, fingers, toes, hands, or feet.',
  ),
  RescueMed(
    id: 'glucagon',
    name: 'Glucagon',
    indication: 'Severe hypoglycemia (unconscious or unable to swallow)',
    route: 'Injection (thigh/arm/buttock) or nasal (Baqsimi)',
    icon: Icons.bloodtype_outlined,
    color: Color(0xFFD81B60),
    steps: [
      'Call 911 first.',
      'Injectable: mix the powder with the diluent in the kit, then inject the full dose into the thigh, arm, or buttock.',
      'Nasal (Baqsimi): insert tip into one nostril and press the plunger fully. No need to inhale.',
      'Turn the person on their side (recovery position) — vomiting is common.',
      'When alert and able to swallow, give a fast-acting carb (juice, glucose tab) followed by a snack.',
    ],
    warning:
        'Do NOT give food or drink to an unconscious person. Effects last only 60–90 minutes — follow-up care is essential.',
  ),
  RescueMed(
    id: 'diastat',
    name: 'Diastat (Diazepam Rectal Gel)',
    indication: 'Prolonged or cluster seizures (>5 minutes)',
    route: 'Rectal',
    icon: Icons.flash_on_outlined,
    color: Color(0xFF8E24AA),
    steps: [
      'Note the start time of the seizure.',
      'Position the person on their side, facing you.',
      'Remove the cap, lubricate the rectal tip, and gently insert.',
      'Push the plunger fully to deliver the prescribed dose. Hold in place for 3 seconds.',
      'Hold buttocks together for a few seconds to prevent leakage.',
      'Stay with the person. Note the time the dose was given.',
    ],
    warning:
        'Call 911 if the seizure continues >5 minutes after the dose, if breathing is impaired, if the person is injured, or if seizures cluster. Do NOT restrain or put anything in their mouth.',
  ),
  RescueMed(
    id: 'narcan',
    name: 'Narcan (Naloxone)',
    indication: 'Suspected opioid overdose',
    route: 'Nasal spray (or IM injection)',
    icon: Icons.healing_outlined,
    color: Color(0xFF1E88E5),
    steps: [
      'Call 911 first. Tell dispatch: "suspected opioid overdose."',
      'Lay the person on their back. Tilt the head back and support the neck.',
      'Insert the nozzle into one nostril until your fingers touch the bottom of the nose.',
      'Press the plunger firmly to give the full dose.',
      'If no response in 2–3 minutes, give a second dose in the other nostril.',
      'Place in the recovery position (on their side) and stay until EMS arrives.',
    ],
    warning:
        'Naloxone wears off in 30–90 minutes — overdose symptoms can return. EMS evaluation is required. Rescue breaths may be needed if breathing is absent or very slow.',
  ),
  RescueMed(
    id: 'albuterol',
    name: 'Rescue Inhaler (Albuterol)',
    indication: 'Acute asthma or COPD attack — wheezing, shortness of breath',
    route: 'Inhaled (with spacer if available)',
    icon: Icons.air_outlined,
    color: Color(0xFF00897B),
    steps: [
      'Sit the person upright. Stay calm and reassure them.',
      'Shake the inhaler well. Attach a spacer if available.',
      'Have the person exhale fully, away from the inhaler.',
      'Press the canister and have them inhale slowly and deeply.',
      'Hold the breath for 10 seconds, then exhale.',
      'Wait 1 minute, then repeat for a second puff. Up to 3 puffs.',
    ],
    warning:
        'Call 911 if there is no improvement after 3 puffs, if lips/fingers turn blue, if speech is broken into single words, or if the person is using neck/chest muscles to breathe.',
  ),
  RescueMed(
    id: 'nitroglycerin',
    name: 'Nitroglycerin',
    indication: 'Chest pain / angina',
    route: 'Sublingual (under the tongue)',
    icon: Icons.favorite_outline,
    color: Color(0xFFE65100),
    steps: [
      'Have the person sit or lie down — nitroglycerin can cause dizziness.',
      'Place one tablet under the tongue. Do NOT chew or swallow.',
      'Wait 5 minutes. If chest pain continues, call 911.',
      'A second tablet may be given 5 minutes after the first.',
      'A third tablet may be given 5 minutes after the second.',
      'Maximum 3 tablets in 15 minutes.',
    ],
    warning:
        'Call 911 immediately if chest pain is not relieved 5 minutes after the FIRST tablet. Do NOT give if the person has taken erectile-dysfunction medication (sildenafil, tadalafil) in the last 24–48 hours — severe blood pressure drop can occur.',
  ),
];
