// lib/models/glossary_term.dart
//
// Static medical-glossary reference. Plain-language definitions written for
// non-clinical caregivers — not textbook definitions. No backend.

class GlossaryTerm {
  final String term;
  final String definition;
  final String category; // 'general' | 'vitals' | 'medications' | 'conditions' | 'procedures' | 'care'

  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.category,
  });
}

const List<GlossaryTerm> kGlossaryTerms = [
  // ── A ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Acute', definition: 'Sudden and severe. An acute illness comes on quickly, as opposed to chronic (long-lasting).', category: 'general'),
  GlossaryTerm(term: 'ADL (Activities of Daily Living)', definition: 'Basic self-care tasks: bathing, dressing, eating, toileting, transferring, and continence. Used to measure how much help someone needs.', category: 'care'),
  GlossaryTerm(term: 'Advance Directive', definition: 'A legal document stating a person\'s wishes for medical care if they can\'t speak for themselves. Includes living wills and healthcare proxies.', category: 'care'),
  GlossaryTerm(term: 'Adverse Reaction', definition: 'An unwanted or harmful response to a medication or treatment.', category: 'medications'),
  GlossaryTerm(term: 'Agitation', definition: 'Restlessness, irritability, or excessive movement. Common in dementia, especially in late afternoon (sundowning).', category: 'conditions'),
  GlossaryTerm(term: 'Allergy', definition: 'An immune system reaction to a substance most people tolerate. Can range from mild rash to life-threatening anaphylaxis.', category: 'conditions'),
  GlossaryTerm(term: 'Alzheimer\'s Disease', definition: 'The most common cause of dementia. A progressive brain disease affecting memory, thinking, and behavior.', category: 'conditions'),
  GlossaryTerm(term: 'Ambulation', definition: 'Walking. "Ambulatory" means able to walk; "non-ambulatory" means cannot walk.', category: 'care'),
  GlossaryTerm(term: 'Anaphylaxis', definition: 'A severe, rapid, life-threatening allergic reaction. Treated with epinephrine (EpiPen). Always call 911.', category: 'conditions'),
  GlossaryTerm(term: 'Anemia', definition: 'Low red blood cell count. Causes fatigue, weakness, and shortness of breath.', category: 'conditions'),
  GlossaryTerm(term: 'Angina', definition: 'Chest pain caused by reduced blood flow to the heart. Often a warning sign of heart disease.', category: 'conditions'),
  GlossaryTerm(term: 'Anticoagulant', definition: 'A blood thinner (like warfarin or apixaban). Prevents clots but increases bleeding risk.', category: 'medications'),
  GlossaryTerm(term: 'Antibiotic', definition: 'A medication that kills bacteria. Does not work on viruses like the common cold.', category: 'medications'),
  GlossaryTerm(term: 'Aphasia', definition: 'Difficulty speaking or understanding language, often after a stroke.', category: 'conditions'),
  GlossaryTerm(term: 'Arrhythmia', definition: 'An irregular heartbeat — too fast, too slow, or uneven.', category: 'conditions'),
  GlossaryTerm(term: 'Arthritis', definition: 'Inflammation of the joints causing pain and stiffness.', category: 'conditions'),
  GlossaryTerm(term: 'Aspiration', definition: 'When food, liquid, or saliva goes into the lungs instead of the stomach. Common in dementia patients with swallowing difficulty. Can cause pneumonia.', category: 'conditions'),
  GlossaryTerm(term: 'Atrophy', definition: 'Wasting away or shrinking of muscle or tissue, often from disuse.', category: 'conditions'),

  // ── B ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Bedsore (Pressure Ulcer)', definition: 'A skin injury caused by prolonged pressure, often on the back, hips, heels, or tailbone. Prevent by repositioning every 2 hours.', category: 'conditions'),
  GlossaryTerm(term: 'Beta-blocker', definition: 'A medication that slows the heart rate and lowers blood pressure (e.g. metoprolol).', category: 'medications'),
  GlossaryTerm(term: 'BMI (Body Mass Index)', definition: 'A weight-to-height ratio used to estimate body fat.', category: 'vitals'),
  GlossaryTerm(term: 'BP (Blood Pressure)', definition: 'The force of blood pushing against artery walls. Recorded as systolic/diastolic, e.g. 120/80.', category: 'vitals'),
  GlossaryTerm(term: 'Bradycardia', definition: 'Heart rate below 60 beats per minute. May be caused by medications like beta-blockers.', category: 'vitals'),
  GlossaryTerm(term: 'BPM (Beats Per Minute)', definition: 'A measurement of heart rate.', category: 'vitals'),

  // ── C ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Cardiac', definition: 'Relating to the heart.', category: 'general'),
  GlossaryTerm(term: 'Catheter', definition: 'A thin tube inserted into the body, often into the bladder to drain urine.', category: 'procedures'),
  GlossaryTerm(term: 'Cellulitis', definition: 'A bacterial skin infection causing redness, swelling, warmth, and pain. Needs antibiotics.', category: 'conditions'),
  GlossaryTerm(term: 'Chronic', definition: 'Long-lasting or recurring, as opposed to acute (sudden).', category: 'general'),
  GlossaryTerm(term: 'CNA (Certified Nursing Assistant)', definition: 'A trained caregiver who helps with bathing, dressing, feeding, and basic care under nurse supervision.', category: 'care'),
  GlossaryTerm(term: 'Cognitive', definition: 'Related to thinking, memory, and reasoning.', category: 'general'),
  GlossaryTerm(term: 'Comorbidity', definition: 'Having two or more medical conditions at the same time, like diabetes and heart disease.', category: 'general'),
  GlossaryTerm(term: 'Congestive Heart Failure (CHF)', definition: 'A condition where the heart can\'t pump blood well, causing fluid buildup in the lungs and legs.', category: 'conditions'),
  GlossaryTerm(term: 'Constipation', definition: 'Difficulty passing stool. Common with low fiber, dehydration, and certain pain medications.', category: 'conditions'),
  GlossaryTerm(term: 'Contraindication', definition: 'A reason a medication or procedure should NOT be used (e.g. an allergy or risky drug interaction).', category: 'medications'),
  GlossaryTerm(term: 'COPD', definition: 'Chronic Obstructive Pulmonary Disease. Long-term lung disease causing shortness of breath. Includes emphysema and chronic bronchitis.', category: 'conditions'),
  GlossaryTerm(term: 'CPR (Cardiopulmonary Resuscitation)', definition: 'Chest compressions and rescue breaths used when someone\'s heart stops.', category: 'procedures'),

  // ── D ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Dehydration', definition: 'Not enough fluid in the body. In elders, it can cause confusion, dizziness, and falls.', category: 'conditions'),
  GlossaryTerm(term: 'Delirium', definition: 'A sudden change in mental state — confusion, agitation, hallucinations. Often caused by infection (especially UTI), medications, or dehydration.', category: 'conditions'),
  GlossaryTerm(term: 'Dementia', definition: 'A decline in memory and thinking severe enough to interfere with daily life. Alzheimer\'s is the most common cause.', category: 'conditions'),
  GlossaryTerm(term: 'Diabetes', definition: 'A condition where the body can\'t properly regulate blood sugar.', category: 'conditions'),
  GlossaryTerm(term: 'Diagnosis', definition: 'The medical name for what is wrong.', category: 'general'),
  GlossaryTerm(term: 'Diastolic', definition: 'The bottom number of a blood pressure reading. Pressure when the heart rests between beats.', category: 'vitals'),
  GlossaryTerm(term: 'Diuretic', definition: 'A "water pill" that makes the body get rid of extra fluid (e.g. furosemide/Lasix).', category: 'medications'),
  GlossaryTerm(term: 'DNR (Do Not Resuscitate)', definition: 'A medical order that CPR should not be performed if the person\'s heart stops.', category: 'care'),
  GlossaryTerm(term: 'Dyspnea', definition: 'Shortness of breath; feeling unable to get enough air.', category: 'conditions'),
  GlossaryTerm(term: 'Dysphagia', definition: 'Difficulty swallowing. Common in late-stage dementia and after strokes. May require thickened liquids.', category: 'conditions'),

  // ── E ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Edema', definition: 'Swelling caused by fluid buildup, usually in the legs and ankles. Can indicate heart or kidney problems.', category: 'conditions'),
  GlossaryTerm(term: 'EKG / ECG', definition: 'Electrocardiogram. A test that records the heart\'s electrical activity.', category: 'procedures'),
  GlossaryTerm(term: 'Embolism', definition: 'A blockage in a blood vessel, often from a clot.', category: 'conditions'),
  GlossaryTerm(term: 'Epinephrine', definition: 'The medication in an EpiPen. Used for severe allergic reactions (anaphylaxis).', category: 'medications'),
  GlossaryTerm(term: 'Etiology', definition: 'The cause or origin of a disease.', category: 'general'),

  // ── F ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Fall Risk', definition: 'A label given to someone at increased risk of falling. Triggers extra precautions like bed alarms or non-slip socks.', category: 'care'),
  GlossaryTerm(term: 'Fasting', definition: 'Going without food (and sometimes liquid). Often required before blood tests or surgery.', category: 'general'),
  GlossaryTerm(term: 'Foley Catheter', definition: 'A urinary catheter that stays in the bladder, draining into a bag.', category: 'procedures'),
  GlossaryTerm(term: 'Fracture', definition: 'A broken bone.', category: 'conditions'),

  // ── G ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Gait', definition: 'The way a person walks. "Unsteady gait" is a fall risk.', category: 'care'),
  GlossaryTerm(term: 'Gait Belt', definition: 'A safety belt worn around the waist to help a caregiver support someone while walking or transferring.', category: 'care'),
  GlossaryTerm(term: 'Geriatric', definition: 'Relating to older adults and the medical care of older adults.', category: 'general'),
  GlossaryTerm(term: 'Glucose', definition: 'Blood sugar.', category: 'vitals'),
  GlossaryTerm(term: 'Glucagon', definition: 'An emergency medication for severe low blood sugar in someone who can\'t eat or drink.', category: 'medications'),

  // ── H ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Hematoma', definition: 'A collection of blood outside a blood vessel — basically a deep bruise.', category: 'conditions'),
  GlossaryTerm(term: 'Hemorrhage', definition: 'Heavy bleeding.', category: 'conditions'),
  GlossaryTerm(term: 'HIPAA', definition: 'Federal law protecting the privacy of health information. Requires authorization before sharing medical records.', category: 'general'),
  GlossaryTerm(term: 'Hospice', definition: 'Comfort-focused care for someone with a terminal illness, typically with a life expectancy of 6 months or less. Focuses on quality of life, not curing the disease.', category: 'care'),
  GlossaryTerm(term: 'Hypertension', definition: 'High blood pressure.', category: 'conditions'),
  GlossaryTerm(term: 'Hypotension', definition: 'Low blood pressure. Can cause dizziness and falls, especially when standing up (orthostatic hypotension).', category: 'conditions'),
  GlossaryTerm(term: 'Hyperglycemia', definition: 'High blood sugar.', category: 'conditions'),
  GlossaryTerm(term: 'Hypoglycemia', definition: 'Low blood sugar. Can cause shakiness, confusion, sweating, and (if severe) loss of consciousness.', category: 'conditions'),

  // ── I ───────────────────────────────────────────────────
  GlossaryTerm(term: 'IADL (Instrumental Activities of Daily Living)', definition: 'More complex daily tasks: managing money, cooking, shopping, taking medications, using the phone.', category: 'care'),
  GlossaryTerm(term: 'Incontinence', definition: 'Loss of bladder or bowel control.', category: 'conditions'),
  GlossaryTerm(term: 'Infection', definition: 'When germs invade the body and cause illness.', category: 'conditions'),
  GlossaryTerm(term: 'Inflammation', definition: 'The body\'s response to injury or infection — redness, swelling, warmth, and pain.', category: 'general'),
  GlossaryTerm(term: 'Insulin', definition: 'A hormone (and medication) that controls blood sugar in diabetes.', category: 'medications'),
  GlossaryTerm(term: 'Intramuscular (IM)', definition: 'Injected into a muscle (e.g. EpiPen into the thigh).', category: 'medications'),
  GlossaryTerm(term: 'Intravenous (IV)', definition: 'Given directly into a vein.', category: 'medications'),

  // ── L ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Lethargy', definition: 'Unusual sluggishness or drowsiness.', category: 'conditions'),
  GlossaryTerm(term: 'Living Will', definition: 'A legal document describing the medical care a person wants if they can\'t communicate.', category: 'care'),

  // ── M ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Medicare', definition: 'Federal health insurance for people 65+ or with certain disabilities.', category: 'care'),
  GlossaryTerm(term: 'Medicaid', definition: 'State and federal program providing health coverage for people with limited income, including long-term care.', category: 'care'),
  GlossaryTerm(term: 'Metastasis', definition: 'When cancer spreads from where it started to other parts of the body.', category: 'conditions'),
  GlossaryTerm(term: 'MRI', definition: 'Magnetic Resonance Imaging. A scan that uses magnets to make detailed pictures of the body.', category: 'procedures'),

  // ── N ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Naloxone (Narcan)', definition: 'An emergency medication that reverses opioid overdose.', category: 'medications'),
  GlossaryTerm(term: 'Nebulizer', definition: 'A machine that turns liquid medicine into a mist for breathing in. Used for asthma and COPD.', category: 'procedures'),
  GlossaryTerm(term: 'Nephrology', definition: 'The medical specialty that deals with kidneys.', category: 'general'),
  GlossaryTerm(term: 'Neuropathy', definition: 'Nerve damage causing numbness, tingling, or pain — often in hands and feet. Common in diabetes.', category: 'conditions'),
  GlossaryTerm(term: 'NPO', definition: 'Nothing by mouth. A doctor\'s order meaning the patient should not eat or drink, usually before a procedure.', category: 'care'),

  // ── O ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Occupational Therapy (OT)', definition: 'Therapy that helps people regain skills for daily living after illness or injury.', category: 'care'),
  GlossaryTerm(term: 'Opioid', definition: 'A strong pain medication (e.g. morphine, oxycodone). Carries overdose and addiction risks.', category: 'medications'),
  GlossaryTerm(term: 'Orthostatic Hypotension', definition: 'A drop in blood pressure when standing up, causing dizziness and increasing fall risk.', category: 'conditions'),
  GlossaryTerm(term: 'Osteoporosis', definition: 'Weakening of the bones, making fractures more likely.', category: 'conditions'),
  GlossaryTerm(term: 'Oxygen Saturation (SpO2)', definition: 'The percentage of oxygen in the blood. Normal is typically 95-100%.', category: 'vitals'),

  // ── P ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Palliative', definition: 'Care focused on relieving symptoms and improving quality of life, not curing the disease. Can be provided alongside curative treatment.', category: 'care'),
  GlossaryTerm(term: 'Parkinson\'s Disease', definition: 'A progressive brain disorder causing tremors, stiffness, and balance problems.', category: 'conditions'),
  GlossaryTerm(term: 'Pneumonia', definition: 'A lung infection. Especially dangerous in elders and those with swallowing problems.', category: 'conditions'),
  GlossaryTerm(term: 'POA (Power of Attorney)', definition: 'A legal authority for one person to make decisions for another. Healthcare POA covers medical decisions.', category: 'care'),
  GlossaryTerm(term: 'POLST', definition: 'Physician Orders for Life-Sustaining Treatment. A medical form documenting end-of-life wishes.', category: 'care'),
  GlossaryTerm(term: 'Polypharmacy', definition: 'Taking multiple medications, common in elders. Increases risk of drug interactions.', category: 'medications'),
  GlossaryTerm(term: 'Pressure Ulcer', definition: 'See Bedsore. A skin injury from prolonged pressure.', category: 'conditions'),
  GlossaryTerm(term: 'PRN', definition: 'As needed. A medication taken only when symptoms occur, not on a regular schedule.', category: 'medications'),
  GlossaryTerm(term: 'Prognosis', definition: 'The expected outcome or course of a disease.', category: 'general'),
  GlossaryTerm(term: 'PT (Physical Therapy)', definition: 'Therapy to improve strength, balance, and movement after injury or illness.', category: 'care'),
  GlossaryTerm(term: 'Pulse Oximeter', definition: 'A clip-on finger device that measures oxygen levels and pulse.', category: 'procedures'),

  // ── R ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Range of Motion (ROM)', definition: 'How far a joint can move. ROM exercises keep joints flexible.', category: 'care'),
  GlossaryTerm(term: 'Recovery Position', definition: 'Lying on the side with the top knee bent. Used for unconscious people who are breathing — keeps the airway clear.', category: 'procedures'),
  GlossaryTerm(term: 'Rehabilitation (Rehab)', definition: 'Care that helps someone recover function after illness, injury, or surgery.', category: 'care'),
  GlossaryTerm(term: 'Renal', definition: 'Relating to the kidneys.', category: 'general'),
  GlossaryTerm(term: 'Respiration Rate', definition: 'How many breaths per minute. Normal adult: 12–20.', category: 'vitals'),
  GlossaryTerm(term: 'Respite Care', definition: 'Short-term care for a loved one so the primary caregiver can rest.', category: 'care'),

  // ── S ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Sepsis', definition: 'A life-threatening response to infection. Symptoms include fever, fast heart rate, confusion, and low blood pressure. Requires emergency care.', category: 'conditions'),
  GlossaryTerm(term: 'Side Effect', definition: 'An unwanted effect of a medication, separate from its main purpose.', category: 'medications'),
  GlossaryTerm(term: 'Stage (cancer)', definition: 'How far cancer has spread. Stages run from 0 (early) to 4 (advanced).', category: 'conditions'),
  GlossaryTerm(term: 'Stat', definition: 'Immediately. As in "give this medication stat."', category: 'general'),
  GlossaryTerm(term: 'Stenosis', definition: 'A narrowing of a passage in the body, like a heart valve or spinal canal.', category: 'conditions'),
  GlossaryTerm(term: 'Stoma', definition: 'A surgically created opening on the body, like for a colostomy.', category: 'procedures'),
  GlossaryTerm(term: 'Stroke (CVA)', definition: 'Brain damage caused by blocked or bleeding blood vessels. Time is critical — call 911 for sudden weakness, slurred speech, or face drooping.', category: 'conditions'),
  GlossaryTerm(term: 'Subcutaneous (SubQ)', definition: 'Injected just under the skin (e.g. insulin).', category: 'medications'),
  GlossaryTerm(term: 'Sundowning', definition: 'Increased confusion, agitation, or anxiety in the late afternoon and evening. Common in Alzheimer\'s and dementia.', category: 'conditions'),
  GlossaryTerm(term: 'Suppository', definition: 'Medication inserted into the rectum, vagina, or urethra rather than swallowed.', category: 'medications'),
  GlossaryTerm(term: 'Systolic', definition: 'The top number of a blood pressure reading. Pressure during a heartbeat.', category: 'vitals'),

  // ── T ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Tachycardia', definition: 'Heart rate above 100 beats per minute at rest. Can be caused by pain, anxiety, fever, or medications.', category: 'vitals'),
  GlossaryTerm(term: 'TIA (Transient Ischemic Attack)', definition: 'A "mini-stroke" with stroke-like symptoms that resolve within 24 hours. A warning sign — call 911.', category: 'conditions'),
  GlossaryTerm(term: 'Titrate', definition: 'To gradually adjust a medication dose up or down.', category: 'medications'),
  GlossaryTerm(term: 'Tolerance', definition: 'When the body adapts to a medication and needs more to get the same effect.', category: 'medications'),
  GlossaryTerm(term: 'Topical', definition: 'Applied to the skin (creams, ointments, patches).', category: 'medications'),
  GlossaryTerm(term: 'Transfer', definition: 'Moving a person from one surface to another, like bed to wheelchair.', category: 'care'),
  GlossaryTerm(term: 'Tremor', definition: 'Involuntary shaking, often of the hands. Common in Parkinson\'s.', category: 'conditions'),

  // ── U ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Ulcer', definition: 'An open sore, on the skin (pressure ulcer) or in the body (stomach ulcer).', category: 'conditions'),
  GlossaryTerm(term: 'UTI (Urinary Tract Infection)', definition: 'Infection in the bladder or kidneys. In elderly patients, may cause sudden confusion rather than typical burning symptoms.', category: 'conditions'),

  // ── V ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Vascular', definition: 'Relating to blood vessels.', category: 'general'),
  GlossaryTerm(term: 'Ventilator', definition: 'A machine that breathes for a patient who cannot breathe on their own.', category: 'procedures'),
  GlossaryTerm(term: 'Vital Signs', definition: 'Basic body measurements: temperature, pulse, respiration rate, blood pressure, and oxygen saturation.', category: 'vitals'),

  // ── W ───────────────────────────────────────────────────
  GlossaryTerm(term: 'Walker', definition: 'A four-legged frame that helps with walking and balance.', category: 'care'),
  GlossaryTerm(term: 'Wandering', definition: 'When a person with dementia walks aimlessly and may become lost. Triggers safety precautions like door alarms.', category: 'care'),
  GlossaryTerm(term: 'Wheelchair-bound', definition: 'Using a wheelchair for mobility (the term "wheelchair user" is preferred).', category: 'care'),
  GlossaryTerm(term: 'Wound Care', definition: 'Cleaning, dressing, and monitoring of cuts, sores, or surgical sites to prevent infection.', category: 'procedures'),
];
