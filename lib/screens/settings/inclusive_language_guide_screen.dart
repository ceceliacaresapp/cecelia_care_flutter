import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

class InclusiveLanguageGuideScreen extends StatelessWidget {
  const InclusiveLanguageGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- PERFORMANCE FIX: Step 1 ---
    // Fetch theme and localization data once in the parent widget.
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // --- PERFORMANCE FIX: Step 2 ---
    // Pass the fetched data to a new, private widget that builds the UI.
    return _BuildContent(l10n: l10n, theme: theme);
  }
}

/// --- PERFORMANCE FIX: Step 3 ---
/// This new private widget handles the UI logic, preventing the parent
/// from rebuilding every time a small change occurs.
class _BuildContent extends StatelessWidget {
  const _BuildContent({
    required this.l10n,
    required this.theme,
  });

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inclusiveLanguageGuideTitle),
      ),
      body: SingleChildScrollView(
        padding: AppStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuidanceCard(
              context,
              title: l10n.inclusiveLanguageTip1Title,
              content: l10n.inclusiveLanguageTip1Content,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            _buildGuidanceCard(
              context,
              title: l10n.inclusiveLanguageTip2Title,
              content: l10n.inclusiveLanguageTip2Content,
              textTheme: textTheme,
            ),
            // Add more _buildGuidanceCard widgets here for additional tips
          ],
        ),
      ),
    );
  }

  Widget _buildGuidanceCard(
    BuildContext context, {
    required String title,
    required String content,
    required TextTheme textTheme,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: textTheme.titleLarge?.copyWith(color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            Text(content, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}