import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MatchPintLogo extends StatelessWidget {
  const MatchPintLogo({super.key, this.size = 108, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.logoSurface(context),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.45), width: 2),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.16),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.sports_soccer, size: size * 0.56, color: Theme.of(context).colorScheme.onSurface),
                Transform.translate(
                  offset: Offset(0, -size * 0.28),
                  child: Icon(Icons.sports_bar, size: size * 0.36, color: AppTheme.pintGold),
                ),
              ],
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 18),
          Text(
            'MatchPint',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find your crowd, not just a screen.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.subtleText(context)),
          ),
        ],
      ],
    );
  }
}
