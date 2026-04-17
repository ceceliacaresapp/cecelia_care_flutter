// lib/screens/invite/redeem_invite_screen.dart
//
// Two-step redemption flow:
//   1. User enters the 8-char code (or pastes / arrives with one pre-filled).
//      → peekInvite() fetches the denormalized elder name + inviter so we
//        can show "Helen invited you to help care for Mom" before they
//        irreversibly join.
//   2. User confirms → redeemInviteCode() adds their UID to the elder
//      profile with the coded role, and we set the new elder active so
//      they land on that profile immediately after confirming.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/invite_code.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/services/invite_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tileBlue;
const Color _kAccentDeep = AppTheme.tileBlueDark;

class RedeemInviteScreen extends StatefulWidget {
  const RedeemInviteScreen({super.key, this.initialCode});

  /// Seed the code field — used by future deep-link handling. Today,
  /// callers typically leave this null and the user pastes the code.
  final String? initialCode;

  @override
  State<RedeemInviteScreen> createState() => _RedeemInviteScreenState();
}

class _RedeemInviteScreenState extends State<RedeemInviteScreen> {
  final _inviteService = InviteService();
  final _codeCtrl = TextEditingController();
  InviteCode? _preview;
  String? _previewError;
  bool _isPeekingNow = false;
  bool _isRedeemingNow = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeCtrl.text = widget.initialCode!;
      // Slight delay so the widget has mounted before peeking.
      WidgetsBinding.instance.addPostFrameCallback((_) => _peek());
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _peek() async {
    final raw = _codeCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() {
        _preview = null;
        _previewError = 'Enter a code to continue.';
      });
      return;
    }
    setState(() {
      _isPeekingNow = true;
      _previewError = null;
      _preview = null;
    });
    try {
      final invite = await _inviteService.peekInvite(raw);
      if (!mounted) return;
      if (invite == null) {
        setState(() {
          _previewError = 'That code isn\'t recognized. Double-check and try again.';
          _isPeekingNow = false;
        });
        return;
      }
      if (!invite.isUsable) {
        setState(() {
          _previewError = _reasonFor(invite.effectiveStatus);
          _preview = invite;
          _isPeekingNow = false;
        });
        return;
      }
      setState(() {
        _preview = invite;
        _isPeekingNow = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _previewError = 'Could not look up that code. Check your connection.';
        _isPeekingNow = false;
      });
    }
  }

  String _reasonFor(InviteCodeStatus status) {
    switch (status) {
      case InviteCodeStatus.expired:
        return 'This invite has expired. Ask the sender for a new one.';
      case InviteCodeStatus.revoked:
        return 'This invite has been revoked.';
      case InviteCodeStatus.exhausted:
        return 'All uses of this invite have been claimed.';
      default:
        return 'This invite is not currently usable.';
    }
  }

  Future<void> _redeem() async {
    final preview = _preview;
    if (preview == null || _isRedeemingNow) return;
    setState(() => _isRedeemingNow = true);
    try {
      final result = await _inviteService.redeemInvite(preview.code);
      if (!mounted) return;

      // Set the newly-joined elder as the active one so the home screen
      // lands on it. If the provider doesn't have the elder loaded yet
      // it will refresh on the next auth/stream tick.
      try {
        final firestore = context.read<FirestoreService>();
        final profile = await firestore.getElderProfile(result.elderId);
        if (profile != null && mounted) {
          await context.read<ActiveElderProvider>().setActive(profile);
        }
      } catch (_) {
        // Non-fatal — the user can pick the elder manually.
      }

      HapticUtils.success();
      if (!mounted) return;

      final alreadyJoined =
          result.alreadyRedeemed || result.alreadyOnProfile;
      await showDialog(
        context: context,
        builder: (ctx) => _RedeemResultDialog(
          elderName: result.elderName,
          role: CaregiverRoleX.fromString(result.role),
          alreadyJoined: alreadyJoined,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on InviteException catch (e) {
      if (!mounted) return;
      setState(() {
        _isRedeemingNow = false;
        _previewError = e.message;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final authed = FirebaseAuth.instance.currentUser != null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redeem Invite'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          if (!authed)
            _SignedOutBanner()
          else ...[
            const Text(
              'Welcome to Cecelia Care',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter the 8-character code a family member shared with you. '
              'You\'ll get read-only access to their care timeline unless they '
              'chose otherwise.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            _CodeInput(
              controller: _codeCtrl,
              isLoading: _isPeekingNow,
              onSubmitted: _peek,
            ),
            if (_previewError != null) ...[
              const SizedBox(height: 10),
              _ErrorBanner(message: _previewError!),
            ],
            const SizedBox(height: 16),
            if (_preview == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isPeekingNow ? null : _peek,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Look up invite'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kAccentDeep,
                    side: BorderSide(
                        color: _kAccent.withValues(alpha: 0.5)),
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                ),
              )
            else ...[
              _InvitePreviewCard(invite: _preview!),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_preview!.isUsable && !_isRedeemingNow)
                      ? _redeem
                      : null,
                  icon: _isRedeemingNow
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isRedeemingNow
                        ? 'Joining…'
                        : 'Join ${_preview!.elderName}\'s care team',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccentDeep,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _HelperFooter(),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Code input — large, uppercase, dash-stripped
// ---------------------------------------------------------------------------

class _CodeInput extends StatelessWidget {
  const _CodeInput({
    required this.controller,
    required this.isLoading,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-\s]')),
        _UppercaseFormatter(),
      ],
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: 3.0,
      ),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: 'ABCD-EFGH',
        hintStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 3.0,
          color: AppTheme.textLight,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          borderSide: BorderSide(color: _kAccentDeep, width: 1.8),
        ),
        suffixIcon: isLoading
            ? Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kAccentDeep),
                ),
              )
            : IconButton(
                tooltip: 'Look up',
                icon: Icon(Icons.arrow_forward, color: _kAccentDeep),
                onPressed: onSubmitted,
              ),
      ),
      onSubmitted: (_) => onSubmitted(),
    );
  }
}

class _UppercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// ---------------------------------------------------------------------------
// Preview card — shown after a successful peek()
// ---------------------------------------------------------------------------

class _InvitePreviewCard extends StatelessWidget {
  const _InvitePreviewCard({required this.invite});
  final InviteCode invite;

  @override
  Widget build(BuildContext context) {
    final role = CaregiverRoleX.fromString(invite.role);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        border: Border.all(color: _kAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: _kAccentDeep, size: 22),
              const SizedBox(width: 10),
              const Text(
                'You\'ve been invited',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            invite.createdByName == null
                ? 'A caregiver invited you to help with '
                    '${invite.elderName}\'s care.'
                : '${invite.createdByName} invited you to help with '
                    '${invite.elderName}\'s care.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _MetaRow(
            icon: Icons.shield_outlined,
            label: 'Access',
            value: '${role.label} — ${role.description}',
          ),
          _MetaRow(
            icon: Icons.schedule_outlined,
            label: 'Expires',
            value: _expiryText(invite.timeUntilExpiry),
          ),
          if (invite.maxUses > 1)
            _MetaRow(
              icon: Icons.people_alt_outlined,
              label: 'Redemptions',
              value:
                  '${invite.uses} of ${invite.maxUses} used · ${invite.remainingUses} left',
            ),
        ],
      ),
    );
  }

  String _expiryText(Duration remaining) {
    if (remaining.isNegative) return 'Expired';
    if (remaining.inDays >= 1) {
      return 'in ${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'}';
    }
    if (remaining.inHours >= 1) {
      return 'in ${remaining.inHours} hour${remaining.inHours == 1 ? '' : 's'}';
    }
    return 'soon';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _kAccentDeep),
          const SizedBox(width: 8),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error + helper bits
// ---------------------------------------------------------------------------

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
        border: Border.all(
            color: AppTheme.dangerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 16, color: AppTheme.dangerColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.dangerColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignedOutBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.lock_outline,
              size: 40, color: _kAccent.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          const Text(
            'Sign in to redeem an invite.',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your account keeps your access separate from the inviter\'s.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HelperFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline,
              size: 14, color: AppTheme.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Codes are typically 8 characters (letters and numbers). Dashes '
              'and spaces don\'t matter — we\'ll clean it up automatically.',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.textSecondary,
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
// Success dialog
// ---------------------------------------------------------------------------

class _RedeemResultDialog extends StatelessWidget {
  const _RedeemResultDialog({
    required this.elderName,
    required this.role,
    required this.alreadyJoined,
  });

  final String elderName;
  final CaregiverRole role;
  final bool alreadyJoined;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusL)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.statusGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check,
                size: 42, color: AppTheme.statusGreen),
          ),
          const SizedBox(height: 16),
          Text(
            alreadyJoined
                ? 'You\'re already on this team'
                : 'You\'re in',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            alreadyJoined
                ? 'You\'ve already joined $elderName\'s care team. No changes made.'
                : 'You now have ${role.label.toLowerCase()} access to $elderName\'s '
                    'care timeline.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: _kAccentDeep),
          child: const Text('Open timeline'),
        ),
      ],
    );
  }
}
