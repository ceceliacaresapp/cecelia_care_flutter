// lib/screens/controlled_substance_vault_screen.dart
//
// Controlled Substance Vault — enhanced tracking for opioids and scheduled
// medications: strict count logging, two-person verification option,
// waste documentation, and PIN-locked access.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';
import 'package:cecelia_care_flutter/widgets/pin_gate.dart';

const _kAccent = AppTheme.tileOrange;

class ControlledSubstanceVaultScreen extends StatefulWidget {
  const ControlledSubstanceVaultScreen({super.key});

  @override
  State<ControlledSubstanceVaultScreen> createState() =>
      _ControlledSubstanceVaultScreenState();
}

class _ControlledSubstanceVaultScreenState
    extends State<ControlledSubstanceVaultScreen> {
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptPin());
  }

  Future<void> _promptPin() async {
    final elderId =
        context.read<ActiveElderProvider>().activeElder?.id ?? '';
    if (elderId.isEmpty) return;

    final ok = await verifyControlledSubstancePin(context, elderId: elderId);
    if (mounted) setState(() => _unlocked = ok);
    if (!ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Controlled Substance Vault')),
        body: const Center(child: Text('No care recipient selected.')),
      );
    }

    if (!_unlocked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Controlled Substance Vault'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allMeds =
        context.watch<MedicationDefinitionsProvider>().medDefinitions;
    final controlled =
        allMeds.where((m) => m.isControlled).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controlled Substance Vault'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline),
            tooltip: 'Lock vault',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: controlled.isEmpty
          ? EmptyStateWidget(
              icon: Icons.shield_outlined,
              title: 'No controlled substances',
              subtitle:
                  'Mark a medication as controlled from the Medication Manager\'s Reminders tab.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controlled.length,
              itemBuilder: (_, i) => _ControlledMedCard(
                def: controlled[i],
                elderId: elder.id,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card for a single controlled medication
// ---------------------------------------------------------------------------

class _ControlledMedCard extends StatelessWidget {
  const _ControlledMedCard({required this.def, required this.elderId});
  final MedicationDefinition def;
  final String elderId;

  @override
  Widget build(BuildContext context) {
    final scheduleLabel = def.deaSchedule != null
        ? 'Schedule ${_romanNumeral(def.deaSchedule!)}'
        : 'Controlled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Orange severity bar
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppTheme.radiusM),
                  bottomLeft: Radius.circular(AppTheme.radiusM),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: name + schedule badge
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined,
                            size: 18, color: _kAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(def.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kAccent.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusS),
                          ),
                          child: Text(scheduleLabel,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _kAccent)),
                        ),
                      ],
                    ),

                    if (def.dose != null && def.dose!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('Dose: ${def.dose}',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary)),
                    ],

                    const SizedBox(height: 10),

                    // Pill count display
                    Row(
                      children: [
                        _CountBadge(
                          label: 'On Hand',
                          value: def.pillCount?.toString() ?? '—',
                          color: (def.pillCount ?? 0) <= (def.refillThreshold ?? 5)
                              ? AppTheme.statusRed
                              : AppTheme.statusGreen,
                        ),
                        const SizedBox(width: 10),
                        if (def.requiresTwoPersonVerify)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.tilePurple.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusS),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline,
                                    size: 14,
                                    color: AppTheme.tilePurple),
                                const SizedBox(width: 4),
                                Text('2-person verify',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.tilePurple,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showCountAdjustDialog(context, def),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Adjust Count',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _kAccent,
                              side: BorderSide(
                                  color: _kAccent.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showWasteDocDialog(context, def),
                            icon: const Icon(Icons.delete_sweep_outlined,
                                size: 16),
                            label: const Text('Log Waste',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.statusRed,
                              side: BorderSide(
                                  color: AppTheme.statusRed
                                      .withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Recent audit log
                    const SizedBox(height: 10),
                    _AuditLogPreview(elderId: elderId, medName: def.name),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _romanNumeral(int n) {
    switch (n) {
      case 2: return 'II';
      case 3: return 'III';
      case 4: return 'IV';
      case 5: return 'V';
      default: return '$n';
    }
  }

  void _showCountAdjustDialog(
      BuildContext context, MedicationDefinition med) {
    final controller =
        TextEditingController(text: med.pillCount?.toString() ?? '');
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.inventory_2_outlined,
                color: _kAccent, size: 20),
            const SizedBox(width: 8),
            const Text('Adjust Count'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New pill count',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for adjustment',
                hintText: 'e.g., Pharmacy refill, correcting count error',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newCount = int.tryParse(controller.text.trim());
              if (newCount == null || newCount < 0) return;
              final reason = reasonController.text.trim();
              Navigator.pop(ctx);

              await _logAuditEntry(context, med, 'count_adjust',
                  'Count set to $newCount${reason.isNotEmpty ? ': $reason' : ''}');

              if (!context.mounted) return;
              // Direct Firestore update — stream auto-notifies the provider.
              await FirebaseFirestore.instance
                  .collection('medicationDefinitions')
                  .doc(med.id)
                  .update({'pillCount': newCount});
              HapticUtils.success();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWasteDocDialog(
      BuildContext context, MedicationDefinition med) {
    final qtyController = TextEditingController(text: '1');
    final reasonController = TextEditingController();
    final witnessController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_sweep_outlined,
                color: AppTheme.statusRed, size: 20),
            const SizedBox(width: 8),
            const Text('Document Waste'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Record medication waste with witness documentation '
              'for controlled substance compliance.',
              style: TextStyle(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity wasted',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'e.g., Partial dose, dropped, expired',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: witnessController,
              decoration: const InputDecoration(
                labelText: 'Witness name (if applicable)',
                hintText: 'e.g., Nurse Jane Doe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text.trim()) ?? 0;
              if (qty <= 0) return;
              final reason = reasonController.text.trim();
              final witness = witnessController.text.trim();
              Navigator.pop(ctx);

              final detail = StringBuffer('Wasted $qty unit(s)');
              if (reason.isNotEmpty) detail.write(': $reason');
              if (witness.isNotEmpty) detail.write(' (witness: $witness)');

              await _logAuditEntry(
                  context, med, 'waste', detail.toString());

              // Decrement pill count — stream auto-notifies.
              if (med.pillCount != null) {
                final newCount = (med.pillCount! - qty).clamp(0, 99999);
                await FirebaseFirestore.instance
                    .collection('medicationDefinitions')
                    .doc(med.id)
                    .update({'pillCount': newCount});
              }
              HapticUtils.success();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Document Waste'),
          ),
        ],
      ),
    );
  }

  Future<void> _logAuditEntry(
    BuildContext context,
    MedicationDefinition med,
    String action,
    String detail,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('elderProfiles')
        .doc(elderId)
        .collection('controlledSubstanceLog')
        .add({
      'medDefId': med.id,
      'medName': med.name,
      'action': action,
      'detail': detail,
      'loggedBy': user?.uid ?? '',
      'loggedByName': user?.displayName ?? user?.email ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Audit log preview — shows last 5 entries inline
// ---------------------------------------------------------------------------

class _AuditLogPreview extends StatelessWidget {
  const _AuditLogPreview({required this.elderId, required this.medName});
  final String elderId;
  final String medName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('elderProfiles')
          .doc(elderId)
          .collection('controlledSubstanceLog')
          .where('medName', isEqualTo: medName)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No audit entries yet.',
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textLight));
        }

        final docs = snapshot.data!.docs;
        final dateFmt = DateFormat('MMM d, h:mm a');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AUDIT LOG',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary)),
            const SizedBox(height: 4),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              final dateStr = ts != null
                  ? dateFmt.format(ts.toDate())
                  : '?';
              final action = data['action'] as String? ?? '';
              final detail = data['detail'] as String? ?? '';
              final loggedBy = data['loggedByName'] as String? ?? '';

              IconData icon;
              Color iconColor;
              switch (action) {
                case 'waste':
                  icon = Icons.delete_sweep_outlined;
                  iconColor = AppTheme.statusRed;
                  break;
                case 'count_adjust':
                  icon = Icons.edit_outlined;
                  iconColor = _kAccent;
                  break;
                case 'administered':
                  icon = Icons.check_circle_outline;
                  iconColor = AppTheme.statusGreen;
                  break;
                default:
                  icon = Icons.history;
                  iconColor = AppTheme.textSecondary;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 14, color: iconColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$detail — $loggedBy, $dateStr',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
