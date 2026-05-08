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
    this.distanceKmOverride,
    this.matchLabel,
    this.broadcastConfidence,
  });

  final PubSpot pub;
  final UserPreferences preferences;
  final VoidCallback onTap;
  final double? distanceKmOverride;
  final String? matchLabel;
  final int? broadcastConfidence;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final distance = distanceKmOverride ?? pub.distanceKm;
    final score = pub.comfortScore(
      prefersCalm: preferences.prefersCalm,
      soloMode: preferences.soloMode,
      wantsFood: preferences.wantsFood,
    );
    bool isEvidenceTag(String tag) {
      final value = tag.toLowerCase();
      return value.contains('external sports-pub') ||
          value.contains('guide') ||
          value.contains('source') ||
          value.contains('verified') ||
          value.contains('osm ') ||
          value.contains('evidence') ||
          value.contains('metadata') ||
          value.contains('user-confirmed') ||
          value.contains('comment confirmed');
    }
    final featureTags = pub.features.where((feature) => !isEvidenceTag(feature)).take(3).toList();
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
                        Text('${pub.area} • ${distance.toStringAsFixed(1)} km away', style: TextStyle(color: muted)),
                        const SizedBox(height: 6),
                        _EvidenceBadge(pub: pub),
                      ],
                    ),
                  ),
                  ScorePill(score: score, label: 'fit'),
                ],
              ),
              if (matchLabel != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.live_tv, size: 15, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          broadcastConfidence == null ? 'Predicted: $matchLabel' : 'Predicted best match: $matchLabel • $broadcastConfidence% fit',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Tag(icon: Icons.volume_up, label: '${pub.noiseDb} dB'),
                  _Tag(icon: Icons.people, label: '${pub.crowdLevel}% crowd'),
                  _Tag(icon: Icons.tv, label: '${pub.screenQuality}% screens'),
                  if (pub.soloFriendly) const _Tag(icon: Icons.person, label: 'solo-friendly'),
                  ...featureTags.map((feature) => _Tag(icon: Icons.local_offer_outlined, label: feature)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvidenceBadge extends StatelessWidget {
  const _EvidenceBadge({required this.pub});

  final PubSpot pub;

  @override
  Widget build(BuildContext context) {
    final color = pub.verifiedFootballFriendly
        ? Colors.green.shade700
        : pub.likelyFootballFriendly
            ? Theme.of(context).colorScheme.primary
            : AppTheme.subtleText(context);
    final icon = pub.verifiedFootballFriendly
        ? Icons.verified
        : pub.likelyFootballFriendly
            ? Icons.rule
            : Icons.help_outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(pub.evidenceTierLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
        ],
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
