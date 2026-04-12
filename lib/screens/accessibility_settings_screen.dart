// lib/screens/accessibility_settings_screen.dart
//
// Dedicated accessibility settings: Visual+Vibration Only toggle,
// link to Communication Cards, and future expansion hooks.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/providers/accessibility_provider.dart';
import 'package:cecelia_care_flutter/screens/communication_cards_screen.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final accessProv = context.watch<AccessibilityProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        children: [
          // ── Info card ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.tileBlueDark.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Cecelia Care is designed to be accessible for both '
              'caregivers and care recipients. These settings help '
              'customize the experience for different sensory needs.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ),

          // ── Section 1: Sensory Preferences ──────────────────────
          _sectionHeader(context, 'Sensory Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_off_outlined),
            title: const Text('Visual + Vibration Only'),
            subtitle: const Text(
              'Mute notification sounds. Alerts use vibration and '
              'on-screen banners only.',
              style: TextStyle(fontSize: 12),
            ),
            value: accessProv.isVisualOnly,
            onChanged: (value) async {
              await accessProv.toggleVisualOnlyMode(value);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(value
                      ? 'Notifications set to vibration only.'
                      : 'Notification sounds re-enabled.'),
                ));
              }
            },
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Section 2: Communication Aids ───────────────────────
          _sectionHeader(context, 'Communication Aids'),
          ListTile(
            leading: const Icon(Icons.sign_language, color: AppTheme.tilePurple),
            title: const Text('Communication Cards + ASL'),
            subtitle: const Text(
              'Picture cards and ASL signs for non-verbal communication',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right,
                color: AppTheme.textLight, size: 20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CommunicationCardsScreen()),
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // ── Section 3: Display (future) ─────────────────────────
          _sectionHeader(context, 'Display'),
          _comingSoonTile(Icons.contrast, 'High Contrast Mode'),
          _comingSoonTile(Icons.text_fields, 'Large Text Override'),
          _comingSoonTile(Icons.animation, 'Reduced Motion'),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _comingSoonTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade400),
      title: Text(title,
          style: TextStyle(color: Colors.grey.shade400)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Coming soon',
            style: TextStyle(fontSize: 10, color: Colors.grey)),
      ),
    );
  }
}
