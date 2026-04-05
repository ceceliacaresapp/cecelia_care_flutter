// lib/models/training_resource.dart
//
// Data model + curated static library for the Caregiver Training hub.
// ~45 resources organized into 7 categories.

import 'package:flutter/material.dart';

enum TrainingCategory {
  dementiaCare,
  fallPrevention,
  medication,
  selfCare,
  legalBenefits,
  conditionSpecific,
  lgbtqResources,
}

enum ResourceType { article, guide, video, tool, hotline }

class TrainingCategoryInfo {
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const TrainingCategoryInfo({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class TrainingResource {
  final String id;
  final String title;
  final String description;
  final String url;
  final String source;
  final TrainingCategory category;
  final ResourceType type;

  const TrainingResource({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.category,
    this.type = ResourceType.article,
  });

  // ── Category metadata ──────────────────────────────────────────

  static const Map<TrainingCategory, TrainingCategoryInfo> categories = {
    TrainingCategory.dementiaCare: TrainingCategoryInfo(
      label: 'Dementia Care',
      description: 'Understanding Alzheimer\'s, communication, behaviors',
      icon: Icons.psychology_outlined,
      color: Color(0xFF7E57C2),
    ),
    TrainingCategory.fallPrevention: TrainingCategoryInfo(
      label: 'Fall Prevention',
      description: 'Home safety, mobility aids, exercises',
      icon: Icons.elderly_outlined,
      color: Color(0xFFAD1457),
    ),
    TrainingCategory.medication: TrainingCategoryInfo(
      label: 'Medication Safety',
      description: 'Drug interactions, adherence, safe storage',
      icon: Icons.medication_outlined,
      color: Color(0xFF1E88E5),
    ),
    TrainingCategory.selfCare: TrainingCategoryInfo(
      label: 'Caregiver Self-Care',
      description: 'Burnout prevention, mental health, respite',
      icon: Icons.spa_outlined,
      color: Color(0xFF00897B),
    ),
    TrainingCategory.legalBenefits: TrainingCategoryInfo(
      label: 'Legal & Benefits',
      description: 'Medicare, VA benefits, elder law, advance directives',
      icon: Icons.gavel_outlined,
      color: Color(0xFF5C6BC0),
    ),
    TrainingCategory.conditionSpecific: TrainingCategoryInfo(
      label: 'Condition-Specific',
      description: 'Heart, diabetes, Parkinson\'s, lung, kidney',
      icon: Icons.medical_services_outlined,
      color: Color(0xFFE64A19),
    ),
    TrainingCategory.lgbtqResources: TrainingCategoryInfo(
      label: 'LGBTQ+ Resources',
      description: 'Affirming legal and advocacy services',
      icon: Icons.diversity_3_outlined,
      color: Color(0xFF8E24AA),
    ),
  };

  // ── Resource type icons ────────────────────────────────────────

  static IconData typeIcon(ResourceType t) {
    switch (t) {
      case ResourceType.article: return Icons.article_outlined;
      case ResourceType.guide: return Icons.menu_book_outlined;
      case ResourceType.video: return Icons.play_circle_outline;
      case ResourceType.tool: return Icons.build_outlined;
      case ResourceType.hotline: return Icons.phone_outlined;
    }
  }

  // ── Full curated library ───────────────────────────────────────

  static const List<TrainingResource> all = [
    // ── Dementia Care ─────────────────────────────────────────────
    TrainingResource(
      id: 'alz-10-signs', title: '10 Warning Signs of Alzheimer\'s',
      description: 'Recognize early symptoms that go beyond normal aging.',
      url: 'https://www.alz.org/alzheimers-dementia/10_signs',
      source: 'ALZ.org', category: TrainingCategory.dementiaCare, type: ResourceType.guide),
    TrainingResource(
      id: 'alz-communication', title: 'Communication Tips',
      description: 'How to have meaningful conversations as dementia progresses.',
      url: 'https://www.alz.org/help-support/caregiving/daily-care/communications',
      source: 'ALZ.org', category: TrainingCategory.dementiaCare),
    TrainingResource(
      id: 'alz-behaviors', title: 'Understanding Behaviors',
      description: 'Why agitation, aggression, and sundowning happen \u2014 and how to respond.',
      url: 'https://www.alz.org/help-support/caregiving/stages-behaviors',
      source: 'ALZ.org', category: TrainingCategory.dementiaCare),
    TrainingResource(
      id: 'nia-caring-alzheimers', title: 'Caring for a Person with Alzheimer\'s',
      description: 'Comprehensive NIA guide covering daily care, communication, and safety.',
      url: 'https://www.nia.nih.gov/health/caregiving/caring-person-alzheimers-disease',
      source: 'NIA', category: TrainingCategory.dementiaCare, type: ResourceType.guide),
    TrainingResource(
      id: 'alz-safety', title: 'Home Safety for Dementia',
      description: 'Room-by-room checklist for making the home safer.',
      url: 'https://www.alz.org/help-support/caregiving/safety',
      source: 'ALZ.org', category: TrainingCategory.dementiaCare),
    TrainingResource(
      id: 'alz-late-stage', title: 'Late-Stage Caregiving',
      description: 'Comfort care, hospice decisions, and end-of-life planning.',
      url: 'https://www.alz.org/help-support/caregiving/stages-behaviors/late-stage',
      source: 'ALZ.org', category: TrainingCategory.dementiaCare),

    // ── Fall Prevention ───────────────────────────────────────────
    TrainingResource(
      id: 'cdc-steadi-patient', title: 'CDC STEADI: What You Can Do',
      description: 'Patient-friendly fall prevention resources from the CDC.',
      url: 'https://www.cdc.gov/steadi/patient.html',
      source: 'CDC', category: TrainingCategory.fallPrevention, type: ResourceType.guide),
    TrainingResource(
      id: 'nia-fall-proofing', title: 'Fall-Proofing Your Home',
      description: 'NIA guide to removing trip hazards and adding safety features.',
      url: 'https://www.nia.nih.gov/health/fall-proofing-your-home',
      source: 'NIA', category: TrainingCategory.fallPrevention),
    TrainingResource(
      id: 'nia-exercise-balance', title: 'Exercise & Balance for Older Adults',
      description: 'Gentle exercises that improve strength and reduce fall risk.',
      url: 'https://www.nia.nih.gov/health/exercise-and-physical-activity',
      source: 'NIA', category: TrainingCategory.fallPrevention),
    TrainingResource(
      id: 'agingcare-mobility', title: 'When to Get a Walker or Cane',
      description: 'Signs that an assistive device is needed and how to choose one.',
      url: 'https://www.agingcare.com/articles/when-to-use-a-walker-or-cane-143489.htm',
      source: 'AgingCare', category: TrainingCategory.fallPrevention),

    // ── Medication Safety ─────────────────────────────────────────
    TrainingResource(
      id: 'nia-medicines', title: 'Safe Use of Medicines for Older Adults',
      description: 'Tips for managing multiple medications and avoiding interactions.',
      url: 'https://www.nia.nih.gov/health/safe-use-medicines-older-adults',
      source: 'NIA', category: TrainingCategory.medication, type: ResourceType.guide),
    TrainingResource(
      id: 'fda-medwatch', title: 'FDA MedWatch Safety Alerts',
      description: 'Report side effects and check recent drug safety communications.',
      url: 'https://www.fda.gov/safety/medwatch-fda-safety-information-and-adverse-event-reporting-program',
      source: 'FDA', category: TrainingCategory.medication, type: ResourceType.tool),
    TrainingResource(
      id: 'aarp-pill-organizer', title: 'Medication Management Tips',
      description: 'Practical strategies: pill organizers, reminders, and refill systems.',
      url: 'https://www.aarp.org/caregiving/health/info-2020/medication-management.html',
      source: 'AARP', category: TrainingCategory.medication),
    TrainingResource(
      id: 'drugs-interaction', title: 'Drug Interaction Checker',
      description: 'Free tool to check for dangerous interactions between medications.',
      url: 'https://www.drugs.com/drug_interactions.html',
      source: 'Drugs.com', category: TrainingCategory.medication, type: ResourceType.tool),

    // ── Caregiver Self-Care ───────────────────────────────────────
    TrainingResource(
      id: 'can-burnout', title: 'Caregiver Burnout: Signs and Solutions',
      description: 'Recognize burnout early and learn evidence-based coping strategies.',
      url: 'https://www.caregiveraction.org/resources/caregiver-burnout',
      source: 'CAN', category: TrainingCategory.selfCare, type: ResourceType.guide),
    TrainingResource(
      id: 'samhsa-caregiver', title: 'Caregiver Mental Health',
      description: 'SAMHSA resources for depression, anxiety, and grief in caregivers.',
      url: 'https://www.samhsa.gov/mental-health',
      source: 'SAMHSA', category: TrainingCategory.selfCare),
    TrainingResource(
      id: 'aarp-respite', title: 'Finding Respite Care',
      description: 'How to find and afford temporary relief from caregiving duties.',
      url: 'https://www.aarp.org/caregiving/home-care/info-2017/respite-care.html',
      source: 'AARP', category: TrainingCategory.selfCare),
    TrainingResource(
      id: 'alz-caregiver-stress', title: 'Caregiver Stress Check',
      description: 'Self-assessment tool from the Alzheimer\'s Association.',
      url: 'https://www.alz.org/help-support/caregiving/caregiver-health/caregiver-stress-check',
      source: 'ALZ.org', category: TrainingCategory.selfCare, type: ResourceType.tool),
    TrainingResource(
      id: 'crisis-988', title: '988 Suicide & Crisis Lifeline',
      description: '24/7 free and confidential support for emotional distress.',
      url: 'https://988lifeline.org/',
      source: '988 Lifeline', category: TrainingCategory.selfCare, type: ResourceType.hotline),

    // ── Legal & Benefits ──────────────────────────────────────────
    TrainingResource(
      id: 'medicare-gov', title: 'Medicare.gov',
      description: 'Official Medicare information: plans, coverage, and enrollment.',
      url: 'https://www.medicare.gov/',
      source: 'Medicare', category: TrainingCategory.legalBenefits, type: ResourceType.tool),
    TrainingResource(
      id: 'va-caregiver', title: 'VA Caregiver Support',
      description: 'Benefits and support for caregivers of veterans.',
      url: 'https://www.caregiver.va.gov/',
      source: 'VA', category: TrainingCategory.legalBenefits),
    TrainingResource(
      id: 'eldercare-locator', title: 'Eldercare Locator',
      description: 'Find local aging services: meals, transport, home care, adult day.',
      url: 'https://eldercare.acl.gov/',
      source: 'ACL', category: TrainingCategory.legalBenefits, type: ResourceType.tool),
    TrainingResource(
      id: 'ssa-benefits', title: 'Social Security Benefits',
      description: 'Check eligibility and apply for SSI, SSDI, and retirement benefits.',
      url: 'https://www.ssa.gov/benefits/',
      source: 'SSA', category: TrainingCategory.legalBenefits, type: ResourceType.tool),
    TrainingResource(
      id: 'aarp-advance-directives', title: 'Advance Directives Guide',
      description: 'How to set up a living will and healthcare power of attorney.',
      url: 'https://www.aarp.org/caregiving/financial-legal/free-printable-advance-directives/',
      source: 'AARP', category: TrainingCategory.legalBenefits, type: ResourceType.guide),

    // ── Condition-Specific ────────────────────────────────────────
    TrainingResource(
      id: 'aha-heart', title: 'Heart Failure Caregiver Guide',
      description: 'American Heart Association guide to supporting heart failure patients.',
      url: 'https://www.heart.org/en/health-topics/heart-failure',
      source: 'AHA', category: TrainingCategory.conditionSpecific),
    TrainingResource(
      id: 'ada-diabetes', title: 'Diabetes Care for Caregivers',
      description: 'Blood sugar monitoring, diet, insulin management basics.',
      url: 'https://diabetes.org/tools-resources/caregivers',
      source: 'ADA', category: TrainingCategory.conditionSpecific),
    TrainingResource(
      id: 'parkinsons-care', title: 'Parkinson\'s Caregiving Guide',
      description: 'Managing motor symptoms, medications, and emotional changes.',
      url: 'https://www.parkinson.org/living-with-parkinsons/for-caregivers',
      source: 'Parkinson\'s Foundation', category: TrainingCategory.conditionSpecific, type: ResourceType.guide),
    TrainingResource(
      id: 'lung-copd', title: 'COPD Caregiver Resources',
      description: 'Breathing exercises, oxygen management, and emergency plans.',
      url: 'https://www.lung.org/lung-health-diseases/lung-disease-lookup/copd/living-with-copd/caregiver',
      source: 'ALA', category: TrainingCategory.conditionSpecific),
    TrainingResource(
      id: 'kidney-nkf', title: 'Kidney Disease Caregiver Guide',
      description: 'Dialysis support, diet management, and emotional coping.',
      url: 'https://www.kidney.org/patients/caregivers',
      source: 'NKF', category: TrainingCategory.conditionSpecific),
    TrainingResource(
      id: 'cancer-acs', title: 'Cancer Caregiver Support',
      description: 'Practical tips for supporting someone through cancer treatment.',
      url: 'https://www.cancer.org/cancer/caregivers.html',
      source: 'ACS', category: TrainingCategory.conditionSpecific),

    // ── LGBTQ+ Resources ──────────────────────────────────────────
    TrainingResource(
      id: 'sage-lgbtq', title: 'SAGE: Services for LGBTQ+ Elders',
      description: 'Advocacy, services, and legal resources for LGBTQ+ older adults.',
      url: 'https://www.sageusa.org/',
      source: 'SAGE', category: TrainingCategory.lgbtqResources),
    TrainingResource(
      id: 'lambda-legal', title: 'Lambda Legal: Elder Rights',
      description: 'Legal assistance and advocacy for LGBTQ+ elder law issues.',
      url: 'https://www.lambdalegal.org/',
      source: 'Lambda Legal', category: TrainingCategory.lgbtqResources),
    TrainingResource(
      id: 'nclr-elder', title: 'National Center for Lesbian Rights',
      description: 'Elder law, family law, and estate planning resources.',
      url: 'https://www.nclrights.org/',
      source: 'NCLR', category: TrainingCategory.lgbtqResources),
    TrainingResource(
      id: 'tlc-trans', title: 'Transgender Law Center',
      description: 'Legal advocacy including healthcare rights and elder issues.',
      url: 'https://transgenderlawcenter.org/',
      source: 'TLC', category: TrainingCategory.lgbtqResources),
    TrainingResource(
      id: 'glad-lgbtq', title: 'GLBTQ Legal Advocates & Defenders',
      description: 'Legal advocacy and public education for LGBTQ+ community.',
      url: 'https://www.glad.org/',
      source: 'GLAD', category: TrainingCategory.lgbtqResources),
  ];

  /// Resources filtered by category.
  static List<TrainingResource> forCategory(TrainingCategory cat) =>
      all.where((r) => r.category == cat).toList();
}
