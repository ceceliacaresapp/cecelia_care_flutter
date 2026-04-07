// lib/screens/shift_schedule_screen.dart
//
// Weekly shift schedule grid with caregiver assignments.
// Shows an "On duty now" banner, a Mon–Sun grid per shift definition,
// and lets admins assign caregivers by tapping cells.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/shift_definition.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class ShiftScheduleScreen extends StatefulWidget {
  const ShiftScheduleScreen({super.key});

  @override
  State<ShiftScheduleScreen> createState() => _ShiftScheduleScreenState();
}

class _ShiftScheduleScreenState extends State<ShiftScheduleScreen> {
  List<UserProfile> _associatedUsers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final elder =
        context.read<ActiveElderProvider>().activeElder;
    if (elder == null) return;
    setState(() => _isLoadingUsers = true);
    try {
      final users = await context
          .read<FirestoreService>()
          .getAssociatedUsersForElder(elder.id);
      if (mounted) setState(() => _associatedUsers = users);
    } catch (e) {
      debugPrint('ShiftScheduleScreen._fetchUsers error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsers = false);
    }
  }

  bool get _canEdit {
    final role =
        context.read<ActiveElderProvider>().currentUserRole;
    return role == CaregiverRole.admin || role == CaregiverRole.caregiver;
  }

  @override
  Widget build(BuildContext context) {
    final elder =
        context.watch<ActiveElderProvider>().activeElder;
    if (elder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shift Schedule')),
        body: const Center(
            child: Text('No care recipient selected.')),
      );
    }

    final fs = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Schedule'),
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
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: () => _showAddShiftDialog(context),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fs.getShiftDefinitionsStream(elder.id),
        builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawShifts = snapshot.data ?? [];
          final shifts = rawShifts
              .map((m) => ShiftDefinition.fromFirestore(
                  m['id'] as String, m))
              .toList();

          if (shifts.isEmpty) {
            return _EmptyState(
              onQuickSetup: _canEdit
                  ? () => _quickSetup(context, elder.id)
                  : null,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: [
              // On duty banner
              _OnDutyBanner(shifts: shifts),
              const SizedBox(height: 20),

              // Weekly grid
              ...shifts.map((shift) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ShiftRow(
                      shift: shift,
                      users: _associatedUsers,
                      canEdit: _canEdit,
                      onAssign: (dayKey, uid, name) =>
                          _assignCaregiver(shift, dayKey, uid, name),
                      onEdit: () => _showEditShiftDialog(context, shift),
                      onDelete: () => _confirmDelete(context, shift),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  // ── Quick setup — create 3 preset shifts ────────────────────────
  Future<void> _quickSetup(BuildContext context, String elderId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final fs = context.read<FirestoreService>();
    final presets = ShiftDefinition.presets(elderId, user.uid);

    for (final preset in presets) {
      await fs.addShiftDefinition(elderId, preset.toFirestore());
    }

    if (mounted) {
      HapticUtils.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('3 shifts created: Morning, Afternoon, Overnight'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ── Assign a caregiver to a day ─────────────────────────────────
  Future<void> _assignCaregiver(
    ShiftDefinition shift,
    String dayKey,
    String? uid,
    String? displayName,
  ) async {
    final elder =
        context.read<ActiveElderProvider>().activeElder;
    if (elder == null || shift.id == null) return;

    final newAssignments = Map<String, String>.from(shift.assignments);
    final newNames = Map<String, String>.from(shift.assigneeNames);

    if (uid != null && uid.isNotEmpty) {
      newAssignments[dayKey] = uid;
      if (displayName != null && displayName.isNotEmpty) {
        newNames[uid] = displayName;
      }
    } else {
      newAssignments.remove(dayKey);
    }

    try {
      await context.read<FirestoreService>().updateShiftDefinition(
        elder.id,
        shift.id!,
        {'assignments': newAssignments, 'assigneeNames': newNames},
      );
      HapticUtils.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning: $e')),
        );
      }
    }
  }

  // ── Add shift dialog ────────────────────────────────────────────
  void _showAddShiftDialog(BuildContext context) {
    _showShiftFormDialog(context, null);
  }

  void _showEditShiftDialog(BuildContext context, ShiftDefinition shift) {
    _showShiftFormDialog(context, shift);
  }

  void _showShiftFormDialog(BuildContext context, ShiftDefinition? existing) {
    final nameCtrl =
        TextEditingController(text: existing?.name ?? '');
    String startTime = existing?.startTime ?? '08:00';
    String endTime = existing?.endTime ?? '16:00';
    String selectedColor = existing?.colorHex ?? '#1E88E5';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSheetState) {
          Color activeColor;
          try {
            activeColor = Color(int.parse(
                'FF${selectedColor.replaceFirst('#', '')}',
                radix: 16));
          } catch (_) {
            activeColor = AppTheme.primaryColor;
          }

          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null ? 'New Shift' : 'Edit Shift',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: activeColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Preset buttons
                if (existing == null) ...[
                  Text('QUICK FILL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      )),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _PresetChip(
                          label: 'Morning',
                          onTap: () => setSheetState(() {
                                nameCtrl.text = 'Morning';
                                startTime = '07:00';
                                endTime = '15:00';
                                selectedColor = '#1E88E5';
                              })),
                      const SizedBox(width: 8),
                      _PresetChip(
                          label: 'Afternoon',
                          onTap: () => setSheetState(() {
                                nameCtrl.text = 'Afternoon';
                                startTime = '15:00';
                                endTime = '23:00';
                                selectedColor = '#F57C00';
                              })),
                      const SizedBox(width: 8),
                      _PresetChip(
                          label: 'Overnight',
                          onTap: () => setSheetState(() {
                                nameCtrl.text = 'Overnight';
                                startTime = '23:00';
                                endTime = '07:00';
                                selectedColor = '#5C6BC0';
                              })),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Shift name',
                    hintText: 'e.g., Morning, Evening',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),

                // Time pickers
                Row(
                  children: [
                    Expanded(
                      child: _TimePickerField(
                        label: 'Start',
                        value: startTime,
                        onChanged: (v) =>
                            setSheetState(() => startTime = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimePickerField(
                        label: 'End',
                        value: endTime,
                        onChanged: (v) =>
                            setSheetState(() => endTime = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Color picker
                Row(
                  children: ShiftDefinition.kShiftColors
                      .map((hex) {
                        Color c;
                        try {
                          c = Color(int.parse(
                              'FF${hex.replaceFirst('#', '')}',
                              radix: 16));
                        } catch (_) {
                          c = AppTheme.textSecondary;
                        }
                        final sel = selectedColor == hex;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setSheetState(
                                () => selectedColor = hex),
                            child: Container(
                              height: 32,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 2),
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius:
                                    BorderRadius.circular(6),
                                border: sel
                                    ? Border.all(
                                        color: Colors.white,
                                        width: 2.5)
                                    : null,
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color:
                                                c.withValues(alpha: 0.5),
                                            blurRadius: 6)
                                      ]
                                    : null,
                              ),
                              child: sel
                                  ? const Icon(Icons.check,
                                      color: Colors.white,
                                      size: 16)
                                  : null,
                            ),
                          ),
                        );
                      })
                      .toList(),
                ),
                const SizedBox(height: 20),

                // Save
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty) return;
                            setSheetState(() => isSaving = true);

                            final elder = context
                                .read<ActiveElderProvider>()
                                .activeElder;
                            final user = FirebaseAuth
                                .instance.currentUser;
                            if (elder == null || user == null) return;

                            final fs =
                                context.read<FirestoreService>();
                            final data = ShiftDefinition(
                              name: name,
                              startTime: startTime,
                              endTime: endTime,
                              colorHex: selectedColor,
                              elderId: elder.id,
                              createdBy: user.uid,
                              assignments:
                                  existing?.assignments ?? {},
                              assigneeNames:
                                  existing?.assigneeNames ?? {},
                            ).toFirestore();

                            try {
                              if (existing?.id != null) {
                                await fs.updateShiftDefinition(
                                    elder.id,
                                    existing!.id!,
                                    data);
                              } else {
                                await fs.addShiftDefinition(
                                    elder.id, data);
                              }
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx)
                                    .showSnackBar(SnackBar(
                                  content: Text('Error: $e'),
                                ));
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      existing == null
                          ? 'Create Shift'
                          : 'Update Shift',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ShiftDefinition shift) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${shift.name}"?'),
        content: const Text(
            'This removes the shift and all its assignments.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || shift.id == null) return;

    final elder =
        context.read<ActiveElderProvider>().activeElder;
    if (elder == null) return;
    await context
        .read<FirestoreService>()
        .deleteShiftDefinition(elder.id, shift.id!);
  }
}

// ---------------------------------------------------------------------------
// On duty banner
// ---------------------------------------------------------------------------
class _OnDutyBanner extends StatelessWidget {
  const _OnDutyBanner({required this.shifts});
  final List<ShiftDefinition> shifts;

  @override
  Widget build(BuildContext context) {
    final today = ShiftDefinition.todayKey();
    ShiftDefinition? active;
    String? onDutyName;

    for (final s in shifts) {
      if (s.isCurrentShift) {
        active = s;
        onDutyName = s.assignedNameForDay(today);
        break;
      }
    }

    if (active == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_outlined,
                size: 20, color: AppTheme.textLight),
            const SizedBox(width: 10),
            Text(
              'No shift currently active',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final hasAssignee = onDutyName != null && onDutyName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: active.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF43A047),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                children: [
                  TextSpan(
                    text: '${active.name} shift',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: active.color),
                  ),
                  TextSpan(
                    text: hasAssignee
                        ? ' — $onDutyName is on duty'
                        : ' — unassigned',
                    style: TextStyle(
                      color: hasAssignee
                          ? AppTheme.textPrimary
                          : AppTheme.textLight,
                      fontStyle:
                          hasAssignee ? FontStyle.normal : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shift row — one row per shift definition with 7 day cells
// ---------------------------------------------------------------------------
class _ShiftRow extends StatelessWidget {
  const _ShiftRow({
    required this.shift,
    required this.users,
    required this.canEdit,
    required this.onAssign,
    required this.onEdit,
    required this.onDelete,
  });

  final ShiftDefinition shift;
  final List<UserProfile> users;
  final bool canEdit;
  final void Function(String dayKey, String? uid, String? name) onAssign;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final today = ShiftDefinition.todayKey();

    return Container(
      decoration: BoxDecoration(
        color: shift.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: shift.color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onLongPress: canEdit ? () => _showOptions(context) : null,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: shift.color.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: shift.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shift.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: shift.color,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${shift.startTime}–${shift.endTime}',
                    style: TextStyle(
                      fontSize: 11,
                      color: shift.color.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  if (canEdit)
                    GestureDetector(
                      onTap: () => _showOptions(context),
                      child: Icon(Icons.more_horiz,
                          size: 18,
                          color: shift.color.withValues(alpha: 0.5)),
                    ),
                ],
              ),
            ),
          ),

          // Day cells
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: List.generate(7, (i) {
                final dayKey = ShiftDefinition.dayKeys[i];
                final dayLabel = ShiftDefinition.dayLabels[i];
                final assignedName = shift.assignedNameForDay(dayKey);
                final isToday = dayKey == today;
                final hasAssignee = assignedName.isNotEmpty;

                return Expanded(
                  child: GestureDetector(
                    onTap: canEdit
                        ? () => _showAssignmentPicker(
                            context, dayKey, dayLabel)
                        : null,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isToday
                            ? shift.color.withValues(alpha: 0.12)
                            : hasAssignee
                                ? shift.color.withValues(alpha: 0.06)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(
                                color: shift.color.withValues(alpha: 0.4))
                            : hasAssignee
                                ? null
                                : Border.all(
                                    color: AppTheme.textLight
                                        .withValues(alpha: 0.3),
                                    style: BorderStyle.solid,
                                  ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isToday
                                  ? shift.color
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasAssignee)
                            CircleAvatar(
                              radius: 13,
                              backgroundColor:
                                  shift.color.withValues(alpha: 0.15),
                              child: Text(
                                assignedName[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: shift.color,
                                ),
                              ),
                            )
                          else
                            Icon(
                              Icons.add,
                              size: 16,
                              color:
                                  AppTheme.textLight.withValues(alpha: 0.5),
                            ),
                          if (hasAssignee) ...[
                            const SizedBox(height: 2),
                            Text(
                              assignedName.length > 5
                                  ? assignedName.substring(0, 5)
                                  : assignedName,
                              style: TextStyle(
                                fontSize: 8,
                                color: shift.color.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_outlined, color: shift.color),
              title: const Text('Edit shift'),
              onTap: () {
                Navigator.of(ctx).pop();
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppTheme.dangerColor),
              title: const Text('Delete shift',
                  style: TextStyle(color: AppTheme.dangerColor)),
              onTap: () {
                Navigator.of(ctx).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentPicker(
      BuildContext context, String dayKey, String dayLabel) {
    final currentUid = shift.assignedUidForDay(dayKey);

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                '${shift.name} — $dayLabel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: shift.color,
                ),
              ),
            ),
            const Divider(),
            if (users.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('No caregivers found.'),
              )
            else
              ...users.map((u) {
                final isSelected = u.uid == currentUid;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        shift.color.withValues(alpha: 0.12),
                    backgroundImage:
                        u.avatarUrl?.isNotEmpty == true
                            ? NetworkImage(u.avatarUrl!)
                            : null,
                    child: u.avatarUrl?.isNotEmpty != true
                        ? Text(
                            u.displayName.isNotEmpty
                                ? u.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                color: shift.color,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  title: Text(u.displayName.isNotEmpty
                      ? u.displayName
                      : u.email),
                  trailing: isSelected
                      ? Icon(Icons.check_circle,
                          color: shift.color)
                      : null,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    onAssign(dayKey, u.uid, u.displayName);
                  },
                );
              }),
            if (currentUid != null)
              ListTile(
                leading: const Icon(Icons.clear,
                    color: AppTheme.dangerColor),
                title: const Text('Unassign',
                    style: TextStyle(color: AppTheme.dangerColor)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onAssign(dayKey, null, null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onQuickSetup});
  final VoidCallback? onQuickSetup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule_outlined,
                size: 56, color: AppTheme.textLight),
            const SizedBox(height: 16),
            Text(
              'No shifts set up yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create shifts and assign caregivers to coordinate '
              'who\'s responsible at each time of day.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textLight,
                height: 1.4,
              ),
            ),
            if (onQuickSetup != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onQuickSetup,
                icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                label: const Text('Quick Setup — 3 Shifts'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Creates Morning, Afternoon, and Overnight',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time picker field
// ---------------------------------------------------------------------------
class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        TimeOfDay initial;
        try {
          final parts = value.split(':');
          initial = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        } catch (_) {
          initial = const TimeOfDay(hour: 8, minute: 0);
        }

        final picked = await showTimePicker(
          context: context,
          initialTime: initial,
        );
        if (picked != null) {
          final h = picked.hour.toString().padLeft(2, '0');
          final m = picked.minute.toString().padLeft(2, '0');
          onChanged('$h:$m');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
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
                Icon(Icons.access_time,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preset chip
// ---------------------------------------------------------------------------
class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
