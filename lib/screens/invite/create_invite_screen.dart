// lib/screens/invite/create_invite_screen.dart
//
// Admin flow: generate a short invite code for the active elder
// profile, then share it via the OS share sheet. Shows a running list
// of this user's recently-issued codes so they can see who's
// outstanding and revoke as needed.
//
// Surfaces role + TTL + max-uses choices behind a single "Advanced"
// collapsible so the default 1-use / 14-day / viewer experience is
// literally one tap.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/invite_code.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/invite_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tileBlue;
const Color _kAccentDeep = AppTheme.tileBlueDark;

class CreateInviteScreen extends StatefulWidget {
  const CreateInviteScreen({super.key});

  @override
  State<CreateInviteScreen> createState() => _CreateInviteScreenState();
}

class _CreateInviteScreenState extends State<CreateInviteScreen> {
  final _inviteService = InviteService();

  String _role = 'viewer';
  int _ttlDays = 14;
  int _maxUses = 1;
  bool _advancedOpen = false;
  bool _isCreating = false;
  CreatedInvite? _lastCreated;

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;
    final user = FirebaseAuth.instance.currentUser;
    final canCreate = elder != null &&
        user != null &&
        context.watch<ActiveElderProvider>().isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Family'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _HeroCard(elderName: elder?.profileName ?? '—', canCreate: canCreate),
          const SizedBox(height: 14),
          if (!canCreate)
            _NotAdminNotice()
          else ...[
            _RoleSelector(
              value: _role,
              onChanged: (v) => setState(() => _role = v),
            ),
            const SizedBox(height: 14),
            _AdvancedPanel(
              open: _advancedOpen,
              ttlDays: _ttlDays,
              maxUses: _maxUses,
              onToggle: () =>
                  setState(() => _advancedOpen = !_advancedOpen),
              onTtlChanged: (v) => setState(() => _ttlDays = v),
              onMaxUsesChanged: (v) => setState(() => _maxUses = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating
                    ? null
                    : () => _createInvite(elder.id),
                icon: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(
                  _isCreating ? 'Generating…' : 'Generate invite code',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM)),
                ),
              ),
            ),
            if (_lastCreated != null) ...[
              const SizedBox(height: 16),
              _CodeResultCard(
                invite: _lastCreated!,
                elderName: elder.profileName,
                inviterName: user.displayName ?? 'Your caregiver',
              ),
            ],
            const SizedBox(height: 22),
            _RecentInvitesSection(
              uid: user.uid,
              service: _inviteService,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _createInvite(String elderId) async {
    setState(() => _isCreating = true);
    try {
      final invite = await _inviteService.createInvite(
        elderId: elderId,
        role: _role,
        ttlDays: _ttlDays,
        maxUses: _maxUses,
      );
      HapticUtils.success();
      if (!mounted) return;
      setState(() {
        _lastCreated = invite;
        _isCreating = false;
      });
    } on InviteException catch (e) {
      if (!mounted) return;
      setState(() => _isCreating = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }
}

// ---------------------------------------------------------------------------
// Hero banner
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.elderName, required this.canCreate});
  final String elderName;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: _kAccent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_add_outlined, color: _kAccentDeep, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Invite family to read along',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            canCreate
                ? 'Generate a code. Text or email it. They open Cecelia Care, '
                    'tap "I have an invite code", and they\'re in. Read-only '
                    'by default — they see $elderName\'s timeline without '
                    'being able to log or delete anything.'
                : 'You need to be the admin of $elderName\'s profile to send '
                    'invites. Ask the admin to add you, or create your own '
                    'profile for someone you care for.',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotAdminNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: const Text(
        'Only admins can generate invite codes.',
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role selector
// ---------------------------------------------------------------------------

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACCESS LEVEL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _RoleOption(
            role: 'viewer',
            selected: value == 'viewer',
            title: 'Viewer (default)',
            description:
                'Read-only — can see timeline, calendar, medications. '
                'Cannot log entries, send messages, or change anything.',
            onTap: () => onChanged('viewer'),
          ),
          const SizedBox(height: 8),
          _RoleOption(
            role: 'caregiver',
            selected: value == 'caregiver',
            title: 'Caregiver',
            description:
                'Full logging access — can write entries, mark meds taken, '
                'send messages. Cannot manage profiles or caregivers.',
            onTap: () => onChanged('caregiver'),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.role,
    required this.selected,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String role;
  final bool selected;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? _kAccent.withValues(alpha: 0.08)
              : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: selected ? _kAccent : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? _kAccent : AppTheme.textLight,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          selected ? _kAccentDeep : AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4,
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
}

// ---------------------------------------------------------------------------
// Advanced panel (TTL / maxUses)
// ---------------------------------------------------------------------------

class _AdvancedPanel extends StatelessWidget {
  const _AdvancedPanel({
    required this.open,
    required this.ttlDays,
    required this.maxUses,
    required this.onToggle,
    required this.onTtlChanged,
    required this.onMaxUsesChanged,
  });

  final bool open;
  final int ttlDays;
  final int maxUses;
  final VoidCallback onToggle;
  final ValueChanged<int> onTtlChanged;
  final ValueChanged<int> onMaxUsesChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 18, color: _kAccentDeep),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Advanced options',
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '$ttlDays ${ttlDays == 1 ? 'day' : 'days'} · $maxUses '
                    '${maxUses == 1 ? 'use' : 'uses'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  Icon(open ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expires in',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final days in const [1, 3, 7, 14, 30])
                        ChoiceChip(
                          label: Text(
                            days == 1 ? '1 day' : '$days days',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: ttlDays == days,
                          onSelected: (_) => onTtlChanged(days),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Max redemptions',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final n in const [1, 2, 5, 10])
                        ChoiceChip(
                          label: Text(
                            n == 1 ? '1 person' : '$n people',
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: maxUses == n,
                          onSelected: (_) => onMaxUsesChanged(n),
                        ),
                    ],
                  ),
                  if (maxUses > 1) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 12, color: AppTheme.statusAmber),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Multi-use codes let several family members join '
                            'with the same link. Each UID can only redeem '
                            'once.',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
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

// ---------------------------------------------------------------------------
// Code result card — shown immediately after creation
// ---------------------------------------------------------------------------

class _CodeResultCard extends StatelessWidget {
  const _CodeResultCard({
    required this.invite,
    required this.elderName,
    required this.inviterName,
  });

  final CreatedInvite invite;
  final String elderName;
  final String inviterName;

  String _formatCode(String code) {
    if (code.length <= 4) return code;
    // Split into halves for readability: ABCD-EFGH
    final mid = code.length ~/ 2;
    return '${code.substring(0, mid)}-${code.substring(mid)}';
  }

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.code));
    HapticUtils.tap();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Invite code copied.'),
        backgroundColor: AppTheme.statusGreen,
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<void> _share(BuildContext context) async {
    final body = _invitationBody();
    await Share.share(body, subject: 'Cecelia Care invite');
    HapticUtils.tap();
  }

  String _invitationBody() {
    return '$inviterName invited you to help care for $elderName on Cecelia Care.\n\n'
        'Open the app and tap "I have an invite code", then enter:\n'
        '    ${invite.code}\n\n'
        '(Or use the link: ${invite.shareUrl})';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.statusGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(
            color: AppTheme.statusGreen.withValues(alpha: 0.3), width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle,
                  color: AppTheme.statusGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                'Ready to share',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.statusGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _copyCode(context),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatCode(invite.code),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                      color: _kAccentDeep,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.copy, size: 16, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Expires ${DateFormat('MMM d, h:mm a').format(invite.expiresAt)}'
            ' · ${invite.role == 'viewer' ? 'Viewer' : 'Caregiver'}'
            ' · ${invite.maxUses == 1 ? '1 use' : '${invite.maxUses} uses'}',
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _copyCode(context),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAccentDeep,
                    side: BorderSide(color: _kAccent.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share_outlined, size: 16),
                  label: const Text('Share'),
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

// ---------------------------------------------------------------------------
// Recent invites
// ---------------------------------------------------------------------------

class _RecentInvitesSection extends StatelessWidget {
  const _RecentInvitesSection({required this.uid, required this.service});
  final String uid;
  final InviteService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InviteCode>>(
      stream: service.watchInvitesCreatedBy(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        final invites = snap.data ?? const <InviteCode>[];
        if (invites.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR RECENT INVITES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              for (final inv in invites) _InviteRow(invite: inv, service: service),
            ],
          ),
        );
      },
    );
  }
}

class _InviteRow extends StatelessWidget {
  const _InviteRow({required this.invite, required this.service});
  final InviteCode invite;
  final InviteService service;

  @override
  Widget build(BuildContext context) {
    final status = invite.effectiveStatus;
    final color = _colorFor(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                invite.code,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: _kAccentDeep,
                ),
              ),
              Text(
                '${CaregiverRoleX.fromString(invite.role).label} · '
                '${invite.uses}/${invite.maxUses}',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              invite.elderName,
              style: const TextStyle(fontSize: 12.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            ),
            child: Text(
              status.label.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
          ),
          if (status == InviteCodeStatus.active)
            IconButton(
              tooltip: 'Revoke',
              icon: const Icon(Icons.close, size: 16),
              color: AppTheme.dangerColor,
              visualDensity: VisualDensity.compact,
              onPressed: () => _confirmRevoke(context),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke this invite?'),
        content: Text(
          'The code ${invite.code} won\'t work anymore. People who already '
          'redeemed it keep their access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await service.revokeInvite(invite.code);
      if (context.mounted) {
        HapticUtils.warning();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invite revoked.'),
        ));
      }
    } on InviteException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }
}

Color _colorFor(InviteCodeStatus s) {
  switch (s) {
    case InviteCodeStatus.active:
      return AppTheme.statusGreen;
    case InviteCodeStatus.expired:
      return AppTheme.statusAmber;
    case InviteCodeStatus.revoked:
      return AppTheme.dangerColor;
    case InviteCodeStatus.exhausted:
      return AppTheme.textSecondary;
    case InviteCodeStatus.unknown:
      return AppTheme.textLight;
  }
}
