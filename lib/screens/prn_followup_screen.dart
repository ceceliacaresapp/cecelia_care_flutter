// lib/screens/prn_followup_screen.dart
//
// Quick response screen shown when a caregiver taps a PRN follow-up
// notification ("Did {medName} help?"). Four tappable response buttons,
// saves to the original journal entry, pops back.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class PrnFollowupScreen extends StatefulWidget {
  const PrnFollowupScreen({
    super.key,
    required this.entryId,
    required this.medName,
    required this.elderId,
  });

  final String entryId;
  final String medName;
  final String elderId;

  @override
  State<PrnFollowupScreen> createState() => _PrnFollowupScreenState();
}

class _PrnFollowupScreenState extends State<PrnFollowupScreen> {
  bool _saving = false;
  bool _done = false;

  Future<void> _respond(String response) async {
    if (_saving || _done) return;
    setState(() => _saving = true);
    try {
      await context
          .read<FirestoreService>()
          .updatePrnFollowUp(widget.entryId, response);
      HapticUtils.success();
      setState(() => _done = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thanks — logged!'),
              backgroundColor: Colors.green),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('PrnFollowupScreen: error saving response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Could not save: $e'),
              backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-Up'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.tileBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.medication_outlined,
                    size: 48, color: AppTheme.tileBlue),
              ),
              const SizedBox(height: 24),
              Text(
                'How did ${widget.medName} work?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Your response helps track medication effectiveness.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4),
              ),
              const SizedBox(height: 28),
              _ResponseButton(
                label: 'Much better',
                icon: Icons.sentiment_very_satisfied,
                color: AppTheme.statusGreen,
                onTap: () => _respond('muchBetter'),
                saving: _saving,
              ),
              const SizedBox(height: 10),
              _ResponseButton(
                label: 'Somewhat better',
                icon: Icons.sentiment_satisfied,
                color: const Color(0xFF7CB342),
                onTap: () => _respond('somewhat'),
                saving: _saving,
              ),
              const SizedBox(height: 10),
              _ResponseButton(
                label: 'No change',
                icon: Icons.sentiment_neutral,
                color: AppTheme.statusAmber,
                onTap: () => _respond('noChange'),
                saving: _saving,
              ),
              const SizedBox(height: 10),
              _ResponseButton(
                label: 'Worse',
                icon: Icons.sentiment_very_dissatisfied,
                color: AppTheme.statusRed,
                onTap: () => _respond('worse'),
                saving: _saving,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponseButton extends StatelessWidget {
  const _ResponseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.saving,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: saving ? null : onTap,
        icon: Icon(icon, size: 22),
        label: Text(label,
            style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusM)),
        ),
      ),
    );
  }
}
