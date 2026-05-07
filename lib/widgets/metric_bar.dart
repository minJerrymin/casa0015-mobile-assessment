import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MetricBar extends StatelessWidget {
  const MetricBar({super.key, required this.label, required this.value, required this.trailing});

  final String label;
  final int value;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final color = value >= 80 ? Theme.of(context).colorScheme.primary : AppTheme.pintGold;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              Text(trailing, style: TextStyle(color: AppTheme.subtleText(context))),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: value.clamp(0, 100) / 100,
              backgroundColor: AppTheme.softSurface(context),
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
