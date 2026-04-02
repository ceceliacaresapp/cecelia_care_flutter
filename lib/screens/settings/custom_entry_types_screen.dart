// lib/screens/settings/custom_entry_types_screen.dart
//
// CRUD management for custom care log categories.
// Admins create, edit, and delete custom entry types here.
// Accessed from Settings → Custom Entry Types.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/custom_entry_type.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/custom_entry_types_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class CustomEntryTypesScreen extends StatelessWidget {
  const CustomEntryTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final types = context.watch<CustomEntryTypesProvider>().types;
    final isLoading = context.watch<CustomEntryTypesProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Entry Types'),
        centerTitle: true,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, null),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : types.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.extension_outlined,
                            size: 56, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text(
                          'No custom entry types yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create categories like "Wound Check", '
                          '"Behavior Log", or "Fluid Intake" — '
                          'anything your care routine needs.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: types.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = types[i];
                    return _TypeCard(
                      type: t,
                      onTap: () => _openEditor(context, t),
                      onDelete: () => _confirmDelete(context, t),
                    );
                  },
                ),
    );
  }

  void _openEditor(BuildContext context, CustomEntryType? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CustomEntryTypeEditor(existing: existing),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CustomEntryType type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${type.name}"?'),
        content: const Text(
          'This removes the type definition. '
          'Existing entries already logged with this type will '
          'still appear on the timeline.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final elder =
          context.read<ActiveElderProvider>().activeElder;
      if (elder == null || type.id == null) return;
      await context
          .read<FirestoreService>()
          .deleteCustomEntryType(elder.id, type.id!);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Type card — shown in the list
// ---------------------------------------------------------------------------
class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.onTap,
    required this.onDelete,
  });

  final CustomEntryType type;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: type.color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: type.color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(type.iconData, color: type.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: type.color,
                    ),
                  ),
                  Text(
                    '${type.fields.length} field${type.fields.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 18, color: type.color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor — create or edit a custom entry type
// ---------------------------------------------------------------------------
class _CustomEntryTypeEditor extends StatefulWidget {
  const _CustomEntryTypeEditor({this.existing});
  final CustomEntryType? existing;

  @override
  State<_CustomEntryTypeEditor> createState() =>
      _CustomEntryTypeEditorState();
}

class _CustomEntryTypeEditorState extends State<_CustomEntryTypeEditor> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'note';
  String _selectedColor = '#1E88E5';
  final List<_FieldDraft> _fields = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameCtrl.text = e.name;
      _selectedIcon = e.iconName;
      _selectedColor = e.colorHex;
      _fields.addAll(e.fields.map((f) => _FieldDraft(
            labelCtrl: TextEditingController(text: f.label),
            fieldType: f.fieldType,
            required: f.required,
            optionsCtrl:
                TextEditingController(text: f.options?.join(', ') ?? ''),
          )));
    }
    if (_fields.isEmpty) _addField();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final f in _fields) {
      f.labelCtrl.dispose();
      f.optionsCtrl.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() => _fields.add(_FieldDraft(
          labelCtrl: TextEditingController(),
          optionsCtrl: TextEditingController(),
        )));
  }

  void _removeField(int index) {
    if (_fields.length <= 1) return;
    _fields[index].labelCtrl.dispose();
    _fields[index].optionsCtrl.dispose();
    setState(() => _fields.removeAt(index));
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final validFields = _fields.where(
        (f) => f.labelCtrl.text.trim().isNotEmpty);
    if (validFields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add at least one field with a label')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final elder =
          context.read<ActiveElderProvider>().activeElder;
      final user = FirebaseAuth.instance.currentUser;
      if (elder == null || user == null) return;

      final fields = validFields.map((f) {
        final label = f.labelCtrl.text.trim();
        final key = label
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]'), '_');
        return CustomField(
          key: key,
          label: label,
          fieldType: f.fieldType,
          required: f.required,
          options: f.fieldType == 'dropdown'
              ? f.optionsCtrl.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList()
              : null,
        );
      }).toList();

      final type = CustomEntryType(
        id: widget.existing?.id,
        name: name,
        iconName: _selectedIcon,
        colorHex: _selectedColor,
        fields: fields,
        createdBy: user.uid,
        elderId: elder.id,
      );

      final fs = context.read<FirestoreService>();
      if (_isEditing && widget.existing?.id != null) {
        await fs.updateCustomEntryType(
            elder.id, widget.existing!.id!, type);
      } else {
        await fs.addCustomEntryType(elder.id, type);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color get _activeColor {
    try {
      final hex = _selectedColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _activeColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry Type' : 'New Entry Type'),
        centerTitle: true,
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // Preview
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      CustomEntryType.kAvailableIcons[_selectedIcon] ??
                          Icons.note_outlined,
                      color: color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _nameCtrl.text.isEmpty ? 'Preview' : _nameCtrl.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Name
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: 'Entry type name',
              hintText: 'e.g., Wound Check, Fluid Intake',
              filled: true,
              fillColor: color.withOpacity(0.04),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Icon picker
          Text('ICON',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CustomEntryType.kAvailableIcons.entries
                .map((e) => GestureDetector(
                      onTap: () =>
                          setState(() => _selectedIcon = e.key),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _selectedIcon == e.key
                              ? color.withOpacity(0.15)
                              : AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedIcon == e.key
                                ? color
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(e.value,
                            size: 22,
                            color: _selectedIcon == e.key
                                ? color
                                : AppTheme.textSecondary),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          // Color picker
          Text('COLOR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: AppTheme.textSecondary,
              )),
          const SizedBox(height: 8),
          Row(
            children: CustomEntryType.kAvailableColors
                .map((hex) {
                  Color c;
                  try {
                    c = Color(
                        int.parse('FF${hex.replaceFirst('#', '')}',
                            radix: 16));
                  } catch (_) {
                    c = AppTheme.textSecondary;
                  }
                  final selected = _selectedColor == hex;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedColor = hex),
                      child: Container(
                        height: 36,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 2),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(
                                  color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                      color: c.withOpacity(0.5),
                                      blurRadius: 6)
                                ]
                              : null,
                        ),
                        child: selected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    ),
                  );
                })
                .toList(),
          ),
          const SizedBox(height: 24),

          // Fields builder
          Row(
            children: [
              Text('FIELDS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppTheme.textSecondary,
                  )),
              const Spacer(),
              TextButton.icon(
                onPressed: _addField,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add field'),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          ...List.generate(_fields.length, (i) {
            final f = _fields[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: f.labelCtrl,
                          decoration: InputDecoration(
                            labelText: 'Field label',
                            hintText: 'e.g., Size (cm)',
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          value: f.fieldType,
                          isDense: true,
                          decoration: InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'text', child: Text('Text')),
                            DropdownMenuItem(
                                value: 'number',
                                child: Text('Number')),
                            DropdownMenuItem(
                                value: 'longtext',
                                child: Text('Long text')),
                            DropdownMenuItem(
                                value: 'dropdown',
                                child: Text('Dropdown')),
                            DropdownMenuItem(
                                value: 'toggle',
                                child: Text('Toggle')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => f.fieldType = v);
                            }
                          },
                        ),
                      ),
                      if (_fields.length > 1)
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removeField(i),
                          color: AppTheme.dangerColor,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  if (f.fieldType == 'dropdown') ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: f.optionsCtrl,
                      decoration: InputDecoration(
                        labelText: 'Options (comma-separated)',
                        hintText: 'Improving, Stable, Worsening',
                        isDense: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text('Required',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Switch(
                        value: f.required,
                        onChanged: (v) =>
                            setState(() => f.required = v),
                        activeColor: color,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      _isEditing ? 'Update Entry Type' : 'Create Entry Type',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Mutable draft for a field being edited
class _FieldDraft {
  final TextEditingController labelCtrl;
  final TextEditingController optionsCtrl;
  String fieldType;
  bool required;

  _FieldDraft({
    required this.labelCtrl,
    required this.optionsCtrl,
    this.fieldType = 'text',
    this.required = false,
  });
}
