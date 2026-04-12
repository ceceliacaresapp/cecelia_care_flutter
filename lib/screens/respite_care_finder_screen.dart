// lib/screens/respite_care_finder_screen.dart
//
// ZIP-code search for local respite care services. Queries CMS Socrata
// API (free), bundled state agencies, and Firestore crowdsourced providers.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/respite_provider.dart';
import 'package:cecelia_care_flutter/services/respite_care_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class RespiteCareFinderScreen extends StatefulWidget {
  const RespiteCareFinderScreen({super.key});

  @override
  State<RespiteCareFinderScreen> createState() =>
      _RespiteCareFinderScreenState();
}

class _RespiteCareFinderScreenState extends State<RespiteCareFinderScreen> {
  final _zipCtrl = TextEditingController();
  bool _isSearching = false;
  bool _hasSearched = false;
  List<RespiteProvider> _clinical = [];
  List<RespiteProvider> _community = [];
  List<RespiteProvider> _national = [];
  String? _error;

  static const _kAccent = AppTheme.tileTeal;

  @override
  void dispose() {
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final zip = _zipCtrl.text.trim();
    if (zip.length < 5) {
      setState(() => _error = 'Enter a valid 5-digit ZIP code');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final results = await RespiteCareService.instance.search(zip);

      final clinical = <RespiteProvider>[];
      final community = <RespiteProvider>[];
      final national = <RespiteProvider>[];

      for (final r in results) {
        if (r.source == 'bundled' && r.id.startsWith('hotline_')) {
          national.add(r);
        } else if (r.source == 'cms_api') {
          clinical.add(r);
        } else if (r.source == 'user_submitted') {
          community.add(r);
        } else {
          // Bundled state agencies go to community
          community.add(r);
        }
      }

      if (mounted) {
        setState(() {
          _clinical = clinical;
          _community = community;
          _national = national;
          _hasSearched = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Search failed. Showing offline results.';
          _isSearching = false;
          _hasSearched = true;
          _clinical = [];
          _community = [];
          _national = [...RespiteResourceDirectory.kNationalHotlines];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respite Care Finder'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceForm(context),
        backgroundColor: _kAccent,
        child: const Icon(Icons.add_location_alt_outlined,
            color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        children: [
          // Search bar
          _SearchBar(
            controller: _zipCtrl,
            isSearching: _isSearching,
            onSearch: _search,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    color: AppTheme.dangerColor, fontSize: 12)),
          ],
          const SizedBox(height: 16),

          // Results
          if (!_hasSearched && !_isSearching) ...[
            _InfoCard(),
          ],

          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),

          if (_hasSearched && !_isSearching) ...[
            // Clinical facilities
            if (_clinical.isNotEmpty) ...[
              _SectionHeader(
                title: 'Clinical Facilities',
                subtitle: '${_clinical.length} Medicare-verified',
                icon: Icons.local_hospital_outlined,
                color: AppTheme.statusRed,
              ),
              const SizedBox(height: 8),
              ..._clinical.map((p) => _ProviderCard(provider: p)),
              const SizedBox(height: 20),
            ],

            // Community services
            if (_community.isNotEmpty) ...[
              _SectionHeader(
                title: 'Community Services',
                subtitle: '${_community.length} local resources',
                icon: Icons.groups_outlined,
                color: _kAccent,
              ),
              const SizedBox(height: 8),
              ..._community.map((p) => _ProviderCard(provider: p)),
              const SizedBox(height: 20),
            ],

            // No clinical/community results
            if (_clinical.isEmpty && _community.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.search_off_outlined,
                        size: 36, color: AppTheme.textLight),
                    const SizedBox(height: 8),
                    Text(
                      'No local services found near ${_zipCtrl.text}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a nearby ZIP code, or browse the national '
                      'resources below.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // National resources (always shown)
            _SectionHeader(
              title: 'National Resources',
              subtitle: 'Hotlines & directories',
              icon: Icons.phone_in_talk_outlined,
              color: AppTheme.tilePurple,
            ),
            const SizedBox(height: 8),
            ..._national.map((p) => _ProviderCard(provider: p)),
          ],
        ],
      ),
    );
  }

  // ── Add a service form ──────────────────────────────────────────
  void _showAddServiceForm(BuildContext context) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final zipCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final selectedTypes = <String>{};
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Suggest a Service',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help other caregivers by adding a local respite '
                    'service you know about.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: _inputDeco('Service name *'),
                  ),
                  const SizedBox(height: 10),

                  // Service type chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: RespiteProvider.kAllServiceTypes.map((type) {
                      final selected = selectedTypes.contains(type);
                      final color = RespiteProvider.kServiceTypeColors[type] ??
                          AppTheme.textSecondary;
                      return GestureDetector(
                        onTap: () => setSheetState(() {
                          if (selected) {
                            selectedTypes.remove(type);
                          } else {
                            selectedTypes.add(type);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : AppTheme.textLight.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            RespiteProvider.kServiceTypeLabels[type] ?? type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color:
                                  selected ? color : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
                    decoration: _inputDeco('Street address *'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: cityCtrl,
                        decoration: _inputDeco('City *'),
                      )),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: stateCtrl,
                          decoration: _inputDeco('State'),
                          maxLength: 2,
                          textCapitalization: TextCapitalization.characters,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: zipCtrl,
                          decoration: _inputDeco('ZIP *'),
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                        controller: phoneCtrl,
                        decoration: _inputDeco('Phone'),
                        keyboardType: TextInputType.phone,
                      )),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                        controller: websiteCtrl,
                        decoration: _inputDeco('Website'),
                        keyboardType: TextInputType.url,
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: _inputDeco('Description (optional)'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final addr = addressCtrl.text.trim();
                              final city = cityCtrl.text.trim();
                              final zip = zipCtrl.text.trim();
                              if (name.isEmpty ||
                                  addr.isEmpty ||
                                  city.isEmpty ||
                                  zip.length < 5) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Fill in name, address, city, and ZIP')),
                                );
                                return;
                              }
                              setSheetState(() => isSaving = true);
                              try {
                                final user =
                                    FirebaseAuth.instance.currentUser;
                                final provider = RespiteProvider(
                                  id: '',
                                  name: name,
                                  description: descCtrl.text.trim().isNotEmpty
                                      ? descCtrl.text.trim()
                                      : null,
                                  serviceTypes: selectedTypes.toList(),
                                  address: addr,
                                  city: city,
                                  state: stateCtrl.text
                                      .trim()
                                      .toUpperCase(),
                                  zipCode: zip,
                                  phone: phoneCtrl.text.trim().isNotEmpty
                                      ? phoneCtrl.text.trim()
                                      : null,
                                  website:
                                      websiteCtrl.text.trim().isNotEmpty
                                          ? websiteCtrl.text.trim()
                                          : null,
                                  source: 'user_submitted',
                                  submittedBy: user?.uid,
                                );
                                await RespiteCareService.instance
                                    .submitProvider(provider);
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                if (mounted) {
                                  HapticUtils.success();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Thanks! Your suggestion helps '
                                          'other caregivers.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Re-run search if we had one
                                  if (_hasSearched) _search();
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_location_alt_outlined,
                              size: 18),
                      label: const Text('Submit Service',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------
class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.isSearching,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 5,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Enter ZIP code (e.g., 02360)',
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: _RespiteCareFinderScreenState._kAccent),
              counterText: '',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: _RespiteCareFinderScreenState._kAccent,
                    width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: isSearching ? null : onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: _RespiteCareFinderScreenState._kAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: isSearching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Search',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Info card (pre-search)
// ---------------------------------------------------------------------------
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _RespiteCareFinderScreenState._kAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color:
                _RespiteCareFinderScreenState._kAccent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_outlined,
              size: 40,
              color:
                  _RespiteCareFinderScreenState._kAccent.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          const Text(
            'Find respite care near you',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _RespiteCareFinderScreenState._kAccent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your ZIP code to search for hospice respite, home health '
            'agencies, adult day centers, and other caregiver support services.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sources: CMS Medicare data (free, verified) + community submissions',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textLight,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          subtitle,
          style: TextStyle(fontSize: 10, color: AppTheme.textLight),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Provider card
// ---------------------------------------------------------------------------
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider});
  final RespiteProvider provider;

  @override
  Widget build(BuildContext context) {
    final hasPhone = provider.phone != null && provider.phone!.isNotEmpty;
    final hasWeb = provider.website != null && provider.website!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textLight.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + source badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  provider.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: provider.source == 'cms_api'
                      ? AppTheme.tileBlue.withValues(alpha: 0.1)
                      : _RespiteCareFinderScreenState._kAccent
                          .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  provider.sourceLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: provider.source == 'cms_api'
                        ? AppTheme.tileBlue
                        : _RespiteCareFinderScreenState._kAccent,
                  ),
                ),
              ),
            ],
          ),

          // Service type chips
          if (provider.serviceTypes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: provider.serviceTypes.take(3).map((type) {
                final color = RespiteProvider.kServiceTypeColors[type] ??
                    AppTheme.textSecondary;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    RespiteProvider.kServiceTypeLabels[type] ?? type,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // Address
          if (provider.address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              provider.fullAddress,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.3,
              ),
            ),
          ],

          // Description
          if (provider.description != null &&
              provider.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              provider.description!,
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Action buttons
          if (hasPhone || hasWeb) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (hasPhone)
                  _ActionChip(
                    icon: Icons.phone_outlined,
                    label: provider.phone!,
                    color: AppTheme.statusGreen,
                    onTap: () => _launchPhone(provider.phone!),
                  ),
                if (hasPhone && hasWeb) const SizedBox(width: 8),
                if (hasWeb)
                  _ActionChip(
                    icon: Icons.open_in_new,
                    label: 'Website',
                    color: AppTheme.tileBlue,
                    onTap: () => _launchUrl(provider.website!),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _shareProvider(provider),
                  child: Icon(Icons.share_outlined,
                      size: 18, color: AppTheme.textLight),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _launchPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    launchUrl(Uri.parse('tel:$cleaned'));
  }

  void _launchUrl(String url) {
    final uri = url.startsWith('http') ? url : 'https://$url';
    launchUrl(Uri.parse(uri), mode: LaunchMode.externalApplication);
  }

  void _shareProvider(RespiteProvider p) {
    final lines = <String>[p.name];
    if (p.address.isNotEmpty) lines.add(p.fullAddress);
    if (p.phone != null && p.phone!.isNotEmpty) lines.add('Phone: ${p.phone}');
    if (p.website != null && p.website!.isNotEmpty) {
      lines.add(p.website!);
    }
    if (p.description != null) lines.add(p.description!);
    Share.share(lines.join('\n'), subject: 'Respite Care: ${p.name}');
  }
}

// ---------------------------------------------------------------------------
// Action chip
// ---------------------------------------------------------------------------
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label.length > 16 ? '${label.substring(0, 14)}…' : label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
