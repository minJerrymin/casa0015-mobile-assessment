import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScorePill extends StatelessWidget {
  const ScorePill({super.key, required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? Theme.of(context).colorScheme.primary
        : score >= 65
            ? AppTheme.pintGold
            : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$score', style: TextStyle(color: color, fontWeight: FontWeight.w900)),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}
