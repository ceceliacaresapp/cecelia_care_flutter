// lib/widgets/section.dart

import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

/// Just enough so `Section(title: ..., child: ...)` compiles.
class Section extends StatelessWidget {
  final String title;
  final Widget child;

  const Section({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppStyles.screenTitle),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
