import 'package:flutter/material.dart' hide Badge; // Hide Material's Badge
import 'package:cecelia_care_flutter/models/badge.dart';

class BadgeTile extends StatelessWidget {
  final Badge badge;

  const BadgeTile({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.5, // Dim if not unlocked
      child: Card(
        elevation: badge.unlocked ? 4.0 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content
            mainAxisSize: MainAxisSize.min, // Take minimum space
            children: <Widget>[
              // Display PNG image
              Image.asset(
                badge.imagePath,
                width: 64.0, // Adjust size as needed
                height: 64.0, // Adjust size as needed
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image fails to load
                  return const Icon(Icons.error_outline, size: 64.0, color: Colors.grey);
                },
              ),
              const SizedBox(height: 8.0),
              Text(
                badge.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1, // Prevent wrapping
                overflow: TextOverflow.ellipsis, // Add ellipsis for long labels
              ),
            ],
          ),
        ),
      ),
    );
  }
}
