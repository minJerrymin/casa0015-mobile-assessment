import 'package:flutter/material.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_bar.dart';
import '../widgets/score_pill.dart';

class PubDetailScreen extends StatelessWidget {
  const PubDetailScreen({
    super.key,
    required this.pub,
    required this.preferences,
    required this.onStartMatchMode,
    this.fixture,
  });

  final PubSpot pub;
  final UserPreferences preferences;
  final MatchFixture? fixture;
  final VoidCallback onStartMatchMode;

  @override
  Widget build(BuildContext context) {
    final score = pub.comfortScore(prefersCalm: preferences.prefersCalm, soloMode: preferences.soloMode);
    return Scaffold(
      appBar: AppBar(title: Text(pub.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(colors: [AppTheme.pitchGreen.withOpacity(0.22), AppTheme.pintGold.withOpacity(0.24)]),
            ),
            child: const Center(child: Icon(Icons.sports_bar, size: 76, color: AppTheme.cream)),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Text(pub.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900))),
              ScorePill(score: score, label: 'fit'),
            ],
          ),
          const SizedBox(height: 6),
          Text('${pub.area} • ${pub.distanceKm.toStringAsFixed(1)} km away • ${pub.vibe}', style: const TextStyle(color: AppTheme.muted)),
          const SizedBox(height: 16),
          Text(pub.description, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Matchday signals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  MetricBar(label: 'Screen quality', value: pub.screenQuality, trailing: '${pub.screenQuality}%'),
                  MetricBar(label: 'Crowd level', value: pub.crowdLevel, trailing: '${pub.crowdLevel}%'),
                  MetricBar(label: 'Typical noise', value: pub.noiseDb, trailing: '${pub.noiseDb} dB'),
                  MetricBar(label: 'Food rating', value: pub.foodScore, trailing: '${pub.foodScore}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Why it fits', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: pub.features.map((f) => Chip(label: Text(f))).toList()),
          const SizedBox(height: 28),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(fixture == null ? 'Start match mode' : 'Start match mode for ${fixture!.homeTeam}'),
            onPressed: onStartMatchMode,
          ),
        ],
      ),
    );
  }
}
