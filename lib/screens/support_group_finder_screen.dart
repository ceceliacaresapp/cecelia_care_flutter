// lib/screens/support_group_finder_screen.dart
//
// Local + virtual support group finder. Mirrors the Respite Finder
// UX (ZIP-first search, condition filter chips) with these twists:
//   • Format filter (in-person / virtual / phone / hybrid) — isolation
//     is the core problem, so "virtual right now" is a valid answer.
//   • Action-oriented cards: phone → dialer, URL → browser,
//     address → directions.
//   • Submit-a-group bottom sheet so users can crowdsource local
//     in-person groups that aren't in the national directory.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cecelia_care_flutter/models/support_group.dart';
import 'package:cecelia_care_flutter/services/ai_suggestion_service.dart';
import 'package:cecelia_care_flutter/services/support_group_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tileTeal;
const Color _kAccentDeep = Color(0xFF00695C);

class SupportGroupFinderScreen extends StatefulWidget {
  const SupportGroupFinderScreen({super.key});

  @override
  State<SupportGroupFinderScreen> createState() =>
      _SupportGroupFinderScreenState();
}

class _SupportGroupFinderScreenState
    extends State<SupportGroupFinderScreen> {
  final _zipCtrl = TextEditingController();
  final Set<SupportConditionType> _selectedConditions = {};
  SupportFormat? _formatFilter;

  bool _loading = false;
  List<SupportGroup>? _results;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pre-populate with the national directory so there's always
    // something on-screen while the caregiver thinks about filters.
    _results = SupportGroupDirectory.filter();
  }

  @override
  void dispose() {
    _zipCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await SupportGroupService.instance.search(
        zipCode: _zipCtrl.text.trim(),
        conditions: _selectedConditions,
        format: _formatFilter,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not search right now: $e';
        _loading = false;
      });
    }
  }

  void _toggleCondition(SupportConditionType c) {
    setState(() {
      if (_selectedConditions.contains(c)) {
        _selectedConditions.remove(c);
      } else {
        _selectedConditions.add(c);
      }
    });
    _runSearch();
  }

  void _setFormat(SupportFormat? f) {
    setState(() => _formatFilter = f);
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results ?? const <SupportGroup>[];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Groups'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kAccentDeep,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add a local group'),
        onPressed: _openSubmitSheet,
      ),
      body: Column(
        children: [
          _IsolationBanner(),
          _FiltersPanel(
            zipCtrl: _zipCtrl,
            onSearch: _runSearch,
            selectedConditions: _selectedConditions,
            onToggleCondition: _toggleCondition,
            format: _formatFilter,
            onSetFormat: _setFormat,
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(
                        message: _error!, onRetry: _runSearch)
                    : results.isEmpty
                        ? _EmptyResults(
                            onClearFilters: () {
                              setState(() {
                                _selectedConditions.clear();
                                _formatFilter = null;
                                _zipCtrl.clear();
                              });
                              _runSearch();
                            },
                            onSubmit: _openSubmitSheet,
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(
                                16, 12, 16, 96),
                            children: [
                              _ResultsSummary(count: results.length),
                              const SizedBox(height: 10),
                              for (final g in results)
                                _GroupCard(group: g),
                              const SizedBox(height: 10),
                              _MatchMeCard(
                                conditions: _selectedConditions,
                                format: _formatFilter,
                                zip: _zipCtrl.text.trim(),
                              ),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  void _openSubmitSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _SubmitGroupSheet(
        onSaved: (group) async {
          try {
            await SupportGroupService.instance.submitGroup(group);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Thank you — the group was added to the community directory.'),
              backgroundColor: AppTheme.statusGreen,
            ));
            HapticUtils.success();
            _runSearch();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Could not submit: $e'),
              backgroundColor: AppTheme.dangerColor,
            ));
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Isolation banner
// ---------------------------------------------------------------------------

class _IsolationBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_outline, color: _kAccentDeep, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Isolation is the #1 driver of caregiver depression. '
              'Finding one group — even a 24/7 hotline tonight — changes that.',
              style: TextStyle(
                fontSize: 12.5,
                color: _kAccentDeep,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.zipCtrl,
    required this.onSearch,
    required this.selectedConditions,
    required this.onToggleCondition,
    required this.format,
    required this.onSetFormat,
  });

  final TextEditingController zipCtrl;
  final VoidCallback onSearch;
  final Set<SupportConditionType> selectedConditions;
  final void Function(SupportConditionType) onToggleCondition;
  final SupportFormat? format;
  final ValueChanged<SupportFormat?> onSetFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ZIP row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: zipCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixIcon: const Icon(Icons.location_on_outlined,
                        size: 18),
                    hintText: 'ZIP code (optional — finds local groups)',
                    hintStyle: const TextStyle(fontSize: 12.5),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusS),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentDeep,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusS)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                child: const Text('Search',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Format row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Any format',
                      style: TextStyle(fontSize: 12)),
                  selected: format == null,
                  onSelected: (_) => onSetFormat(null),
                ),
                const SizedBox(width: 6),
                for (final f in SupportFormat.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      avatar: Icon(f.icon, size: 14),
                      label: Text(f.label,
                          style: const TextStyle(fontSize: 12)),
                      selected: format == f,
                      onSelected: (_) => onSetFormat(f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Condition row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in SupportConditionType.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      avatar: Icon(c.icon, size: 14),
                      label: Text(c.label,
                          style: const TextStyle(fontSize: 12)),
                      selected: selectedConditions.contains(c),
                      onSelected: (_) => onToggleCondition(c),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results views
// ---------------------------------------------------------------------------

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.groups, size: 16, color: _kAccentDeep),
        const SizedBox(width: 6),
        Text(
          '$count ${count == 1 ? 'group' : 'groups'} found',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: _kAccentDeep,
          ),
        ),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onClearFilters, required this.onSubmit});
  final VoidCallback onClearFilters;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.search_off_outlined,
              size: 44, color: _kAccent.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          const Text(
            'No groups match those filters.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try clearing a filter or widening the ZIP search. If you know '
            'of a local group not listed here, add it and help the next '
            'caregiver find it.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.45),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClearFilters,
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear filters'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAccentDeep,
                    side: BorderSide(
                        color: _kAccent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add a group'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccentDeep,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 40, color: AppTheme.dangerColor),
          const SizedBox(height: 10),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Group card
// ---------------------------------------------------------------------------

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final SupportGroup group;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Icon(group.format.icon,
                      color: _kAccentDeep, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                      if (group.organizationName != null &&
                          group.organizationName!.isNotEmpty)
                        Text(
                          group.organizationName!,
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
                _SourcePill(source: group.source),
              ],
            ),
            if (group.description != null &&
                group.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                group.description!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _InfoPill(
                  icon: group.format.icon,
                  label: group.format.label,
                  color: _kAccentDeep,
                ),
                for (final c in group.conditions.take(3))
                  _InfoPill(
                    icon: c.icon,
                    label: c.label,
                    color: AppTheme.tileBlueDark,
                  ),
                if (group.meetingSchedule != null &&
                    group.meetingSchedule!.isNotEmpty)
                  _InfoPill(
                    icon: Icons.schedule,
                    label: group.meetingSchedule!,
                    color: AppTheme.statusAmber,
                  ),
                if (group.languages.isNotEmpty)
                  _InfoPill(
                    icon: Icons.translate,
                    label: group.languages.take(3).join(' · '),
                    color: AppTheme.tilePurple,
                  ),
              ],
            ),
            if (group.hasInPersonLocation) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      group.fullAddress,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _ActionRow(group: group),
          ],
        ),
      ),
    );
  }
}

class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.source});
  final String source;

  @override
  Widget build(BuildContext context) {
    final color = source == 'bundled'
        ? AppTheme.statusGreen
        : source == 'partner_scrape'
            ? AppTheme.tileBlueDark
            : AppTheme.tilePurple;
    final label = source == 'bundled'
        ? 'National'
        : source == 'partner_scrape'
            ? 'Partner'
            : 'Community';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.group});
  final SupportGroup group;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    if (group.phone != null && group.phone!.isNotEmpty) {
      buttons.add(Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _launch('tel:${group.phone!.replaceAll(RegExp(r'[^0-9+]'), '')}'),
          icon: const Icon(Icons.call, size: 14),
          label: Text(group.phone!,
              style: const TextStyle(fontSize: 11.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccentDeep,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ));
    }
    if (group.meetingUrl != null && group.meetingUrl!.isNotEmpty) {
      buttons.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _launch(group.meetingUrl!),
          icon: const Icon(Icons.videocam_outlined, size: 14),
          label: const Text('Join online',
              style: TextStyle(fontSize: 11.5)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kAccentDeep,
            side: BorderSide(color: _kAccent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ));
    }
    if (group.website != null && group.website!.isNotEmpty &&
        (group.meetingUrl == null || group.meetingUrl!.isEmpty)) {
      buttons.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _launch(group.website!),
          icon: const Icon(Icons.open_in_new, size: 14),
          label: const Text('Website',
              style: TextStyle(fontSize: 11.5)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kAccentDeep,
            side: BorderSide(color: _kAccent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ));
    }
    if (group.hasInPersonLocation) {
      final q = Uri.encodeComponent(group.fullAddress);
      buttons.add(Expanded(
        child: OutlinedButton.icon(
          onPressed: () =>
              _launch('https://www.google.com/maps/search/?api=1&query=$q'),
          icon: const Icon(Icons.directions, size: 14),
          label:
              const Text('Directions', style: TextStyle(fontSize: 11.5)),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kAccentDeep,
            side: BorderSide(color: _kAccent.withValues(alpha: 0.5)),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ));
    }
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }
    // Interleave SizedBox separators — we do it manually so the list
    // survives Wrap rules without the _buttons.map dance.
    final children = <Widget>[];
    for (int i = 0; i < buttons.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 8));
      children.add(buttons[i]);
    }
    return Row(children: children);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ---------------------------------------------------------------------------
// AI match card
// ---------------------------------------------------------------------------

class _MatchMeCard extends StatefulWidget {
  const _MatchMeCard({
    required this.conditions,
    required this.format,
    required this.zip,
  });

  final Set<SupportConditionType> conditions;
  final SupportFormat? format;
  final String zip;

  @override
  State<_MatchMeCard> createState() => _MatchMeCardState();
}

class _MatchMeCardState extends State<_MatchMeCard> {
  bool _busy = false;
  String? _message;

  Future<void> _ask() async {
    setState(() => _busy = true);
    final res = await AiSuggestionService.instance
        .suggestSupportGroupMatch(
      elderId: '',
      elderDisplayName: '',
      context: {
        'conditions': widget.conditions.map((c) => c.firestoreValue).toList(),
        'format': widget.format?.firestoreValue,
        'zip': widget.zip,
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = res.suggestion ?? res.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.tileIndigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border:
            Border.all(color: AppTheme.tileIndigo.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 16, color: AppTheme.tileIndigoDeep),
              const SizedBox(width: 8),
              Text(
                'HELP ME CHOOSE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.tileIndigoDeep,
                ),
              ),
              const Spacer(),
              _AiStubChip(onTap: _ask, busy: _busy),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _message ??
                'Tell me which groups fit best for the condition and format '
                'you picked — AI pick coming soon.',
            style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textPrimary,
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _AiStubChip extends StatelessWidget {
  const _AiStubChip({required this.onTap, required this.busy});
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final available = AiSuggestionService.instance.isAvailable;
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: available
              ? AppTheme.tileIndigoDeep.withValues(alpha: 0.1)
              : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(
              color: available
                  ? AppTheme.tileIndigoDeep.withValues(alpha: 0.3)
                  : AppTheme.textLight.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              Icon(
                available
                    ? Icons.auto_awesome_outlined
                    : Icons.lock_clock_outlined,
                size: 12,
                color: available
                    ? AppTheme.tileIndigoDeep
                    : AppTheme.textSecondary,
              ),
            const SizedBox(width: 4),
            Text(
              available ? 'Match me' : 'Soon',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: available
                    ? AppTheme.tileIndigoDeep
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Submit a group sheet
// ---------------------------------------------------------------------------

class _SubmitGroupSheet extends StatefulWidget {
  const _SubmitGroupSheet({required this.onSaved});
  final Future<void> Function(SupportGroup) onSaved;

  @override
  State<_SubmitGroupSheet> createState() => _SubmitGroupSheetState();
}

class _SubmitGroupSheetState extends State<_SubmitGroupSheet> {
  final _name = TextEditingController();
  final _org = TextEditingController();
  final _desc = TextEditingController();
  final _sched = TextEditingController();
  final _addr = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _meetingUrl = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _email = TextEditingController();

  final Set<SupportConditionType> _conditions = {
    SupportConditionType.general,
  };
  SupportFormat _format = SupportFormat.inPerson;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _org.dispose();
    _desc.dispose();
    _sched.dispose();
    _addr.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _meetingUrl.dispose();
    _phone.dispose();
    _website.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Group name is required.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _submitting = true);
    final group = SupportGroup(
      id: '', // assigned by Firestore
      name: _name.text.trim(),
      organizationName:
          _org.text.trim().isEmpty ? null : _org.text.trim(),
      description:
          _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      conditions: _conditions.toList(),
      format: _format,
      meetingSchedule:
          _sched.text.trim().isEmpty ? null : _sched.text.trim(),
      address: _addr.text.trim().isEmpty ? null : _addr.text.trim(),
      city: _city.text.trim().isEmpty ? null : _city.text.trim(),
      state: _state.text.trim().isEmpty
          ? null
          : _state.text.trim().toUpperCase(),
      zipCode: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
      meetingUrl: _meetingUrl.text.trim().isEmpty
          ? null
          : _meetingUrl.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      website:
          _website.text.trim().isEmpty ? null : _website.text.trim(),
      source: 'user_submitted',
      submittedBy: user?.uid,
    );

    Navigator.of(context).pop();
    await widget.onSaved(group);
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final needsAddress = _format == SupportFormat.inPerson ||
        _format == SupportFormat.hybrid;
    final needsUrl = _format == SupportFormat.virtual ||
        _format == SupportFormat.hybrid;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.add_location_alt_outlined,
                      color: _kAccentDeep, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Add a local support group',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const Text(
                    'Sharing legitimate local groups helps other caregivers '
                    'find community. Submissions are reviewed before they '
                    'show up in search.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Label('Group name *'),
                  _tf(_name, 'e.g., Tuesday Night Memory Cafe'),
                  const SizedBox(height: 10),
                  _Label('Organization (optional)'),
                  _tf(_org, 'Sponsoring nonprofit or faith community'),
                  const SizedBox(height: 10),
                  _Label('Format'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final f in SupportFormat.values)
                        ChoiceChip(
                          avatar: Icon(f.icon, size: 14),
                          label: Text(f.label,
                              style: const TextStyle(fontSize: 12)),
                          selected: _format == f,
                          onSelected: (_) =>
                              setState(() => _format = f),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Label('Conditions served'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final c in SupportConditionType.values)
                        FilterChip(
                          avatar: Icon(c.icon, size: 14),
                          label: Text(c.label,
                              style: const TextStyle(fontSize: 12)),
                          selected: _conditions.contains(c),
                          onSelected: (_) => setState(() {
                            if (_conditions.contains(c)) {
                              _conditions.remove(c);
                            } else {
                              _conditions.add(c);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Label('Description'),
                  _tf(_desc,
                      'Who runs it, what to expect, anything families should know.',
                      maxLines: 3),
                  const SizedBox(height: 10),
                  _Label('Meeting schedule'),
                  _tf(_sched, 'e.g., 2nd & 4th Thursdays, 6:30–8 PM'),
                  if (needsAddress) ...[
                    const SizedBox(height: 14),
                    _Label('Address'),
                    _tf(_addr, 'Street (optional)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _tf(_city, 'City')),
                        const SizedBox(width: 8),
                        Expanded(
                            flex: 1,
                            child:
                                _tf(_state, 'State', max: 2, upper: true)),
                        const SizedBox(width: 8),
                        Expanded(flex: 2, child: _tf(_zip, 'ZIP', digits: true, max: 5)),
                      ],
                    ),
                  ],
                  if (needsUrl) ...[
                    const SizedBox(height: 14),
                    _Label('Meeting / online URL'),
                    _tf(_meetingUrl, 'https://zoom.us/…'),
                  ],
                  const SizedBox(height: 10),
                  _Label('Contacts'),
                  _tf(_phone, 'Phone', keyboardType: TextInputType.phone),
                  const SizedBox(height: 8),
                  _tf(_website, 'Website',
                      keyboardType: TextInputType.url),
                  const SizedBox(height: 8),
                  _tf(_email, 'Contact email',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kAccentDeep,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusM)),
                      ),
                      child: Text(
                        _submitting ? 'Submitting…' : 'Submit group',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tf(
    TextEditingController c,
    String hint, {
    int maxLines = 1,
    int? max,
    bool upper = false,
    bool digits = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType ??
          (digits ? TextInputType.number : TextInputType.text),
      textCapitalization: upper
          ? TextCapitalization.characters
          : TextCapitalization.sentences,
      inputFormatters: [
        if (digits) FilteringTextInputFormatter.digitsOnly,
        if (max != null) LengthLimitingTextInputFormatter(max),
      ],
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        hintStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS)),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
