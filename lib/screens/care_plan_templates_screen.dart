// lib/screens/care_plan_templates_screen.dart
//
// Browse, preview, and apply pre-built care plan templates.
// Applying a template batch-creates recurring CalendarEvents for the
// active care recipient's calendar.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/care_plan_template.dart';
import 'package:cecelia_care_flutter/models/calendar_event.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/confetti_overlay.dart';

class CarePlanTemplatesScreen extends StatefulWidget {
  const CarePlanTemplatesScreen({super.key});

  @override
  State<CarePlanTemplatesScreen> createState() =>
      _CarePlanTemplatesScreenState();
}

class _CarePlanTemplatesScreenState extends State<CarePlanTemplatesScreen> {
  CarePlanTemplate? _selectedTemplate;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  int _durationDays = 30;
  bool _isApplying = false;

  static const _kDurationOptions = [14, 30, 60, 90];

  // ── Apply the template ──────────────────────────────────────────
  Future<void> _apply() async {
    if (_selectedTemplate == null || _isApplying) return;

    final activeElder =
        context.read<ActiveElderProvider>().activeElder;
    if (activeElder == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userProfile =
        context.read<UserProfileProvider>().userProfile;
    final displayName = userProfile?.displayName ?? user.email ?? '';

    setState(() => _isApplying = true);

    try {
      final firestoreService = context.read<FirestoreService>();
      final template = _selectedTemplate!;
      final endDate = _startDate.add(Duration(days: _durationDays));

      // Build CalendarEvent list from template items
      final List<CalendarEvent> events = [];
      for (final item in template.items) {
        final parts = item.timeOfDay.split(':');
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

        final start = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          hour,
          minute,
        );
        final end = start.add(Duration(minutes: item.durationMinutes));

        events.add(CalendarEvent(
          elderId: activeElder.id,
          createdBy: user.uid,
          createdByDisplayName: displayName,
          title: item.title,
          notes: item.notes,
          eventType: item.eventType,
          allDay: item.allDay,
          startDateTime: Timestamp.fromDate(start),
          endDateTime: Timestamp.fromDate(end),
          recurrenceRule: item.recurrenceRule,
          recurrenceEndDate: item.recurrenceRule != null
              ? Timestamp.fromDate(endDate)
              : null,
        ));
      }

      final count =
          await firestoreService.applyCarePlanTemplate(events);

      if (mounted) {
        HapticUtils.celebration();
        ConfettiOverlay.trigger(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${template.name} applied! $count events created.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Pop back to care screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('CarePlanTemplatesScreen._apply error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not apply care plan: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  // ── Pick start date ─────────────────────────────────────────────
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedTemplate == null
            ? 'Care Plan Templates'
            : _selectedTemplate!.name),
        centerTitle: true,
        leading: _selectedTemplate != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    setState(() => _selectedTemplate = null),
              )
            : null,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: _selectedTemplate == null
          ? _buildLibrary()
          : _buildPreview(_selectedTemplate!),
    );
  }

  // ── Library view ────────────────────────────────────────────────
  Widget _buildLibrary() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        // Header
        Text(
          'Choose a care plan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a template to auto-fill your calendar with a '
          'daily care routine. You can customize the start date '
          'and duration before applying.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Template cards
        ...carePlanTemplates.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _TemplateCard(
                template: t,
                onTap: () => setState(() {
                  _selectedTemplate = t;
                  _durationDays = t.defaultDurationDays;
                }),
              ),
            )),
      ],
    );
  }

  // ── Preview view ────────────────────────────────────────────────
  Widget _buildPreview(CarePlanTemplate template) {
    final activeElder =
        context.watch<ActiveElderProvider>().activeElder;
    final elderName = activeElder != null
        ? (activeElder.preferredName?.isNotEmpty == true
            ? activeElder.preferredName!
            : activeElder.profileName)
        : 'your care recipient';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            children: [
              // Description
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: template.color.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: template.color.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(template.icon,
                        color: template.color, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: template.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${template.items.length} scheduled events',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: template.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Settings row — start date + duration
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickStartDate,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'START DATE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 14,
                                    color: template.color),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat('MMM d, yyyy')
                                      .format(_startDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DURATION',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _durationDays,
                              isDense: true,
                              isExpanded: true,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              items: _kDurationOptions
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text('$d days'),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(
                                      () => _durationDays = v);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section label
              Text(
                'DAILY SCHEDULE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // Event items
              ...template.items.map((item) => _EventItemTile(
                    item: item,
                    color: template.color,
                  )),
            ],
          ),
        ),

        // Apply button — fixed at bottom
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isApplying ? null : _apply,
              icon: _isApplying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_fix_high_outlined, size: 20),
              label: Text(
                _isApplying
                    ? 'Creating events...'
                    : 'Apply to $elderName\'s calendar',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: template.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Template card — shown in the library list
// ---------------------------------------------------------------------------
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onTap,
  });

  final CarePlanTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: template.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: template.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: template.color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: template.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(template.icon,
                  size: 28, color: template.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: template.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: template.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          template.conditionTag,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: template.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${template.items.length} events',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14,
                color: template.color.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Event item tile — shown in the preview schedule
// ---------------------------------------------------------------------------
class _EventItemTile extends StatelessWidget {
  const _EventItemTile({
    required this.item,
    required this.color,
  });

  final TemplateItem item;
  final Color color;

  IconData _iconForEventType(String type) {
    switch (type) {
      case 'medication_reminder':
        return Icons.medication_outlined;
      case 'activity':
        return Icons.directions_walk_outlined;
      case 'social':
        return Icons.people_outline;
      case 'appointment':
        return Icons.event_outlined;
      default:
        return Icons.schedule_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Text(
              item.timeOfDay,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _iconForEventType(item.eventType),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.recurrenceRule != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.recurrenceRule!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                if (item.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
