// lib/models/support_group.dart
//
// Unified model for caregiver support groups from any source (bundled
// static directory, user-submitted local, future 211/Alz.org scrape).
// Follows the RespiteProvider pattern so the two finders share look +
// feel.
//
// Condition types are structured (enum-backed strings) so caregivers
// can filter to "just dementia" or "mental health" without text search
// false positives. Virtual-only groups carry an empty address and a
// `meetingUrl` instead.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// What condition / caregiving context the group serves. Multi-valued
/// on any given group — an Alzheimer's group also serves dementia
/// caregivers broadly, for example.
enum SupportConditionType {
  alzheimers,
  dementiaGeneral,
  parkinsons,
  stroke,
  cancer,
  mentalHealth,
  heartDisease,
  chronicIllness,
  disability,
  veterans,
  grief,
  youngCaregivers, // sandwich generation / adult children
  lgbtq,
  general, // any-caregiver group with no single disease focus
}

extension SupportConditionTypeX on SupportConditionType {
  String get label {
    switch (this) {
      case SupportConditionType.alzheimers:
        return "Alzheimer's";
      case SupportConditionType.dementiaGeneral:
        return 'Dementia (general)';
      case SupportConditionType.parkinsons:
        return "Parkinson's";
      case SupportConditionType.stroke:
        return 'Stroke';
      case SupportConditionType.cancer:
        return 'Cancer';
      case SupportConditionType.mentalHealth:
        return 'Mental health';
      case SupportConditionType.heartDisease:
        return 'Heart disease';
      case SupportConditionType.chronicIllness:
        return 'Chronic illness';
      case SupportConditionType.disability:
        return 'Disability';
      case SupportConditionType.veterans:
        return 'Veterans';
      case SupportConditionType.grief:
        return 'Grief / bereavement';
      case SupportConditionType.youngCaregivers:
        return 'Adult children';
      case SupportConditionType.lgbtq:
        return 'LGBTQ+';
      case SupportConditionType.general:
        return 'General caregiving';
    }
  }

  IconData get icon {
    switch (this) {
      case SupportConditionType.alzheimers:
      case SupportConditionType.dementiaGeneral:
        return Icons.psychology_outlined;
      case SupportConditionType.parkinsons:
        return Icons.accessibility_new_outlined;
      case SupportConditionType.stroke:
        return Icons.bolt_outlined;
      case SupportConditionType.cancer:
        return Icons.health_and_safety_outlined;
      case SupportConditionType.mentalHealth:
        return Icons.sentiment_satisfied_outlined;
      case SupportConditionType.heartDisease:
        return Icons.favorite_outline;
      case SupportConditionType.chronicIllness:
        return Icons.monitor_heart_outlined;
      case SupportConditionType.disability:
        return Icons.accessible_outlined;
      case SupportConditionType.veterans:
        return Icons.military_tech_outlined;
      case SupportConditionType.grief:
        return Icons.sentiment_very_dissatisfied_outlined;
      case SupportConditionType.youngCaregivers:
        return Icons.family_restroom_outlined;
      case SupportConditionType.lgbtq:
        return Icons.diversity_3_outlined;
      case SupportConditionType.general:
        return Icons.groups_outlined;
    }
  }

  String get firestoreValue {
    switch (this) {
      case SupportConditionType.alzheimers:
        return 'alzheimers';
      case SupportConditionType.dementiaGeneral:
        return 'dementia_general';
      case SupportConditionType.parkinsons:
        return 'parkinsons';
      case SupportConditionType.stroke:
        return 'stroke';
      case SupportConditionType.cancer:
        return 'cancer';
      case SupportConditionType.mentalHealth:
        return 'mental_health';
      case SupportConditionType.heartDisease:
        return 'heart_disease';
      case SupportConditionType.chronicIllness:
        return 'chronic_illness';
      case SupportConditionType.disability:
        return 'disability';
      case SupportConditionType.veterans:
        return 'veterans';
      case SupportConditionType.grief:
        return 'grief';
      case SupportConditionType.youngCaregivers:
        return 'young_caregivers';
      case SupportConditionType.lgbtq:
        return 'lgbtq';
      case SupportConditionType.general:
        return 'general';
    }
  }

  static SupportConditionType fromString(String? s) {
    switch (s) {
      case 'alzheimers':
        return SupportConditionType.alzheimers;
      case 'dementia_general':
        return SupportConditionType.dementiaGeneral;
      case 'parkinsons':
        return SupportConditionType.parkinsons;
      case 'stroke':
        return SupportConditionType.stroke;
      case 'cancer':
        return SupportConditionType.cancer;
      case 'mental_health':
        return SupportConditionType.mentalHealth;
      case 'heart_disease':
        return SupportConditionType.heartDisease;
      case 'chronic_illness':
        return SupportConditionType.chronicIllness;
      case 'disability':
        return SupportConditionType.disability;
      case 'veterans':
        return SupportConditionType.veterans;
      case 'grief':
        return SupportConditionType.grief;
      case 'young_caregivers':
        return SupportConditionType.youngCaregivers;
      case 'lgbtq':
        return SupportConditionType.lgbtq;
      default:
        return SupportConditionType.general;
    }
  }
}

/// Meeting format. Drives which filter chip matches and how the card
/// renders (virtual groups show a "Join online" CTA instead of
/// address/directions).
enum SupportFormat { inPerson, virtual, phone, hybrid }

extension SupportFormatX on SupportFormat {
  String get label {
    switch (this) {
      case SupportFormat.inPerson:
        return 'In-person';
      case SupportFormat.virtual:
        return 'Virtual';
      case SupportFormat.phone:
        return 'Phone';
      case SupportFormat.hybrid:
        return 'Hybrid';
    }
  }

  IconData get icon {
    switch (this) {
      case SupportFormat.inPerson:
        return Icons.location_on_outlined;
      case SupportFormat.virtual:
        return Icons.videocam_outlined;
      case SupportFormat.phone:
        return Icons.phone_outlined;
      case SupportFormat.hybrid:
        return Icons.sync_alt_outlined;
    }
  }

  String get firestoreValue {
    switch (this) {
      case SupportFormat.inPerson:
        return 'in_person';
      case SupportFormat.virtual:
        return 'virtual';
      case SupportFormat.phone:
        return 'phone';
      case SupportFormat.hybrid:
        return 'hybrid';
    }
  }

  static SupportFormat fromString(String? s) {
    switch (s) {
      case 'in_person':
        return SupportFormat.inPerson;
      case 'virtual':
        return SupportFormat.virtual;
      case 'phone':
        return SupportFormat.phone;
      case 'hybrid':
        return SupportFormat.hybrid;
      default:
        return SupportFormat.inPerson;
    }
  }
}

class SupportGroup {
  final String id;
  final String name;
  final String? organizationName;
  final String? description;

  final List<SupportConditionType> conditions;
  final SupportFormat format;

  /// Recurring meeting cadence as free text — "Every Tuesday 7 PM ET",
  /// "2nd & 4th Thursdays", "24/7 helpline". Varies too much by
  /// organization to structure further.
  final String? meetingSchedule;

  // In-person fields (nullable for virtual-only).
  final String? address;
  final String? city;
  final String? state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;

  // Remote fields.
  final String? meetingUrl;

  final String? phone;
  final String? email;
  final String? website;

  /// Non-English languages the group supports, e.g. ['Spanish', 'Mandarin'].
  final List<String> languages;

  /// 'bundled' | 'user_submitted' | 'partner_scrape' (future).
  final String source;
  final DateTime? verifiedAt;
  final String? submittedBy;

  const SupportGroup({
    required this.id,
    required this.name,
    this.organizationName,
    this.description,
    this.conditions = const [SupportConditionType.general],
    this.format = SupportFormat.inPerson,
    this.meetingSchedule,
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.meetingUrl,
    this.phone,
    this.email,
    this.website,
    this.languages = const [],
    this.source = 'bundled',
    this.verifiedAt,
    this.submittedBy,
  });

  /// 3-digit ZIP prefix for regional matching (used by the user-
  /// submitted Firestore query).
  String get zipPrefix {
    final z = zipCode ?? '';
    return z.length >= 3 ? z.substring(0, 3) : z;
  }

  String get fullAddress {
    final a = address ?? '';
    final c = city ?? '';
    final st = state ?? '';
    final z = zipCode ?? '';
    return [
      if (a.isNotEmpty) a,
      [c, st].where((p) => p.isNotEmpty).join(', '),
      if (z.isNotEmpty) z,
    ].where((s) => s.isNotEmpty).join(', ');
  }

  bool get isVirtualAccessible =>
      format == SupportFormat.virtual ||
      format == SupportFormat.phone ||
      format == SupportFormat.hybrid;

  bool get hasInPersonLocation =>
      (format == SupportFormat.inPerson || format == SupportFormat.hybrid) &&
      (city != null && city!.isNotEmpty);

  String get sourceLabel {
    switch (source) {
      case 'user_submitted':
        return 'Community added';
      case 'bundled':
        return 'National resource';
      case 'partner_scrape':
        return 'Partner-verified';
      default:
        return source;
    }
  }

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory SupportGroup.fromFirestore(
      String docId, Map<String, dynamic> data) {
    return SupportGroup(
      id: docId,
      name: data['name'] as String? ?? '',
      organizationName: data['organizationName'] as String?,
      description: data['description'] as String?,
      conditions:
          (data['conditions'] as List<dynamic>? ?? const <dynamic>[])
              .map((v) => SupportConditionTypeX.fromString(v as String?))
              .toList(),
      format: SupportFormatX.fromString(data['format'] as String?),
      meetingSchedule: data['meetingSchedule'] as String?,
      address: data['address'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      zipCode: data['zipCode'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      meetingUrl: data['meetingUrl'] as String?,
      phone: data['phone'] as String?,
      email: data['email'] as String?,
      website: data['website'] as String?,
      languages:
          (data['languages'] as List<dynamic>? ?? const <dynamic>[])
              .map((v) => v.toString())
              .toList(),
      source: data['source'] as String? ?? 'user_submitted',
      verifiedAt: data['verifiedAt'] == null
          ? null
          : (data['verifiedAt'] as Timestamp).toDate(),
      submittedBy: data['submittedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        if (organizationName != null) 'organizationName': organizationName,
        if (description != null) 'description': description,
        'conditions':
            conditions.map((c) => c.firestoreValue).toList(),
        'format': format.firestoreValue,
        if (meetingSchedule != null) 'meetingSchedule': meetingSchedule,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (zipCode != null) 'zipCode': zipCode,
        'zipPrefix': zipPrefix,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (meetingUrl != null) 'meetingUrl': meetingUrl,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (website != null) 'website': website,
        if (languages.isNotEmpty) 'languages': languages,
        'source': source,
        if (submittedBy != null) 'submittedBy': submittedBy,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

// ---------------------------------------------------------------------------
// Static national directory.
//
// Intentionally curated, not exhaustive — the goal is "every caregiver
// can find a legitimate starting point within 2 taps," not to duplicate
// Alz.org's database. Each entry covers either a national hotline,
// a national virtual support network, or a major disease-specific
// umbrella organization.
//
// Data is current as of 2025. URLs + phone numbers were taken from
// public websites; please report breakage.
// ---------------------------------------------------------------------------

class SupportGroupDirectory {
  SupportGroupDirectory._();

  static const List<SupportGroup> kNationalDirectory = [
    // ── Alzheimer's & dementia ─────────────────────────────
    SupportGroup(
      id: 'alz_247',
      name: "Alzheimer's Association 24/7 Helpline",
      organizationName: "Alzheimer's Association",
      description:
          'Free 24/7 support from dementia specialists. Emotional support, '
          'safety planning, and local-resource referrals. Translation '
          'available in 200+ languages.',
      conditions: [
        SupportConditionType.alzheimers,
        SupportConditionType.dementiaGeneral,
      ],
      format: SupportFormat.phone,
      meetingSchedule: '24 hours / 7 days',
      phone: '1-800-272-3900',
      website: 'https://www.alz.org/help-support/resources/helpline',
      languages: ['English', 'Spanish', '200+ via interpreter'],
      source: 'bundled',
    ),
    SupportGroup(
      id: 'alz_connected',
      name: 'ALZConnected',
      organizationName: "Alzheimer's Association",
      description:
          'Free online community for people living with dementia and '
          'their caregivers. Moderated message boards, caregiver and '
          'person-with-dementia rooms, and topic-specific groups.',
      conditions: [
        SupportConditionType.alzheimers,
        SupportConditionType.dementiaGeneral,
      ],
      format: SupportFormat.virtual,
      meetingSchedule: 'Always open (message boards)',
      meetingUrl: 'https://www.alzconnected.org',
      website: 'https://www.alzconnected.org',
      source: 'bundled',
    ),
    SupportGroup(
      id: 'alz_online_groups',
      name: "Alzheimer's Association Online Support Groups",
      organizationName: "Alzheimer's Association",
      description:
          'Schedule of live video support groups for caregivers and '
          'people with early-stage dementia. Facilitator-led sessions '
          'run weekly on Zoom.',
      conditions: [
        SupportConditionType.alzheimers,
        SupportConditionType.dementiaGeneral,
      ],
      format: SupportFormat.virtual,
      meetingSchedule: 'Weekly — check schedule',
      website:
          'https://www.alz.org/help-support/community/support-groups',
      source: 'bundled',
    ),
    SupportGroup(
      id: 'lbda_connect',
      name: 'LBDA Lewy Line + Online Groups',
      organizationName: 'Lewy Body Dementia Association',
      description:
          'Phone support line and moderated online caregiver groups for '
          'people affected by Lewy body dementia.',
      conditions: [SupportConditionType.dementiaGeneral],
      format: SupportFormat.hybrid,
      meetingSchedule: 'Helpline M–F, 9 AM–5 PM ET',
      phone: '1-800-539-9767',
      website: 'https://www.lbda.org/caregiver-support-groups',
      source: 'bundled',
    ),

    // ── Parkinson's ────────────────────────────────────────
    SupportGroup(
      id: 'parkinson_helpline',
      name: "Parkinson's Foundation Helpline",
      organizationName: "Parkinson's Foundation",
      description:
          'Free bilingual helpline for Parkinson\'s patients, '
          'caregivers, and families. Social workers refer to local '
          'chapters and virtual groups.',
      conditions: [SupportConditionType.parkinsons],
      format: SupportFormat.phone,
      meetingSchedule: 'M–F, 9 AM–7 PM ET',
      phone: '1-800-473-4636',
      website: 'https://www.parkinson.org/library/helpline',
      languages: ['English', 'Spanish'],
      source: 'bundled',
    ),
    SupportGroup(
      id: 'apda_groups',
      name: 'APDA Support Groups',
      organizationName: 'American Parkinson Disease Association',
      description:
          'National locator for in-person and virtual Parkinson\'s '
          'support groups, including caregiver-specific groups.',
      conditions: [SupportConditionType.parkinsons],
      format: SupportFormat.hybrid,
      website:
          'https://www.apdaparkinson.org/resources-support/local-resources/support-groups',
      source: 'bundled',
    ),

    // ── Stroke ─────────────────────────────────────────────
    SupportGroup(
      id: 'stroke_warmline',
      name: 'Stroke Family Warmline',
      organizationName: 'American Stroke Association',
      description:
          'Peer support line for stroke survivors and their family '
          'caregivers, plus referrals to local Support Network groups.',
      conditions: [SupportConditionType.stroke],
      format: SupportFormat.phone,
      meetingSchedule: 'M–F, 9 AM–5 PM CT',
      phone: '1-888-478-7653',
      website:
          'https://www.stroke.org/en/stroke-support-group-finder',
      source: 'bundled',
    ),

    // ── Cancer ─────────────────────────────────────────────
    SupportGroup(
      id: 'acs_247',
      name: 'American Cancer Society 24/7 Help',
      organizationName: 'American Cancer Society',
      description:
          'Round-the-clock information and emotional support for '
          'cancer patients, caregivers, and loved ones.',
      conditions: [SupportConditionType.cancer],
      format: SupportFormat.phone,
      meetingSchedule: '24 hours / 7 days',
      phone: '1-800-227-2345',
      website: 'https://www.cancer.org',
      languages: ['English', 'Spanish'],
      source: 'bundled',
    ),
    SupportGroup(
      id: 'cancer_care_groups',
      name: 'CancerCare Support Groups',
      organizationName: 'CancerCare',
      description:
          'Free professional-led online + phone support groups for '
          'cancer patients and caregivers, specific to cancer type and '
          'life stage.',
      conditions: [SupportConditionType.cancer],
      format: SupportFormat.virtual,
      meetingSchedule: 'Weekly — check schedule',
      phone: '1-800-813-4673',
      website: 'https://www.cancercare.org/support_groups',
      source: 'bundled',
    ),

    // ── Mental health ─────────────────────────────────────
    SupportGroup(
      id: 'nami_helpline',
      name: 'NAMI HelpLine',
      organizationName: 'National Alliance on Mental Illness',
      description:
          'Peer-support specialists offer information, referrals, and '
          'emotional support for caregivers of people with mental '
          'health conditions.',
      conditions: [SupportConditionType.mentalHealth],
      format: SupportFormat.phone,
      meetingSchedule: 'M–F, 10 AM–10 PM ET. Text HelpLine 24/7.',
      phone: '1-800-950-6264',
      website: 'https://www.nami.org/help',
      source: 'bundled',
    ),
    SupportGroup(
      id: 'nami_family_support',
      name: 'NAMI Family Support Group',
      organizationName: 'National Alliance on Mental Illness',
      description:
          'Free peer-led support groups for family members, partners, '
          'and caregivers of people with mental illness. In-person + '
          'virtual meetings through local NAMI affiliates.',
      conditions: [SupportConditionType.mentalHealth],
      format: SupportFormat.hybrid,
      website:
          'https://www.nami.org/Support-Education/Support-Groups/NAMI-Family-Support-Group',
      source: 'bundled',
    ),
    SupportGroup(
      id: '988_lifeline',
      name: '988 Suicide & Crisis Lifeline',
      organizationName: 'SAMHSA',
      description:
          '24/7 free and confidential crisis support. Caregivers are '
          'welcome to call for themselves or on behalf of someone in '
          'distress.',
      conditions: [SupportConditionType.mentalHealth],
      format: SupportFormat.phone,
      meetingSchedule: '24 hours / 7 days',
      phone: '988',
      website: 'https://988lifeline.org',
      languages: ['English', 'Spanish'],
      source: 'bundled',
    ),

    // ── Heart disease / chronic illness ───────────────────
    SupportGroup(
      id: 'heart_support_network',
      name: 'AHA Support Network',
      organizationName: 'American Heart Association',
      description:
          'Free online community for people affected by heart disease '
          'and stroke plus their caregivers. Moderated forums + '
          'curated resource library.',
      conditions: [
        SupportConditionType.heartDisease,
        SupportConditionType.chronicIllness,
      ],
      format: SupportFormat.virtual,
      meetingUrl: 'https://supportnetwork.heart.org',
      website: 'https://supportnetwork.heart.org',
      source: 'bundled',
    ),

    // ── Veterans ──────────────────────────────────────────
    SupportGroup(
      id: 'va_caregiver_line',
      name: 'VA Caregiver Support Line',
      organizationName: 'U.S. Department of Veterans Affairs',
      description:
          'Free support line staffed by licensed social workers for '
          'caregivers of veterans. Connects to PCAFC benefits and '
          'local VA Caregiver Support Coordinators.',
      conditions: [SupportConditionType.veterans],
      format: SupportFormat.phone,
      meetingSchedule: 'M–F, 8 AM–10 PM ET. Sat, 8 AM–5 PM ET.',
      phone: '1-855-260-3274',
      website: 'https://www.caregiver.va.gov',
      source: 'bundled',
    ),

    // ── Grief / bereavement ───────────────────────────────
    SupportGroup(
      id: 'grief_hope_hotline',
      name: 'GriefShare',
      organizationName: 'GriefShare',
      description:
          'Network of ~18,000 grief support groups worldwide — most '
          'run through local churches. Searchable by ZIP, with virtual '
          'groups available.',
      conditions: [SupportConditionType.grief],
      format: SupportFormat.hybrid,
      website: 'https://www.griefshare.org/findagroup',
      source: 'bundled',
    ),

    // ── General caregiving ────────────────────────────────
    SupportGroup(
      id: 'can_helpdesk',
      name: 'Caregiver Action Network Help Desk',
      organizationName: 'Caregiver Action Network',
      description:
          'Free peer-support help desk for family caregivers of adults '
          'with any chronic condition. Shepherded by CAN\'s national '
          'caregiver volunteers.',
      conditions: [SupportConditionType.general],
      format: SupportFormat.phone,
      meetingSchedule: 'M–F, 9 AM–5 PM ET',
      phone: '1-855-227-3640',
      email: 'info@caregiveraction.org',
      website: 'https://www.caregiveraction.org/help',
      source: 'bundled',
    ),
    SupportGroup(
      id: 'can_family_circle',
      name: 'CAN Family Caregiver Forum',
      organizationName: 'Caregiver Action Network',
      description:
          'Moderated peer-to-peer online community for family '
          'caregivers across all conditions.',
      conditions: [SupportConditionType.general],
      format: SupportFormat.virtual,
      meetingUrl: 'https://www.caregiveraction.org/family-caregiver-forum',
      website: 'https://www.caregiveraction.org/family-caregiver-forum',
      source: 'bundled',
    ),
    SupportGroup(
      id: 'fca_carenav',
      name: 'Family Caregiver Alliance CareNav',
      organizationName: 'Family Caregiver Alliance',
      description:
          'Free secure online service that connects caregivers with '
          'FCA staff, plus access to online support groups.',
      conditions: [SupportConditionType.general],
      format: SupportFormat.virtual,
      meetingUrl: 'https://www.caregiver.org/carenav',
      website: 'https://www.caregiver.org',
      phone: '1-800-445-8106',
      source: 'bundled',
    ),
    SupportGroup(
      id: 'well_spouse',
      name: 'Well Spouse Association',
      organizationName: 'Well Spouse Association',
      description:
          'Peer support specifically for spouses and partners of '
          'people with chronic illness or disability. National round-'
          'table calls, regional meetings, online forum.',
      conditions: [
        SupportConditionType.general,
        SupportConditionType.chronicIllness,
      ],
      format: SupportFormat.hybrid,
      phone: '1-800-838-0879',
      website: 'https://wellspouse.org',
      source: 'bundled',
    ),
    SupportGroup(
      id: 'eldercare_locator',
      name: 'Eldercare Locator',
      organizationName: 'U.S. Administration for Community Living',
      description:
          'Federal service connecting callers to local Area Agencies '
          'on Aging, which run or list local in-person support '
          'groups. Use this to find groups in your county.',
      conditions: [SupportConditionType.general],
      format: SupportFormat.phone,
      meetingSchedule: 'M–F, 9 AM–8 PM ET',
      phone: '1-800-677-1116',
      website: 'https://eldercare.acl.gov',
      languages: ['English', 'Spanish'],
      source: 'bundled',
    ),

    // ── LGBTQ+ ───────────────────────────────────────────
    SupportGroup(
      id: 'sage_helpline',
      name: 'SAGE LGBT Elder Hotline',
      organizationName: 'SAGE',
      description:
          'Free and confidential hotline for LGBTQ+ older adults and '
          'their caregivers. Information, referrals, and emotional '
          'support.',
      conditions: [
        SupportConditionType.lgbtq,
        SupportConditionType.general,
      ],
      format: SupportFormat.phone,
      meetingSchedule: 'Monday–Friday, 4 PM–midnight ET',
      phone: '1-877-360-5428',
      website: 'https://www.sageusa.org/what-we-do/sage-national-lgbt-elder-hotline',
      source: 'bundled',
    ),

    // ── Adult children / sandwich generation ─────────────
    SupportGroup(
      id: 'daughterhood_circles',
      name: 'Daughterhood Circles',
      organizationName: 'Daughterhood',
      description:
          'Peer support groups for daughters caring for aging parents. '
          'Virtual and in-person circles run by trained community '
          'leaders.',
      conditions: [
        SupportConditionType.youngCaregivers,
        SupportConditionType.general,
      ],
      format: SupportFormat.hybrid,
      website: 'https://daughterhood.org/daughterhood-circles',
      source: 'bundled',
    ),
  ];

  /// Returns groups matching any of the [conditions] (empty list =
  /// return all). Bundled-first, stable order.
  static List<SupportGroup> filter({
    Iterable<SupportConditionType> conditions = const [],
    SupportFormat? format,
  }) {
    final conds = conditions.toSet();
    return kNationalDirectory.where((g) {
      if (format != null && g.format != format) return false;
      if (conds.isEmpty) return true;
      return g.conditions.any(conds.contains);
    }).toList();
  }
}
