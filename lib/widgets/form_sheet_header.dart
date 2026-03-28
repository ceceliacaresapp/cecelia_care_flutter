// lib/widgets/form_sheet_header.dart
//
// A shared header for forms rendered inside modal bottom sheets.
// Replaces the AppBar that the forms previously used when they were
// full Scaffold pages.

import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class FormSheetHeader extends StatelessWidget {
  final String title;

  /// If non-null, a delete icon button is shown on the right.
  final VoidCallback? onDelete;
  final String? deleteTooltip;

  /// When true, the delete button is disabled (save/delete in progress).
  final bool isSaving;

  const FormSheetHeader({
    super.key,
    required this.title,
    this.onDelete,
    this.deleteTooltip,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.dangerColor),
              tooltip: deleteTooltip,
              onPressed: isSaving ? null : onDelete,
            ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
