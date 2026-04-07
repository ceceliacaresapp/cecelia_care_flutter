// lib/models/disease_roadmap.dart
//
// Static educational data for disease progression roadmaps. NOT clinical
// advice — written for caregivers to understand what to expect, what to
// prepare for, and what to ask the doctor at each stage.

import 'package:flutter/material.dart';

class DiseaseStage {
  final int number;
  final String title;
  final String duration;
  final String whatToExpect;
  final List<String> signs;
  final List<String> prepareFor;
  final List<String> doctorQuestions;
  final List<String> caregiverTips;

  const DiseaseStage({
    required this.number,
    required this.title,
    required this.duration,
    required this.whatToExpect,
    required this.signs,
    required this.prepareFor,
    required this.doctorQuestions,
    required this.caregiverTips,
  });
}

class DiseaseRoadmap {
  final String id;
  final String name;
  final String overview;
  final IconData icon;
  final Color color;
  final List<DiseaseStage> stages;

  const DiseaseRoadmap({
    required this.id,
    required this.name,
    required this.overview,
    required this.icon,
    required this.color,
    required this.stages,
  });

  static const List<DiseaseRoadmap> all = [
    _alzheimers,
    _parkinsons,
    _als,
    _chf,
  ];
}

// ── Alzheimer's (Global Deterioration Scale, 7 stages) ──────────────

const _alzheimers = DiseaseRoadmap(
  id: 'alzheimers',
  name: "Alzheimer's Disease",
  overview:
      'A progressive brain disease that gradually impairs memory, thinking, and behavior. The most common cause of dementia.',
  icon: Icons.psychology_outlined,
  color: Color(0xFF6A1B9A),
  stages: [
    DiseaseStage(
      number: 1,
      title: 'No Impairment',
      duration: 'Baseline',
      whatToExpect:
          'Normal function. No memory problems noticeable to the person, family, or doctor.',
      signs: ['Normal day-to-day function', 'No noticeable cognitive changes'],
      prepareFor: [
        'Establish baseline cognitive testing if there is family history',
        'Discuss family medical history with primary care doctor',
      ],
      doctorQuestions: [
        'Are there any early screening tools you recommend?',
        'What lifestyle factors lower dementia risk?',
      ],
      caregiverTips: [
        'Encourage brain-healthy habits: exercise, social engagement, sleep',
        'Document family medical history for future reference',
      ],
    ),
    DiseaseStage(
      number: 2,
      title: 'Very Mild Decline',
      duration: 'Variable',
      whatToExpect:
          'Minor memory lapses — forgetting familiar words or where objects are. Often consistent with normal aging.',
      signs: [
        'Forgetting familiar words',
        'Misplacing keys, glasses, wallet',
        'Symptoms not noticed by coworkers or family',
      ],
      prepareFor: [
        'Start a journal to track memory concerns over time',
        'Begin organizing important documents',
      ],
      doctorQuestions: [
        'Should we schedule a cognitive assessment?',
        'Are these changes typical for age?',
      ],
      caregiverTips: [
        'Avoid alarming the person — these symptoms may be normal',
        'Encourage routines and reminder systems',
      ],
    ),
    DiseaseStage(
      number: 3,
      title: 'Mild Decline (Early-Stage)',
      duration: '2–7 years',
      whatToExpect:
          'Friends and family begin to notice changes. Word-finding difficulty, getting lost in familiar places, declining work performance.',
      signs: [
        'Trouble finding the right word in conversation',
        'Forgetting names of new acquaintances',
        'Losing or misplacing valuable objects',
        'Decline in planning or organizing',
        'Repeating questions',
      ],
      prepareFor: [
        'Get legal documents in order: will, healthcare proxy, POA',
        'Discuss diagnosis openly while the person can participate',
        'Begin financial planning for long-term care',
        'Research adult day programs and support groups',
      ],
      doctorQuestions: [
        'What tests confirm an Alzheimer\'s diagnosis?',
        'Are there medications that can slow progression?',
        'Should we see a neurologist or memory specialist?',
        'What clinical trials might be appropriate?',
      ],
      caregiverTips: [
        'Help maintain calendars and reminder lists',
        'Encourage continued social engagement',
        'Avoid arguing about memory mistakes — redirect gently',
      ],
    ),
    DiseaseStage(
      number: 4,
      title: 'Moderate Decline',
      duration: '2–4 years',
      whatToExpect:
          'Difficulty with finances, complex tasks, recent events, and travel. The person may withdraw from challenging situations.',
      signs: [
        'Trouble managing money and bills',
        'Difficulty with complex tasks like cooking',
        'Forgetting recent events or personal history',
        'Becoming withdrawn or moody in social situations',
      ],
      prepareFor: [
        'Driving evaluation — most need to stop driving',
        'Home safety assessment (stove shut-offs, locks, lighting)',
        'Form a care team — family, friends, possibly paid help',
        'Discuss advance directives and wishes for future care',
      ],
      doctorQuestions: [
        'When should driving stop?',
        'What home safety changes do you recommend?',
        'How do we manage behavioral changes?',
        'What signs mean we need more help at home?',
      ],
      caregiverTips: [
        'Take over financial management',
        'Simplify daily choices (lay out clothes, limit menu options)',
        'Establish a calm, predictable daily routine',
      ],
    ),
    DiseaseStage(
      number: 5,
      title: 'Moderately Severe Decline',
      duration: '1.5 years',
      whatToExpect:
          'Major memory gaps. Help needed with choosing clothes and daily activities. Confusion about time, place, and recent events.',
      signs: [
        'Cannot recall address, phone number, or year',
        'Confused about where they are or what day it is',
        'Needs help selecting season-appropriate clothing',
        'Still remembers own name and family',
      ],
      prepareFor: [
        'Arrange in-home care or adult day program',
        'Create memory aids — labels, photos, communication cards',
        'Establish a structured daily routine',
        'Plan for caregiver respite — burnout starts here',
      ],
      doctorQuestions: [
        'How do we handle agitation and sundowning?',
        'What medications help with sleep or anxiety?',
        'When is memory care or assisted living appropriate?',
      ],
      caregiverTips: [
        'Lay out clothes in the order they\'re put on',
        'Use simple yes/no questions, not open-ended ones',
        'Keep a familiar environment — minimize moves and changes',
      ],
    ),
    DiseaseStage(
      number: 6,
      title: 'Severe Decline (Mid-Stage)',
      duration: '2.5 years',
      whatToExpect:
          'Personality and behavior changes. Needs extensive help with daily activities. May not recognize family. Wandering and incontinence common.',
      signs: [
        'Needs help with bathing, dressing, toileting',
        'Doesn\'t recognize close family at times',
        'Wandering and getting lost',
        'Personality changes — suspicion, hallucinations, agitation',
        'Disrupted sleep cycles',
      ],
      prepareFor: [
        'Incontinence supplies and skin-care routine',
        'Wandering safeguards: door alarms, ID bracelet, GPS',
        'Respite care — caregiver health is critical now',
        'Discuss memory-care facility options',
      ],
      doctorQuestions: [
        'How do we manage hallucinations or delusions?',
        'Is medication helpful for severe agitation?',
        'When should we consider residential care?',
        'How do we keep them safe from wandering?',
      ],
      caregiverTips: [
        'Use simple instructions, one step at a time',
        'Validate emotions rather than correcting facts',
        'Watch for UTIs — they often cause sudden worsening',
      ],
    ),
    DiseaseStage(
      number: 7,
      title: 'Very Severe Decline (Late-Stage)',
      duration: '1.5–2.5 years',
      whatToExpect:
          'Loses ability to respond to environment, carry on conversation, and eventually control movement. Needs full assistance with all care.',
      signs: [
        'Limited or no speech',
        'Loss of ability to walk, sit, or smile',
        'Difficulty swallowing',
        'Vulnerable to infections, especially pneumonia',
      ],
      prepareFor: [
        'Hospice evaluation and comfort-care plan',
        'Family support and bereavement resources',
        'Decisions about feeding tubes and aggressive treatment',
        'Plan for end-of-life rituals and wishes',
      ],
      doctorQuestions: [
        'Is hospice appropriate now?',
        'What are signs the end of life is near?',
        'How do we manage pain and discomfort?',
        'What do we do if there is a sudden change?',
      ],
      caregiverTips: [
        'Focus on comfort: gentle touch, soft music, familiar voices',
        'Watch for signs of pain — grimacing, restlessness, moaning',
        'Allow family members to say goodbye in their own way',
      ],
    ),
  ],
);

// ── Parkinson's (Hoehn & Yahr, 5 stages) ────────────────────────────

const _parkinsons = DiseaseRoadmap(
  id: 'parkinsons',
  name: "Parkinson's Disease",
  overview:
      'A progressive movement disorder caused by loss of dopamine-producing brain cells. Affects movement, balance, and sometimes thinking.',
  icon: Icons.accessibility_new_outlined,
  color: Color(0xFF1565C0),
  stages: [
    DiseaseStage(
      number: 1,
      title: 'Stage 1 — Mild, One Side',
      duration: 'Several years',
      whatToExpect:
          'Symptoms appear on only one side of the body. Tremor or stiffness is mild and does not interfere with daily life.',
      signs: [
        'Tremor in one hand at rest',
        'Slight changes in posture or facial expression',
        'Subtle changes in handwriting (smaller)',
      ],
      prepareFor: [
        'Establish care with a movement-disorder specialist',
        'Start a regular exercise program — proven to slow progression',
        'Get baseline assessments done',
      ],
      doctorQuestions: [
        'When should we start medication?',
        'What kind of exercise is most helpful?',
        'Are there clinical trials we could join?',
      ],
      caregiverTips: [
        'Encourage daily exercise — walking, swimming, dance, boxing',
        'Help track symptom changes for doctor visits',
      ],
    ),
    DiseaseStage(
      number: 2,
      title: 'Stage 2 — Both Sides Affected',
      duration: 'Months to years',
      whatToExpect:
          'Symptoms now affect both sides of the body. Walking and posture changes appear. Daily tasks become harder but the person can still live alone.',
      signs: [
        'Tremor or stiffness on both sides',
        'Slower movements (bradykinesia)',
        'Speech becoming softer or monotone',
        'Stooped posture',
      ],
      prepareFor: [
        'Medication routine — timing is critical',
        'Voice and physical therapy referrals',
        'Plan for future home modifications',
      ],
      doctorQuestions: [
        'How do we time medications for best effect?',
        'Should we see a speech therapist (LSVT LOUD)?',
        'What side effects should we watch for?',
      ],
      caregiverTips: [
        'Set medication alarms — timing matters more than for most drugs',
        'Encourage loud speaking and big movements (LSVT therapy)',
        'Watch for "off" periods when medication wears off',
      ],
    ),
    DiseaseStage(
      number: 3,
      title: 'Stage 3 — Balance Impaired',
      duration: 'Variable',
      whatToExpect:
          'Loss of balance and slowness of movements. Falls become common. Still independent but daily activities are significantly restricted.',
      signs: [
        'Falls and near-falls',
        'Difficulty with fine motor tasks (buttons, utensils)',
        'Slow getting out of chairs',
        'Freezing of gait — feet feel "stuck"',
      ],
      prepareFor: [
        'Fall prevention — remove rugs, install grab bars, good lighting',
        'Physical therapy for balance training',
        'Discuss driving limitations',
        'Adaptive utensils and dressing aids',
      ],
      doctorQuestions: [
        'Are we due for a deep brain stimulation evaluation?',
        'How can we manage freezing episodes?',
        'When is it unsafe to drive?',
      ],
      caregiverTips: [
        'Teach "cueing" tricks for freezing — count steps, march in place',
        'Allow extra time for everything — don\'t rush',
        'Watch for orthostatic hypotension when standing up',
      ],
    ),
    DiseaseStage(
      number: 4,
      title: 'Stage 4 — Severe Disability',
      duration: 'Variable',
      whatToExpect:
          'Symptoms severely limit daily activities. Person can still stand and walk with help but cannot live alone. Needs assistance with most activities.',
      signs: [
        'Cannot live alone safely',
        'Needs help with bathing, dressing, eating',
        'Risk of cognitive decline and hallucinations',
        'Significant medication-related fluctuations',
      ],
      prepareFor: [
        'In-home care or assisted living',
        'Wheelchair or walker for safety',
        'Discuss advance directives',
        'Caregiver respite — burnout is a real risk',
      ],
      doctorQuestions: [
        'How do we manage hallucinations or confusion?',
        'When should we consider hospice or palliative care?',
        'Are there support groups for advanced Parkinson\'s caregivers?',
      ],
      caregiverTips: [
        'Build the day around medication timing',
        'Keep a fall log to share with the doctor',
        'Take care of yourself — accept help',
      ],
    ),
    DiseaseStage(
      number: 5,
      title: 'Stage 5 — Wheelchair / Bed-Bound',
      duration: 'Variable',
      whatToExpect:
          'Bedridden or wheelchair-bound unless aided. Around-the-clock care needed. Person may experience hallucinations or delusions.',
      signs: [
        'Cannot stand or walk without help',
        '24-hour care needed',
        'Difficulty swallowing',
        'Possible dementia',
      ],
      prepareFor: [
        'Hospice or palliative care evaluation',
        'Hospital bed and pressure-relief mattress',
        'Communication devices if speech is lost',
        'Family support and bereavement planning',
      ],
      doctorQuestions: [
        'Is hospice appropriate?',
        'How do we prevent pressure sores?',
        'What can we do for swallowing safety?',
      ],
      caregiverTips: [
        'Reposition every 2 hours to prevent skin breakdown',
        'Thickened liquids may be needed for safe swallowing',
        'Provide gentle range-of-motion exercises',
      ],
    ),
  ],
);

// ── ALS (3 phases) ──────────────────────────────────────────────────

const _als = DiseaseRoadmap(
  id: 'als',
  name: 'ALS (Lou Gehrig\'s Disease)',
  overview:
      'A progressive motor neuron disease causing muscle weakness and loss of voluntary movement. Cognition is usually preserved.',
  icon: Icons.accessible_outlined,
  color: Color(0xFFD84315),
  stages: [
    DiseaseStage(
      number: 1,
      title: 'Early Phase',
      duration: 'Months to 1 year',
      whatToExpect:
          'Muscle weakness or stiffness in one area — often a hand, foot, or speech. Diagnosis period; many tests rule out other causes.',
      signs: [
        'Tripping, dropping things, or hand weakness',
        'Slurred speech or trouble swallowing',
        'Muscle twitching (fasciculations)',
        'Cramps and stiffness',
      ],
      prepareFor: [
        'Get to an ALS-certified clinic — multidisciplinary care matters',
        'Start legal and financial planning early',
        'Apply for disability benefits — it takes time',
        'Connect with the ALS Association',
      ],
      doctorQuestions: [
        'What clinical trials are available?',
        'Should we start riluzole or edaravone?',
        'How quickly might my symptoms progress?',
        'Where is the nearest ALS-certified clinic?',
      ],
      caregiverTips: [
        'Help organize medical records and appointments',
        'Encourage open conversation about wishes early',
        'Document goals and values while speech is intact',
      ],
    ),
    DiseaseStage(
      number: 2,
      title: 'Middle Phase',
      duration: 'Variable, often 1–2 years',
      whatToExpect:
          'Weakness becomes widespread. Speech, swallowing, breathing, and mobility all decline. Adaptive equipment becomes essential.',
      signs: [
        'Cannot walk without aid',
        'Speech is hard to understand',
        'Choking or coughing during meals',
        'Shortness of breath, especially lying down',
        'Significant weight loss',
      ],
      prepareFor: [
        'Wheelchair, communication device, hospital bed',
        'Feeding tube discussion (PEG)',
        'Non-invasive ventilation (BiPAP) for nighttime',
        'Home accessibility modifications',
        'Caregiver training and respite plan',
      ],
      doctorQuestions: [
        'When should we consider a feeding tube?',
        'When should we start BiPAP?',
        'What communication options are there once speech is lost?',
        'How do we prevent aspiration pneumonia?',
      ],
      caregiverTips: [
        'Learn to use the suction machine and cough assist device',
        'Practice patience with communication — never finish their sentences',
        'Pre-program common phrases into communication apps',
      ],
    ),
    DiseaseStage(
      number: 3,
      title: 'Late Phase',
      duration: 'Months',
      whatToExpect:
          'Almost all voluntary muscles are paralyzed. Breathing becomes severely compromised. Most communication is through eye movement or assistive technology.',
      signs: [
        'Cannot move limbs voluntarily',
        'Cannot speak; communicates by eyes or device',
        'Severe shortness of breath',
        'Total dependence for all care',
      ],
      prepareFor: [
        'Decision about invasive ventilation (tracheostomy)',
        'Hospice referral and palliative care',
        'Family support and bereavement counseling',
        'Final wishes and end-of-life planning',
      ],
      doctorQuestions: [
        'What does the dying process look like in ALS?',
        'How do we manage air hunger and anxiety?',
        'What medications keep them comfortable?',
        'How long can we expect at this stage?',
      ],
      caregiverTips: [
        'Maintain eye contact and conversation — cognition is intact',
        'Use morphine and anti-anxiety meds as prescribed for comfort',
        'Honor their wishes about hospital vs. home',
      ],
    ),
  ],
);

// ── CHF / Heart Failure (NYHA 4 classes) ────────────────────────────

const _chf = DiseaseRoadmap(
  id: 'chf',
  name: 'Heart Failure (CHF)',
  overview:
      'A chronic condition where the heart cannot pump blood efficiently. Symptoms are graded by the New York Heart Association (NYHA) into 4 classes.',
  icon: Icons.favorite_outline,
  color: Color(0xFFC62828),
  stages: [
    DiseaseStage(
      number: 1,
      title: 'Class I — No Limitation',
      duration: 'Indefinite with management',
      whatToExpect:
          'No symptoms with normal activity. The person feels fine but has a diagnosis or risk factors for heart failure.',
      signs: [
        'No fatigue or shortness of breath with usual activity',
        'May only be detected on echocardiogram',
      ],
      prepareFor: [
        'Heart-healthy diet (low sodium)',
        'Regular exercise as tolerated',
        'Daily weight monitoring',
        'Medication adherence',
      ],
      doctorQuestions: [
        'What is my ejection fraction?',
        'What sodium limit should I follow?',
        'What weight gain should trigger a call?',
        'Should I see a heart-failure specialist?',
      ],
      caregiverTips: [
        'Help establish a daily weigh-in routine',
        'Track sodium intake with the food log',
        'Encourage regular exercise',
      ],
    ),
    DiseaseStage(
      number: 2,
      title: 'Class II — Slight Limitation',
      duration: 'Variable',
      whatToExpect:
          'Comfortable at rest. Ordinary activity (climbing stairs, brisk walking) causes fatigue, palpitations, or shortness of breath.',
      signs: [
        'Tires more easily than peers',
        'Mild shortness of breath with stairs',
        'Occasional ankle swelling',
        'Sleeping with extra pillows',
      ],
      prepareFor: [
        'Strict sodium limit (typically <2g/day)',
        'Daily weight log — call doctor if up >3 lbs in 2 days',
        'Medication routine with reminders',
        'Cardiac rehab program',
      ],
      doctorQuestions: [
        'Are my medications optimized?',
        'Should I be on a diuretic?',
        'How much fluid should I drink each day?',
        'When do I need to come in vs. wait?',
      ],
      caregiverTips: [
        'Watch for early signs of fluid retention',
        'Keep a low-sodium grocery list',
        'Help track daily weights and report jumps',
      ],
    ),
    DiseaseStage(
      number: 3,
      title: 'Class III — Marked Limitation',
      duration: 'Variable',
      whatToExpect:
          'Comfortable at rest but minimal activity (walking across a room) causes symptoms. Frequent hospital visits become more common.',
      signs: [
        'Shortness of breath with minimal activity',
        'Persistent ankle and leg swelling',
        'Cannot lie flat without coughing',
        'Frequent ER or hospital admissions',
      ],
      prepareFor: [
        'Home health nurse visits',
        'Discuss palliative care — symptom relief, not just treatment',
        'Update advance directives and DNR wishes',
        'Plan for caregiver support — frequent hospital trips',
      ],
      doctorQuestions: [
        'Are we candidates for a heart pump or transplant?',
        'When should we consider palliative care?',
        'What are signs of an emergency vs. wait-and-see?',
        'Do you recommend a cardiology palliative team?',
      ],
      caregiverTips: [
        'Keep a "go bag" ready for hospital trips',
        'Elevate legs when sitting; head of bed up at night',
        'Watch for confusion — can mean low oxygen',
      ],
    ),
    DiseaseStage(
      number: 4,
      title: 'Class IV — Severe Limitation',
      duration: 'Months',
      whatToExpect:
          'Symptoms present even at rest. Any activity causes discomfort. Often hospice-eligible. Focus shifts to comfort and quality of life.',
      signs: [
        'Short of breath at rest',
        'Severe swelling in legs, abdomen, sometimes lungs',
        'Profound fatigue',
        'Confusion from poor blood flow',
      ],
      prepareFor: [
        'Hospice referral',
        'Comfort-focused medications (morphine for air hunger)',
        'Family support and end-of-life planning',
        'Discuss what hospitalization adds vs. comfort at home',
      ],
      doctorQuestions: [
        'Is hospice appropriate now?',
        'What can we expect in the final days?',
        'How do we manage breathlessness at home?',
        'What should we call about vs. accept?',
      ],
      caregiverTips: [
        'Use a fan near the face — relieves air hunger',
        'Sit upright with pillows to ease breathing',
        'Allow loved ones time to say goodbye',
      ],
    ),
  ],
);
