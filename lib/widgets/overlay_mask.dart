// lib/widgets/overlay_mask.dart

import 'package:flutter/material.dart';

class OverlayMask extends StatelessWidget {
  final Widget child;
  final VoidCallback onClose;

  const OverlayMask({super.key, required this.child, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Semi‐transparent background
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black54,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Centered content
        Center(child: child),
      ],
    );
  }
}
