// lib/models/respite_provider.dart
//
// Unified data model for respite care providers from any source
// (bundled static, CMS API, user-submitted, future Google Places).
// HSDS-inspired flattened schema for Firestore compatibility.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RespiteProvider {
  final String id;
  final String name;
  final String? organizationName;
  final String? description;
  final List<String> serviceTypes;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String? phone;
  final String? website;
  final double? latitude;
  final double? longitude;
  final String source; // 'bundled', 'cms_api', 'user_submitted'
  final DateTime? verifiedAt;
  final String? submittedBy;

  const RespiteProvider({
    required this.id,
    required this.name,
    this.organizationName,
    this.description,
    this.serviceTypes = const [],
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.phone,
    this.website,
    this.latitude,
    this.longitude,
    required this.source,
    this.verifiedAt,
    this.submittedBy,
  });

  /// 3-digit ZIP prefix for regional matching.
  String get zipPrefix => zipCode.length >= 3 ? zipCode.substring(0, 3) : zipCode;

  String get fullAddress => '$address, $city, $state $zipCode';

  String get sourceLabel {
    switch (source) {
      case 'cms_api':
        return 'Medicare verified';
      case 'user_submitted':
        return 'Community added';
      case 'bundled':
        return 'National resource';
      default:
        return source;
    }
  }

  factory RespiteProvider.fromFirestore(String docId, Map<String, dynamic> data) {
    return RespiteProvider(
      id: docId,
      name: data['name'] as String? ?? '',
      organizationName: data['organizationName'] as String?,
      description: data['description'] as String?,
      serviceTypes: List<String>.from(data['serviceTypes'] as List? ?? []),
      address: data['address'] as String? ?? '',
      city: data['city'] as String? ?? '',
      state: data['state'] as String? ?? '',
      zipCode: data['zipCode'] as String? ?? '',
      phone: data['phone'] as String?,
      website: data['website'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      source: data['source'] as String? ?? 'user_submitted',
      verifiedAt: data['verifiedAt'] != null
          ? (data['verifiedAt'] as Timestamp).toDate()
          : null,
      submittedBy: data['submittedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'organizationName': organizationName,
        'description': description,
        'serviceTypes': serviceTypes,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'zipPrefix': zipPrefix,
        'phone': phone,
        'website': website,
        'latitude': latitude,
        'longitude': longitude,
        'source': source,
        'submittedBy': submittedBy,
        'createdAt': FieldValue.serverTimestamp(),
      };

  // ── Service type metadata ───────────────────────────────────────

  static const Map<String, String> kServiceTypeLabels = {
    'inpatientRespite': 'Inpatient Respite',
    'adultDayCenter': 'Adult Day Center',
    'inHomeRespite': 'In-Home Respite',
    'hospiceRespite': 'Hospice Respite',
    'skilledNursing': 'Skilled Nursing',
    'communityProgram': 'Community Program',
    'supportGroup': 'Support Group',
    'other': 'Other',
  };

  static const Map<String, IconData> kServiceTypeIcons = {
    'inpatientRespite': Icons.local_hospital_outlined,
    'adultDayCenter': Icons.wb_sunny_outlined,
    'inHomeRespite': Icons.home_outlined,
    'hospiceRespite': Icons.favorite_border,
    'skilledNursing': Icons.medical_services_outlined,
    'communityProgram': Icons.groups_outlined,
    'supportGroup': Icons.people_outline,
    'other': Icons.more_horiz,
  };

  static const Map<String, Color> kServiceTypeColors = {
    'inpatientRespite': Color(0xFFE53935),
    'adultDayCenter': Color(0xFFF57C00),
    'inHomeRespite': Color(0xFF1E88E5),
    'hospiceRespite': Color(0xFF8E24AA),
    'skilledNursing': Color(0xFF00897B),
    'communityProgram': Color(0xFF43A047),
    'supportGroup': Color(0xFF5C6BC0),
    'other': Color(0xFF546E7A),
  };

  static const List<String> kAllServiceTypes = [
    'inpatientRespite',
    'adultDayCenter',
    'inHomeRespite',
    'hospiceRespite',
    'skilledNursing',
    'communityProgram',
    'supportGroup',
    'other',
  ];
}

// ---------------------------------------------------------------------------
// Bundled national resource directory
// ---------------------------------------------------------------------------

class RespiteResourceDirectory {
  RespiteResourceDirectory._();

  // ── National hotlines (always shown) ────────────────────────────

  static const List<RespiteProvider> kNationalHotlines = [
    RespiteProvider(
      id: 'hotline_eldercare',
      name: 'Eldercare Locator',
      organizationName: 'Administration for Community Living',
      description:
          'Connects older adults and caregivers to local support resources '
          'including respite care, transportation, and meal programs.',
      serviceTypes: ['communityProgram'],
      address: '',
      city: 'Washington',
      state: 'DC',
      zipCode: '20001',
      phone: '1-800-677-1116',
      website: 'https://eldercare.acl.gov',
      source: 'bundled',
    ),
    RespiteProvider(
      id: 'hotline_211',
      name: '211 (United Way)',
      organizationName: 'United Way Worldwide',
      description:
          'Dial 211 from any phone to connect with local health and human '
          'services including respite care, adult day programs, and caregiver support.',
      serviceTypes: ['communityProgram'],
      address: '',
      city: 'Alexandria',
      state: 'VA',
      zipCode: '22314',
      phone: '211',
      website: 'https://www.211.org',
      source: 'bundled',
    ),
    RespiteProvider(
      id: 'hotline_arch',
      name: 'ARCH National Respite Locator',
      organizationName: 'ARCH National Respite Network',
      description:
          'Specialized directory to help caregivers find respite services '
          'and funding in their area. Includes volunteer and professional respite.',
      serviceTypes: ['inHomeRespite', 'communityProgram'],
      address: '',
      city: 'Falls Church',
      state: 'VA',
      zipCode: '22042',
      phone: '703-256-2084',
      website: 'https://archrespite.org/respite-locator',
      source: 'bundled',
    ),
    RespiteProvider(
      id: 'hotline_alz',
      name: "Alzheimer's Association 24/7 Helpline",
      organizationName: "Alzheimer's Association",
      description:
          'Round-the-clock support for caregivers of people with dementia. '
          'Information on respite options, care techniques, and local resources.',
      serviceTypes: ['supportGroup', 'communityProgram'],
      address: '',
      city: 'Chicago',
      state: 'IL',
      zipCode: '60601',
      phone: '1-800-272-3900',
      website: 'https://www.alz.org/help-support/resources/helpline',
      source: 'bundled',
    ),
    RespiteProvider(
      id: 'hotline_va',
      name: 'VA Caregiver Support Line',
      organizationName: 'U.S. Department of Veterans Affairs',
      description:
          'Support for caregivers of veterans. Includes respite care benefits, '
          'training, and financial assistance programs.',
      serviceTypes: ['inHomeRespite', 'communityProgram'],
      address: '',
      city: 'Washington',
      state: 'DC',
      zipCode: '20420',
      phone: '1-855-260-3274',
      website: 'https://www.caregiver.va.gov',
      source: 'bundled',
    ),
    RespiteProvider(
      id: 'hotline_nac',
      name: 'National Alliance for Caregiving',
      organizationName: 'NAC',
      description:
          'Research and advocacy organization providing caregiver resources, '
          'best practice guides, and connections to local programs.',
      serviceTypes: ['supportGroup'],
      address: '',
      city: 'Washington',
      state: 'DC',
      zipCode: '20005',
      phone: '',
      website: 'https://www.caregiving.org',
      source: 'bundled',
    ),
  ];

  // ── State aging agencies (one per state) ────────────────────────

  static const List<RespiteProvider> kStateAgencies = [
    RespiteProvider(id: 'st_AL', name: 'Alabama Dept. of Senior Services', serviceTypes: ['communityProgram'], address: '201 Monroe St', city: 'Montgomery', state: 'AL', zipCode: '36104', phone: '1-877-425-2243', website: 'https://www.alabamaageline.gov', source: 'bundled'),
    RespiteProvider(id: 'st_AK', name: 'Alaska Commission on Aging', serviceTypes: ['communityProgram'], address: '150 Third St', city: 'Juneau', state: 'AK', zipCode: '99801', phone: '907-465-3250', website: 'https://health.alaska.gov/acoa', source: 'bundled'),
    RespiteProvider(id: 'st_AZ', name: 'Arizona Div. of Aging & Adult Services', serviceTypes: ['communityProgram'], address: '1789 W Jefferson St', city: 'Phoenix', state: 'AZ', zipCode: '85007', phone: '602-542-4446', website: 'https://des.az.gov/daas', source: 'bundled'),
    RespiteProvider(id: 'st_AR', name: 'Arkansas Div. of Aging, Adult & Behavioral Health', serviceTypes: ['communityProgram'], address: '700 Main St', city: 'Little Rock', state: 'AR', zipCode: '72201', phone: '501-682-2441', website: 'https://humanservices.arkansas.gov/divisions/aging-adult-behavioral-health-services', source: 'bundled'),
    RespiteProvider(id: 'st_CA', name: 'California Dept. of Aging', serviceTypes: ['communityProgram'], address: '2880 Gateway Oaks Dr', city: 'Sacramento', state: 'CA', zipCode: '95833', phone: '916-419-7500', website: 'https://aging.ca.gov', source: 'bundled'),
    RespiteProvider(id: 'st_CO', name: 'Colorado Div. of Aging & Adult Services', serviceTypes: ['communityProgram'], address: '1575 Sherman St', city: 'Denver', state: 'CO', zipCode: '80203', phone: '303-866-2800', website: 'https://cdhs.colorado.gov', source: 'bundled'),
    RespiteProvider(id: 'st_CT', name: 'Connecticut Aging & Disability Services', serviceTypes: ['communityProgram'], address: '55 Farmington Ave', city: 'Hartford', state: 'CT', zipCode: '06105', phone: '1-866-218-6631', website: 'https://portal.ct.gov/AgingandDisability', source: 'bundled'),
    RespiteProvider(id: 'st_DE', name: 'Delaware Div. of Services for Aging & Adults', serviceTypes: ['communityProgram'], address: '1901 N DuPont Hwy', city: 'New Castle', state: 'DE', zipCode: '19720', phone: '302-255-9390', website: 'https://dhss.delaware.gov/dsaapd', source: 'bundled'),
    RespiteProvider(id: 'st_FL', name: 'Florida Dept. of Elder Affairs', serviceTypes: ['communityProgram'], address: '4040 Esplanade Way', city: 'Tallahassee', state: 'FL', zipCode: '32399', phone: '1-800-963-5337', website: 'https://elderaffairs.org', source: 'bundled'),
    RespiteProvider(id: 'st_GA', name: 'Georgia Div. of Aging Services', serviceTypes: ['communityProgram'], address: '2 Peachtree St NW', city: 'Atlanta', state: 'GA', zipCode: '30303', phone: '1-866-552-4464', website: 'https://aging.georgia.gov', source: 'bundled'),
    RespiteProvider(id: 'st_HI', name: 'Hawaii Executive Office on Aging', serviceTypes: ['communityProgram'], address: '250 S Hotel St', city: 'Honolulu', state: 'HI', zipCode: '96813', phone: '808-586-0100', website: 'https://health.hawaii.gov/eoa', source: 'bundled'),
    RespiteProvider(id: 'st_ID', name: 'Idaho Commission on Aging', serviceTypes: ['communityProgram'], address: '341 W Washington St', city: 'Boise', state: 'ID', zipCode: '83702', phone: '208-334-3833', website: 'https://aging.idaho.gov', source: 'bundled'),
    RespiteProvider(id: 'st_IL', name: 'Illinois Dept. on Aging', serviceTypes: ['communityProgram'], address: '160 N LaSalle St', city: 'Chicago', state: 'IL', zipCode: '60601', phone: '1-800-252-8966', website: 'https://ilaging.illinois.gov', source: 'bundled'),
    RespiteProvider(id: 'st_IN', name: 'Indiana Div. of Aging', serviceTypes: ['communityProgram'], address: '402 W Washington St', city: 'Indianapolis', state: 'IN', zipCode: '46204', phone: '1-888-673-0002', website: 'https://www.in.gov/fssa/da', source: 'bundled'),
    RespiteProvider(id: 'st_IA', name: 'Iowa Dept. on Aging', serviceTypes: ['communityProgram'], address: '510 E 12th St', city: 'Des Moines', state: 'IA', zipCode: '50319', phone: '1-800-532-3213', website: 'https://aging.iowa.gov', source: 'bundled'),
    RespiteProvider(id: 'st_KS', name: 'Kansas Dept. for Aging & Disability Services', serviceTypes: ['communityProgram'], address: '503 S Kansas Ave', city: 'Topeka', state: 'KS', zipCode: '66603', phone: '1-800-432-3535', website: 'https://www.kdads.ks.gov', source: 'bundled'),
    RespiteProvider(id: 'st_KY', name: 'Kentucky Dept. for Aging & Independent Living', serviceTypes: ['communityProgram'], address: '275 E Main St', city: 'Frankfort', state: 'KY', zipCode: '40621', phone: '502-564-6930', website: 'https://chfs.ky.gov/agencies/dail', source: 'bundled'),
    RespiteProvider(id: 'st_LA', name: 'Louisiana Office of Aging & Adult Services', serviceTypes: ['communityProgram'], address: '628 N 4th St', city: 'Baton Rouge', state: 'LA', zipCode: '70802', phone: '1-866-758-5035', website: 'http://goea.louisiana.gov', source: 'bundled'),
    RespiteProvider(id: 'st_ME', name: 'Maine Office of Aging & Disability Services', serviceTypes: ['communityProgram'], address: '41 Anthony Ave', city: 'Augusta', state: 'ME', zipCode: '04333', phone: '1-800-262-2232', website: 'https://www.maine.gov/dhhs/oads', source: 'bundled'),
    RespiteProvider(id: 'st_MD', name: 'Maryland Dept. of Aging', serviceTypes: ['communityProgram'], address: '301 W Preston St', city: 'Baltimore', state: 'MD', zipCode: '21201', phone: '1-800-243-3425', website: 'https://aging.maryland.gov', source: 'bundled'),
    RespiteProvider(id: 'st_MA', name: 'Massachusetts Executive Office of Elder Affairs', serviceTypes: ['communityProgram'], address: '1 Ashburton Pl', city: 'Boston', state: 'MA', zipCode: '02108', phone: '1-800-243-4636', website: 'https://www.mass.gov/orgs/executive-office-of-elder-affairs', source: 'bundled'),
    RespiteProvider(id: 'st_MI', name: 'Michigan Aging & Adult Services Agency', serviceTypes: ['communityProgram'], address: '333 S Grand Ave', city: 'Lansing', state: 'MI', zipCode: '48909', phone: '517-241-4100', website: 'https://www.michigan.gov/mdhhs', source: 'bundled'),
    RespiteProvider(id: 'st_MN', name: 'Minnesota Board on Aging', serviceTypes: ['communityProgram'], address: '540 Cedar St', city: 'Saint Paul', state: 'MN', zipCode: '55101', phone: '1-800-333-2433', website: 'https://mn.gov/board-on-aging', source: 'bundled'),
    RespiteProvider(id: 'st_MS', name: 'Mississippi Div. of Aging & Adult Services', serviceTypes: ['communityProgram'], address: '200 S Lamar St', city: 'Jackson', state: 'MS', zipCode: '39201', phone: '1-800-948-3090', website: 'https://www.mdhs.ms.gov/adults-seniors', source: 'bundled'),
    RespiteProvider(id: 'st_MO', name: 'Missouri Div. of Senior & Disability Services', serviceTypes: ['communityProgram'], address: '912 Wildwood Dr', city: 'Jefferson City', state: 'MO', zipCode: '65109', phone: '573-526-3626', website: 'https://health.mo.gov/seniors', source: 'bundled'),
    RespiteProvider(id: 'st_MT', name: 'Montana Senior & Long-Term Care Div.', serviceTypes: ['communityProgram'], address: '111 N Sanders St', city: 'Helena', state: 'MT', zipCode: '59601', phone: '1-800-551-3191', website: 'https://dphhs.mt.gov/sltc', source: 'bundled'),
    RespiteProvider(id: 'st_NE', name: 'Nebraska Dept. of Health & Human Services — Aging', serviceTypes: ['communityProgram'], address: '301 Centennial Mall S', city: 'Lincoln', state: 'NE', zipCode: '68508', phone: '1-800-942-7830', website: 'https://dhhs.ne.gov/Pages/Aging.aspx', source: 'bundled'),
    RespiteProvider(id: 'st_NV', name: 'Nevada Aging & Disability Services Div.', serviceTypes: ['communityProgram'], address: '3416 Goni Rd', city: 'Carson City', state: 'NV', zipCode: '89706', phone: '775-687-4210', website: 'https://adsd.nv.gov', source: 'bundled'),
    RespiteProvider(id: 'st_NH', name: 'New Hampshire Bureau of Elderly & Adult Services', serviceTypes: ['communityProgram'], address: '129 Pleasant St', city: 'Concord', state: 'NH', zipCode: '03301', phone: '1-800-351-1888', website: 'https://www.dhhs.nh.gov/programs-services/adult-aging-care', source: 'bundled'),
    RespiteProvider(id: 'st_NJ', name: 'New Jersey Div. of Aging Services', serviceTypes: ['communityProgram'], address: '240 W State St', city: 'Trenton', state: 'NJ', zipCode: '08625', phone: '1-877-222-3737', website: 'https://www.nj.gov/humanservices/doas', source: 'bundled'),
    RespiteProvider(id: 'st_NM', name: 'New Mexico Aging & Long-Term Services Dept.', serviceTypes: ['communityProgram'], address: '2550 Cerrillos Rd', city: 'Santa Fe', state: 'NM', zipCode: '87505', phone: '1-866-451-2901', website: 'https://www.nmaging.state.nm.us', source: 'bundled'),
    RespiteProvider(id: 'st_NY', name: 'New York State Office for the Aging', serviceTypes: ['communityProgram'], address: '2 Empire State Plaza', city: 'Albany', state: 'NY', zipCode: '12223', phone: '1-800-342-9871', website: 'https://aging.ny.gov', source: 'bundled'),
    RespiteProvider(id: 'st_NC', name: 'North Carolina Div. of Aging & Adult Services', serviceTypes: ['communityProgram'], address: '693 Palmer Dr', city: 'Raleigh', state: 'NC', zipCode: '27603', phone: '919-855-3400', website: 'https://www.ncdhhs.gov/divisions/aging-and-adult-services', source: 'bundled'),
    RespiteProvider(id: 'st_ND', name: 'North Dakota Aging Services Div.', serviceTypes: ['communityProgram'], address: '1237 W Divide Ave', city: 'Bismarck', state: 'ND', zipCode: '58501', phone: '1-855-462-5465', website: 'https://www.nd.gov/dhs/services/adultsaging', source: 'bundled'),
    RespiteProvider(id: 'st_OH', name: 'Ohio Dept. of Aging', serviceTypes: ['communityProgram'], address: '246 N High St', city: 'Columbus', state: 'OH', zipCode: '43215', phone: '1-800-266-4346', website: 'https://aging.ohio.gov', source: 'bundled'),
    RespiteProvider(id: 'st_OK', name: 'Oklahoma Aging Services Div.', serviceTypes: ['communityProgram'], address: '2401 NW 23rd St', city: 'Oklahoma City', state: 'OK', zipCode: '73107', phone: '405-521-2327', website: 'https://oklahoma.gov/okdhs/services/aging.html', source: 'bundled'),
    RespiteProvider(id: 'st_OR', name: 'Oregon Aging & People with Disabilities', serviceTypes: ['communityProgram'], address: '500 Summer St NE', city: 'Salem', state: 'OR', zipCode: '97301', phone: '1-800-282-8096', website: 'https://www.oregon.gov/odhs/aging', source: 'bundled'),
    RespiteProvider(id: 'st_PA', name: 'Pennsylvania Dept. of Aging', serviceTypes: ['communityProgram'], address: '555 Walnut St', city: 'Harrisburg', state: 'PA', zipCode: '17101', phone: '717-783-1550', website: 'https://www.aging.pa.gov', source: 'bundled'),
    RespiteProvider(id: 'st_RI', name: 'Rhode Island Div. of Elderly Affairs', serviceTypes: ['communityProgram'], address: '57 Howard Ave', city: 'Cranston', state: 'RI', zipCode: '02920', phone: '401-462-3000', website: 'https://oha.ri.gov/programs-and-services/elderly-affairs', source: 'bundled'),
    RespiteProvider(id: 'st_SC', name: 'South Carolina Lt. Governor Office on Aging', serviceTypes: ['communityProgram'], address: '1205 Pendleton St', city: 'Columbia', state: 'SC', zipCode: '29201', phone: '1-800-868-9095', website: 'https://aging.sc.gov', source: 'bundled'),
    RespiteProvider(id: 'st_SD', name: 'South Dakota Aging & Disability Services', serviceTypes: ['communityProgram'], address: '700 Governors Dr', city: 'Pierre', state: 'SD', zipCode: '57501', phone: '605-773-3165', website: 'https://dhs.sd.gov/long-term-services-and-supports', source: 'bundled'),
    RespiteProvider(id: 'st_TN', name: 'Tennessee Commission on Aging & Disability', serviceTypes: ['communityProgram'], address: '502 Deaderick St', city: 'Nashville', state: 'TN', zipCode: '37243', phone: '615-741-2056', website: 'https://www.tn.gov/aging.html', source: 'bundled'),
    RespiteProvider(id: 'st_TX', name: 'Texas Health & Human Services — Aging', serviceTypes: ['communityProgram'], address: '701 W 51st St', city: 'Austin', state: 'TX', zipCode: '78751', phone: '1-855-937-2372', website: 'https://www.hhs.texas.gov/services/aging', source: 'bundled'),
    RespiteProvider(id: 'st_UT', name: 'Utah Div. of Aging & Adult Services', serviceTypes: ['communityProgram'], address: '195 N 1950 W', city: 'Salt Lake City', state: 'UT', zipCode: '84116', phone: '1-877-424-4640', website: 'https://daas.utah.gov', source: 'bundled'),
    RespiteProvider(id: 'st_VT', name: 'Vermont Dept. of Disabilities, Aging & Independent Living', serviceTypes: ['communityProgram'], address: '280 State Dr', city: 'Waterbury', state: 'VT', zipCode: '05671', phone: '802-241-2401', website: 'https://dail.vermont.gov', source: 'bundled'),
    RespiteProvider(id: 'st_VA', name: 'Virginia Dept. for Aging & Rehabilitative Services', serviceTypes: ['communityProgram'], address: '8004 Franklin Farms Dr', city: 'Henrico', state: 'VA', zipCode: '23229', phone: '1-800-552-3402', website: 'https://www.dars.virginia.gov', source: 'bundled'),
    RespiteProvider(id: 'st_WA', name: 'Washington Aging & Long-Term Support Admin.', serviceTypes: ['communityProgram'], address: '626 8th Ave SE', city: 'Olympia', state: 'WA', zipCode: '98501', phone: '1-800-422-3263', website: 'https://www.dshs.wa.gov/altsa', source: 'bundled'),
    RespiteProvider(id: 'st_WV', name: 'West Virginia Bureau of Senior Services', serviceTypes: ['communityProgram'], address: '1900 Kanawha Blvd E', city: 'Charleston', state: 'WV', zipCode: '25305', phone: '304-558-3317', website: 'https://boss.wv.gov', source: 'bundled'),
    RespiteProvider(id: 'st_WI', name: 'Wisconsin Bureau of Aging & Disability Resources', serviceTypes: ['communityProgram'], address: '1 W Wilson St', city: 'Madison', state: 'WI', zipCode: '53703', phone: '608-266-2536', website: 'https://www.dhs.wisconsin.gov/aging', source: 'bundled'),
    RespiteProvider(id: 'st_WY', name: 'Wyoming Aging Div.', serviceTypes: ['communityProgram'], address: '2300 Capitol Ave', city: 'Cheyenne', state: 'WY', zipCode: '82002', phone: '1-800-442-2766', website: 'https://health.wyo.gov/aging', source: 'bundled'),
  ];

  // ── ZIP prefix → state mapping (first 3 digits) ────────────────
  static const Map<String, String> _zipPrefixToState = {
    '005': 'NY', '006': 'PR', '007': 'PR', '008': 'VI', '009': 'PR',
    '010': 'MA', '011': 'MA', '012': 'MA', '013': 'MA', '014': 'MA', '015': 'MA', '016': 'MA', '017': 'MA', '018': 'MA', '019': 'MA',
    '020': 'MA', '021': 'MA', '022': 'MA', '023': 'MA', '024': 'MA', '025': 'MA', '026': 'MA', '027': 'MA',
    '028': 'RI', '029': 'RI',
    '030': 'NH', '031': 'NH', '032': 'NH', '033': 'NH', '034': 'NH', '035': 'NH', '036': 'NH', '037': 'NH', '038': 'NH',
    '039': 'ME', '040': 'ME', '041': 'ME', '042': 'ME', '043': 'ME', '044': 'ME', '045': 'ME', '046': 'ME', '047': 'ME', '048': 'ME', '049': 'ME',
    '050': 'VT', '051': 'VT', '052': 'VT', '053': 'VT', '054': 'VT', '056': 'VT', '057': 'VT', '058': 'VT', '059': 'VT',
    '060': 'CT', '061': 'CT', '062': 'CT', '063': 'CT', '064': 'CT', '065': 'CT', '066': 'CT', '067': 'CT', '068': 'CT', '069': 'CT',
    '070': 'NJ', '071': 'NJ', '072': 'NJ', '073': 'NJ', '074': 'NJ', '075': 'NJ', '076': 'NJ', '077': 'NJ', '078': 'NJ', '079': 'NJ', '080': 'NJ', '081': 'NJ', '082': 'NJ', '083': 'NJ', '084': 'NJ', '085': 'NJ', '086': 'NJ', '087': 'NJ', '088': 'NJ', '089': 'NJ',
    '100': 'NY', '101': 'NY', '102': 'NY', '103': 'NY', '104': 'NY', '105': 'NY', '106': 'NY', '107': 'NY', '108': 'NY', '109': 'NY',
    '110': 'NY', '111': 'NY', '112': 'NY', '113': 'NY', '114': 'NY', '115': 'NY', '116': 'NY', '117': 'NY', '118': 'NY', '119': 'NY',
    '120': 'NY', '121': 'NY', '122': 'NY', '123': 'NY', '124': 'NY', '125': 'NY', '126': 'NY', '127': 'NY', '128': 'NY', '129': 'NY',
    '130': 'NY', '131': 'NY', '132': 'NY', '133': 'NY', '134': 'NY', '135': 'NY', '136': 'NY', '137': 'NY', '138': 'NY', '139': 'NY', '140': 'NY', '141': 'NY', '142': 'NY', '143': 'NY', '144': 'NY', '145': 'NY', '146': 'NY', '147': 'NY', '148': 'NY', '149': 'NY',
    '150': 'PA', '151': 'PA', '152': 'PA', '153': 'PA', '154': 'PA', '155': 'PA', '156': 'PA', '157': 'PA', '158': 'PA', '159': 'PA',
    '160': 'PA', '161': 'PA', '162': 'PA', '163': 'PA', '164': 'PA', '165': 'PA', '166': 'PA', '167': 'PA', '168': 'PA', '169': 'PA',
    '170': 'PA', '171': 'PA', '172': 'PA', '173': 'PA', '174': 'PA', '175': 'PA', '176': 'PA', '177': 'PA', '178': 'PA', '179': 'PA',
    '180': 'PA', '181': 'PA', '182': 'PA', '183': 'PA', '184': 'PA', '185': 'PA', '186': 'PA', '187': 'PA', '188': 'PA', '189': 'PA', '190': 'PA', '191': 'PA', '192': 'PA', '193': 'PA', '194': 'PA', '195': 'PA', '196': 'PA',
    '197': 'DE', '198': 'DE', '199': 'DE',
    '200': 'DC', '201': 'VA', '202': 'DC', '203': 'DC', '204': 'DC', '205': 'DC',
    '206': 'MD', '207': 'MD', '208': 'MD', '209': 'MD', '210': 'MD', '211': 'MD', '212': 'MD', '214': 'MD', '215': 'MD', '216': 'MD', '217': 'MD', '218': 'MD', '219': 'MD',
    '220': 'VA', '221': 'VA', '222': 'VA', '223': 'VA', '224': 'VA', '225': 'VA', '226': 'VA', '227': 'VA', '228': 'VA', '229': 'VA',
    '230': 'VA', '231': 'VA', '232': 'VA', '233': 'VA', '234': 'VA', '235': 'VA', '236': 'VA', '237': 'VA', '238': 'VA', '239': 'VA',
    '240': 'VA', '241': 'VA', '242': 'VA', '243': 'VA', '244': 'VA', '245': 'VA', '246': 'VA',
    '247': 'WV', '248': 'WV', '249': 'WV', '250': 'WV', '251': 'WV', '252': 'WV', '253': 'WV', '254': 'WV', '255': 'WV', '256': 'WV', '257': 'WV', '258': 'WV', '259': 'WV', '260': 'WV', '261': 'WV', '262': 'WV', '263': 'WV', '264': 'WV', '265': 'WV', '266': 'WV', '267': 'WV', '268': 'WV',
    '270': 'NC', '271': 'NC', '272': 'NC', '273': 'NC', '274': 'NC', '275': 'NC', '276': 'NC', '277': 'NC', '278': 'NC', '279': 'NC', '280': 'NC', '281': 'NC', '282': 'NC', '283': 'NC', '284': 'NC', '285': 'NC', '286': 'NC', '287': 'NC', '288': 'NC', '289': 'NC',
    '290': 'SC', '291': 'SC', '292': 'SC', '293': 'SC', '294': 'SC', '295': 'SC', '296': 'SC', '297': 'SC', '298': 'SC', '299': 'SC',
    '300': 'GA', '301': 'GA', '302': 'GA', '303': 'GA', '304': 'GA', '305': 'GA', '306': 'GA', '307': 'GA', '308': 'GA', '309': 'GA',
    '310': 'GA', '311': 'GA', '312': 'GA', '313': 'GA', '314': 'GA', '315': 'GA', '316': 'GA', '317': 'GA', '318': 'GA', '319': 'GA',
    '320': 'FL', '321': 'FL', '322': 'FL', '323': 'FL', '324': 'FL', '325': 'FL', '326': 'FL', '327': 'FL', '328': 'FL', '329': 'FL',
    '330': 'FL', '331': 'FL', '332': 'FL', '333': 'FL', '334': 'FL', '335': 'FL', '336': 'FL', '337': 'FL', '338': 'FL', '339': 'FL',
    '340': 'FL',
    '350': 'AL', '351': 'AL', '352': 'AL', '354': 'AL', '355': 'AL', '356': 'AL', '357': 'AL', '358': 'AL', '359': 'AL', '360': 'AL', '361': 'AL', '362': 'AL', '363': 'AL', '364': 'AL', '365': 'AL', '366': 'AL', '367': 'AL', '368': 'AL', '369': 'AL',
    '370': 'TN', '371': 'TN', '372': 'TN', '373': 'TN', '374': 'TN', '375': 'TN', '376': 'TN', '377': 'TN', '378': 'TN', '379': 'TN', '380': 'TN', '381': 'TN', '382': 'TN', '383': 'TN', '384': 'TN', '385': 'TN',
    '386': 'MS', '387': 'MS', '388': 'MS', '389': 'MS', '390': 'MS', '391': 'MS', '392': 'MS', '393': 'MS', '394': 'MS', '395': 'MS', '396': 'MS', '397': 'MS',
    '400': 'KY', '401': 'KY', '402': 'KY', '403': 'KY', '404': 'KY', '405': 'KY', '406': 'KY', '407': 'KY', '408': 'KY', '409': 'KY',
    '410': 'KY', '411': 'KY', '412': 'KY', '413': 'KY', '414': 'KY', '415': 'KY', '416': 'KY', '417': 'KY', '418': 'KY',
    '430': 'OH', '431': 'OH', '432': 'OH', '433': 'OH', '434': 'OH', '435': 'OH', '436': 'OH', '437': 'OH', '438': 'OH', '439': 'OH',
    '440': 'OH', '441': 'OH', '442': 'OH', '443': 'OH', '444': 'OH', '445': 'OH', '446': 'OH', '447': 'OH', '448': 'OH', '449': 'OH',
    '450': 'OH', '451': 'OH', '452': 'OH', '453': 'OH', '454': 'OH', '455': 'OH', '456': 'OH', '457': 'OH', '458': 'OH',
    '460': 'IN', '461': 'IN', '462': 'IN', '463': 'IN', '464': 'IN', '465': 'IN', '466': 'IN', '467': 'IN', '468': 'IN', '469': 'IN', '470': 'IN', '471': 'IN', '472': 'IN', '473': 'IN', '474': 'IN', '475': 'IN', '476': 'IN', '477': 'IN', '478': 'IN', '479': 'IN',
    '480': 'MI', '481': 'MI', '482': 'MI', '483': 'MI', '484': 'MI', '485': 'MI', '486': 'MI', '487': 'MI', '488': 'MI', '489': 'MI',
    '490': 'MI', '491': 'MI', '492': 'MI', '493': 'MI', '494': 'MI', '495': 'MI', '496': 'MI', '497': 'MI', '498': 'MI', '499': 'MI',
    '500': 'IA', '501': 'IA', '502': 'IA', '503': 'IA', '504': 'IA', '505': 'IA', '506': 'IA', '507': 'IA', '508': 'IA', '509': 'IA',
    '510': 'IA', '511': 'IA', '512': 'IA', '513': 'IA', '514': 'IA', '515': 'IA', '516': 'IA', '520': 'IA', '521': 'IA', '522': 'IA', '523': 'IA', '524': 'IA', '525': 'IA', '526': 'IA', '527': 'IA', '528': 'IA',
    '530': 'WI', '531': 'WI', '532': 'WI', '534': 'WI', '535': 'WI', '537': 'WI', '538': 'WI', '539': 'WI', '540': 'WI', '541': 'WI', '542': 'WI', '543': 'WI', '544': 'WI', '545': 'WI', '546': 'WI', '547': 'WI', '548': 'WI', '549': 'WI',
    '550': 'MN', '551': 'MN', '553': 'MN', '554': 'MN', '555': 'MN', '556': 'MN', '557': 'MN', '558': 'MN', '559': 'MN', '560': 'MN', '561': 'MN', '562': 'MN', '563': 'MN', '564': 'MN', '565': 'MN', '566': 'MN', '567': 'MN',
    '570': 'SD', '571': 'SD', '572': 'SD', '573': 'SD', '574': 'SD', '575': 'SD', '576': 'SD', '577': 'SD',
    '580': 'ND', '581': 'ND', '582': 'ND', '583': 'ND', '584': 'ND', '585': 'ND', '586': 'ND', '587': 'ND', '588': 'ND',
    '590': 'MT', '591': 'MT', '592': 'MT', '593': 'MT', '594': 'MT', '595': 'MT', '596': 'MT', '597': 'MT', '598': 'MT', '599': 'MT',
    '600': 'IL', '601': 'IL', '602': 'IL', '603': 'IL', '604': 'IL', '605': 'IL', '606': 'IL', '607': 'IL', '608': 'IL', '609': 'IL',
    '610': 'IL', '611': 'IL', '612': 'IL', '613': 'IL', '614': 'IL', '615': 'IL', '616': 'IL', '617': 'IL', '618': 'IL', '619': 'IL',
    '620': 'IL', '622': 'IL', '623': 'IL', '624': 'IL', '625': 'IL', '626': 'IL', '627': 'IL', '628': 'IL', '629': 'IL',
    '630': 'MO', '631': 'MO', '633': 'MO', '634': 'MO', '635': 'MO', '636': 'MO', '637': 'MO', '638': 'MO', '639': 'MO',
    '640': 'KS', '641': 'MO', '644': 'MO', '645': 'MO', '646': 'MO', '647': 'MO', '648': 'MO', '649': 'MO', '650': 'MO', '651': 'MO', '652': 'MO', '653': 'MO', '654': 'MO', '655': 'MO', '656': 'MO', '657': 'MO', '658': 'MO',
    '660': 'KS', '661': 'KS', '662': 'KS', '664': 'KS', '665': 'KS', '666': 'KS', '667': 'KS', '668': 'KS', '669': 'KS', '670': 'KS', '671': 'KS', '672': 'KS', '673': 'KS', '674': 'KS', '675': 'KS', '676': 'KS', '677': 'KS', '678': 'KS', '679': 'KS',
    '680': 'NE', '681': 'NE', '683': 'NE', '684': 'NE', '685': 'NE', '686': 'NE', '687': 'NE', '688': 'NE', '689': 'NE', '690': 'NE', '691': 'NE', '692': 'NE', '693': 'NE',
    '700': 'LA', '701': 'LA', '703': 'LA', '704': 'LA', '705': 'LA', '706': 'LA', '707': 'LA', '708': 'LA', '710': 'LA', '711': 'LA', '712': 'LA', '713': 'LA', '714': 'LA',
    '716': 'AR', '717': 'AR', '718': 'AR', '719': 'AR', '720': 'AR', '721': 'AR', '722': 'AR', '723': 'AR', '724': 'AR', '725': 'AR', '726': 'AR', '727': 'AR', '728': 'AR', '729': 'AR',
    '730': 'OK', '731': 'OK', '734': 'OK', '735': 'OK', '736': 'OK', '737': 'OK', '738': 'OK', '739': 'OK', '740': 'OK', '741': 'OK', '743': 'OK', '744': 'OK', '745': 'OK', '746': 'OK', '747': 'OK', '748': 'OK', '749': 'OK',
    '750': 'TX', '751': 'TX', '752': 'TX', '753': 'TX', '754': 'TX', '755': 'TX', '756': 'TX', '757': 'TX', '758': 'TX', '759': 'TX',
    '760': 'TX', '761': 'TX', '762': 'TX', '763': 'TX', '764': 'TX', '765': 'TX', '766': 'TX', '767': 'TX', '768': 'TX', '769': 'TX',
    '770': 'TX', '771': 'TX', '772': 'TX', '773': 'TX', '774': 'TX', '775': 'TX', '776': 'TX', '777': 'TX', '778': 'TX', '779': 'TX',
    '780': 'TX', '781': 'TX', '782': 'TX', '783': 'TX', '784': 'TX', '785': 'TX', '786': 'TX', '787': 'TX', '788': 'TX', '789': 'TX', '790': 'TX', '791': 'TX', '792': 'TX', '793': 'TX', '794': 'TX', '795': 'TX', '796': 'TX', '797': 'TX', '798': 'TX', '799': 'TX',
    '800': 'CO', '801': 'CO', '802': 'CO', '803': 'CO', '804': 'CO', '805': 'CO', '806': 'CO', '807': 'CO', '808': 'CO', '809': 'CO', '810': 'CO', '811': 'CO', '812': 'CO', '813': 'CO', '814': 'CO', '815': 'CO', '816': 'CO',
    '820': 'WY', '821': 'WY', '822': 'WY', '823': 'WY', '824': 'WY', '825': 'WY', '826': 'WY', '827': 'WY', '828': 'WY', '829': 'WY', '830': 'WY', '831': 'WY',
    '832': 'ID', '833': 'ID', '834': 'ID', '835': 'ID', '836': 'ID', '837': 'ID', '838': 'ID',
    '840': 'UT', '841': 'UT', '842': 'UT', '843': 'UT', '844': 'UT', '845': 'UT', '846': 'UT', '847': 'UT',
    '850': 'AZ', '852': 'AZ', '853': 'AZ', '855': 'AZ', '856': 'AZ', '857': 'AZ', '859': 'AZ', '860': 'AZ', '863': 'AZ', '864': 'AZ', '865': 'AZ',
    '870': 'NM', '871': 'NM', '873': 'NM', '874': 'NM', '875': 'NM', '877': 'NM', '878': 'NM', '879': 'NM', '880': 'NM', '881': 'NM', '882': 'NM', '883': 'NM', '884': 'NM',
    '889': 'NV', '890': 'NV', '891': 'NV', '893': 'NV', '894': 'NV', '895': 'NV', '897': 'NV', '898': 'NV',
    '900': 'CA', '901': 'CA', '902': 'CA', '903': 'CA', '904': 'CA', '905': 'CA', '906': 'CA', '907': 'CA', '908': 'CA', '910': 'CA', '911': 'CA', '912': 'CA', '913': 'CA', '914': 'CA', '915': 'CA', '916': 'CA', '917': 'CA', '918': 'CA', '919': 'CA',
    '920': 'CA', '921': 'CA', '922': 'CA', '923': 'CA', '924': 'CA', '925': 'CA', '926': 'CA', '927': 'CA', '928': 'CA',
    '930': 'CA', '931': 'CA', '932': 'CA', '933': 'CA', '934': 'CA', '935': 'CA', '936': 'CA', '937': 'CA', '938': 'CA', '939': 'CA',
    '940': 'CA', '941': 'CA', '942': 'CA', '943': 'CA', '944': 'CA', '945': 'CA', '946': 'CA', '947': 'CA', '948': 'CA', '949': 'CA',
    '950': 'CA', '951': 'CA', '952': 'CA', '953': 'CA', '954': 'CA', '955': 'CA', '956': 'CA', '957': 'CA', '958': 'CA', '959': 'CA', '960': 'CA', '961': 'CA',
    '967': 'HI', '968': 'HI',
    '970': 'OR', '971': 'OR', '972': 'OR', '973': 'OR', '974': 'OR', '975': 'OR', '976': 'OR', '977': 'OR', '978': 'OR', '979': 'OR',
    '980': 'WA', '981': 'WA', '982': 'WA', '983': 'WA', '984': 'WA', '985': 'WA', '986': 'WA', '988': 'WA', '989': 'WA', '990': 'WA', '991': 'WA', '992': 'WA', '993': 'WA', '994': 'WA',
    '995': 'AK', '996': 'AK', '997': 'AK', '998': 'AK', '999': 'AK',
  };

  /// Searches bundled data by ZIP code — returns state agency + hotlines.
  static List<RespiteProvider> searchByZip(String zip) {
    if (zip.length < 3) return [...kNationalHotlines];
    final prefix = zip.substring(0, 3);
    final stateCode = _zipPrefixToState[prefix];
    if (stateCode == null) return [...kNationalHotlines];
    return [
      ...kStateAgencies.where((a) => a.state == stateCode),
      ...kNationalHotlines,
    ];
  }

  /// Returns all bundled providers for a state.
  static List<RespiteProvider> searchByState(String stateCode) {
    return kStateAgencies.where((a) => a.state == stateCode).toList();
  }
}
