// lib/widgets/pin_gate.dart
//
// Simple 4-digit PIN gate dialog for controlled substance access.
// The PIN is stored per elder in SharedPreferences. First use prompts
// the caregiver to create a PIN; subsequent uses verify it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Returns true if the user successfully verified (or created) the PIN.
/// Returns false if cancelled.
Future<bool> verifyControlledSubstancePin(
  BuildContext context, {
  required String elderId,
}) async {
  final sp = await SharedPreferences.getInstance();
  final key = 'controlled_pin_$elderId';
  final storedPin = sp.getString(key);

  if (!context.mounted) return false;

  if (storedPin == null) {
    // First time — create a PIN.
    return await _showCreatePinDialog(context, key, sp);
  } else {
    // Verify existing PIN.
    return await _showVerifyPinDialog(context, storedPin);
  }
}

Future<bool> _showCreatePinDialog(
    BuildContext context, String key, SharedPreferences sp) async {
  final controller = TextEditingController();
  final confirmController = TextEditingController();

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppTheme.tileOrange, size: 22),
          const SizedBox(width: 8),
          const Text('Create Vault PIN'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Set a 4-digit PIN to protect controlled substance records. '
            'All care team members will use this PIN.',
            style: TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: confirmController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Confirm PIN',
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (controller.text.length != 4) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits.')));
              return;
            }
            if (controller.text != confirmController.text) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PINs do not match.')));
              return;
            }
            sp.setString(key, controller.text);
            Navigator.pop(ctx, true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.tileOrange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Set PIN'),
        ),
      ],
    ),
  );

  controller.dispose();
  confirmController.dispose();
  return result == true;
}

Future<bool> _showVerifyPinDialog(
    BuildContext context, String storedPin) async {
  final controller = TextEditingController();
  int attempts = 0;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outlined,
                color: AppTheme.tileOrange, size: 22),
            const SizedBox(width: 8),
            const Text('Enter Vault PIN'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 4-digit PIN to access controlled substance records.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'PIN',
                border: const OutlineInputBorder(),
                counterText: '',
                errorText: attempts > 0 ? 'Incorrect PIN' : null,
              ),
              autofocus: true,
              onSubmitted: (_) {
                if (controller.text == storedPin) {
                  Navigator.pop(ctx, true);
                } else {
                  setDialogState(() => attempts++);
                  controller.clear();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == storedPin) {
                Navigator.pop(ctx, true);
              } else {
                setDialogState(() => attempts++);
                controller.clear();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tileOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
      ),
    ),
  );

  controller.dispose();
  return result == true;
}
