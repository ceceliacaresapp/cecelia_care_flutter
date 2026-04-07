import 'package:flutter/material.dart';

class EmojiSelector extends StatelessWidget {
  final List<String> emojis;
  final String? selected;
  final ValueChanged<String> onTap;

  const EmojiSelector({
    super.key,
    required this.emojis,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: emojis.map((e) {
      final isSel = e == selected;
      return GestureDetector(
        onTap: () => onTap(e), // Ensure onTap is called correctly
        child: Text(
          e,
          style: TextStyle(
            fontSize: 32,
            color: DefaultTextStyle.of(
              context,
            ).style.color?.withValues(alpha: isSel ? 1.0 : 0.4),
          ),
        ),
      );
    }).toList(),
  );
}
