import 'package:flutter/material.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import 'score_pill.dart';

class PubCard extends StatelessWidget {
  const PubCard({
    super.key,
    required this.pub,
    required this.preferences,
    required this.onTap,
  });

  final PubSpot pub;
  final UserPreferences preferences;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final score = pub.comfortScore(
      prefersCalm: preferences.prefersCalm,
      soloMode: preferences.soloMode,
      wantsFood: preferences.wantsFood,
    );
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pub.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${pub.area} • ${pub.distanceKm.toStringAsFixed(1)} km away', style: TextStyle(color: muted)),
                      ],
                    ),
                  ),
                  ScorePill(score: score, label: 'fit'),
                ],
              ),
              const SizedBox(height: 14),
              Text(pub.description, style: const TextStyle(height: 1.35)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(icon: Icons.volume_up, label: '${pub.noiseDb} dB'),
                  _Tag(icon: Icons.people, label: '${pub.crowdLevel}% crowd'),
                  _Tag(icon: Icons.tv, label: '${pub.screenQuality}% screens'),
                  if (pub.soloFriendly) const _Tag(icon: Icons.person, label: 'solo-friendly'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.touch_app, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Tap for venue details and match mode', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.softSurface(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12.5)),
        ],
      ),
    );
  }
}
