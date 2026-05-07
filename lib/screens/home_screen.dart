import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';
import '../widgets/pub_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.preferences,
    required this.onOpenMatch,
    required this.onOpenPub,
  });

  final UserPreferences preferences;
  final ValueChanged<MatchFixture> onOpenMatch;
  final ValueChanged<PubSpot> onOpenPub;

  @override
  Widget build(BuildContext context) {
    final heroMatch = mockFixtures.firstWhere((m) => m.homeTeam == preferences.team || m.awayTeam == preferences.team, orElse: () => mockFixtures.first);
    final recommended = [...mockPubs]
      ..sort((a, b) => b.comfortScore(prefersCalm: preferences.prefersCalm, soloMode: preferences.soloMode).compareTo(a.comfortScore(prefersCalm: preferences.prefersCalm, soloMode: preferences.soloMode)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Tonight, find your screen.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Profile: ${preferences.team} • ${preferences.prefersCalm ? 'calm' : 'atmosphere'} • ${preferences.soloMode ? 'solo-friendly' : 'group-friendly'}', style: const TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.pitchGreen.withOpacity(0.28), AppTheme.pintGold.withOpacity(0.16)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Best match to plan', style: TextStyle(color: AppTheme.cream, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(heroMatch.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('${heroMatch.competition} • ${heroMatch.venue}', style: const TextStyle(color: AppTheme.cream)),
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.search),
                label: const Text('Find pubs for this match'),
                onPressed: () => onOpenMatch(heroMatch),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        _SectionHeader(title: 'Upcoming matches', action: 'View all'),
        const SizedBox(height: 12),
        ...mockFixtures.take(2).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchCard(fixture: m, onTap: () => onOpenMatch(m)),
            )),
        const SizedBox(height: 10),
        _SectionHeader(title: 'Recommended pubs', action: 'Based on your vibe'),
        const SizedBox(height: 12),
        ...recommended.take(2).map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PubCard(pub: p, preferences: preferences, onTap: () => onOpenPub(p)),
            )),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});
  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        Text(action, style: const TextStyle(color: AppTheme.muted)),
      ],
    );
  }
}
