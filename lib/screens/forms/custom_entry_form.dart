// lib/screens/forms/custom_entry_form.dart
//
// Dynamic form that renders fields based on a CustomEntryType definition.
// On save, writes through JournalServiceProvider with type 'custom' and
// all display metadata embedded in the data map.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cecelia_care_flutter/models/custom_entry_type.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class CustomEntryForm extends StatefulWidget {
  const CustomEntryForm({
    super.key,
    required this.typeDef,
    required this.activeElder,
    required this.currentDate,
    this.onClose,
  });

  final CustomEntryType typeDef;
  final ElderProfile activeElder;
  final String currentDate;
  final VoidCallback? onClose;

  @override
  State<CustomEntryForm> createState() => _CustomEntryFormState();
}

class _CustomEntryFormState extends State<CustomEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, dynamic> _values = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final field in widget.typeDef.fields) {
      if (field.fieldType == 'toggle') {
        _values[field.key] = false;
      } else if (field.fieldType == 'dropdown') {
        _values[field.key] =
            (field.options != null && field.options!.isNotEmpty)
                ? field.options!.first
                : '';
      } else {
        _textControllers[field.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final ctrl in _textControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final journal = context.read<JournalServiceProvider>();

      // Build payload with all field values
      final payload = <String, dynamic>{
        'elderId': widget.activeElder.id,
        'date': widget.currentDate,
        'loggedByUserId': user.uid,
        'loggedBy': user.displayName ?? user.email ?? 'Unknown',
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
        // Custom type metadata — stored with every entry so rendering
        // works even if the type definition is later edited/deleted
        'customTypeId': widget.typeDef.id ?? '',
        'customTypeName': widget.typeDef.name,
        'customTypeColor': widget.typeDef.colorHex,
        'customTypeIcon': widget.typeDef.iconName,
      };

      // Add field values
      for (final field in widget.typeDef.fields) {
        if (field.fieldType == 'toggle') {
          payload[field.key] = _values[field.key] ?? false;
        } else if (field.fieldType == 'dropdown') {
          payload[field.key] = _values[field.key] ?? '';
        } else {
          payload[field.key] =
              _textControllers[field.key]?.text.trim() ?? '';
        }
      }

      // Build a human-readable summary for the text field
      final summaryParts = <String>[];
      for (final field in widget.typeDef.fields) {
        final val = payload[field.key];
        if (val != null &&
            val.toString().isNotEmpty &&
            val != false) {
          summaryParts.add('${field.label}: $val');
        }
      }
      final summaryText = summaryParts.join(', ');

      payload['text'] = summaryText;

      await journal.addJournalEntry('custom', payload, user.uid);

      if (mounted) {
        HapticUtils.success();
        Navigator.of(context, rootNavigator: true).pop();
        widget.onClose?.call();
      }
    } catch (e) {
      debugPrint('CustomEntryForm._save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save entry: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.typeDef.color;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.typeDef.iconData,
                      color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.typeDef.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Dynamic fields
            ...widget.typeDef.fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildField(field, color),
                )),

            const SizedBox(height: 12),

            // Save button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save ${widget.typeDef.name}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(CustomField field, Color color) {
    switch (field.fieldType) {
      case 'toggle':
        return SwitchListTile(
          value: _values[field.key] ?? false,
          onChanged: (v) => setState(() => _values[field.key] = v),
          title: Text(field.label),
          activeColor: color,
          contentPadding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        );

      case 'dropdown':
        return DropdownButtonFormField<String>(
          value: _values[field.key] as String?,
          decoration: _inputDecoration(field.label, color),
          items: (field.options ?? [])
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: (v) => setState(() => _values[field.key] = v),
          validator: field.required
              ? (v) =>
                  (v == null || v.isEmpty) ? '${field.label} is required' : null
              : null,
        );

      case 'number':
        return TextFormField(
          controller: _textControllers[field.key],
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: _inputDecoration(field.label, color),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '${field.label} is required'
                  : null
              : null,
        );

      case 'longtext':
        return TextFormField(
          controller: _textControllers[field.key],
          maxLines: 4,
          decoration: _inputDecoration(field.label, color),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '${field.label} is required'
                  : null
              : null,
        );

      default: // 'text'
        return TextFormField(
          controller: _textControllers[field.key],
          decoration: _inputDecoration(field.label, color),
          validator: field.required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '${field.label} is required'
                  : null
              : null,
        );
    }
  }

  InputDecoration _inputDecoration(String label, Color color) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: color.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      ),
    );
  }
}
