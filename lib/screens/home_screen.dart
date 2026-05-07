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
    required this.onShowMatches,
    required this.onShowPubs,
  });

  final UserPreferences preferences;
  final ValueChanged<MatchFixture> onOpenMatch;
  final ValueChanged<PubSpot> onOpenPub;
  final VoidCallback onShowMatches;
  final VoidCallback onShowPubs;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final heroMatch = mockFixtures.firstWhere((m) => m.homeTeam == preferences.team || m.awayTeam == preferences.team, orElse: () => mockFixtures.first);
    final recommended = [...mockPubs]
      ..sort((a, b) => b.comfortScore(prefersCalm: preferences.prefersCalm, soloMode: preferences.soloMode, wantsFood: preferences.wantsFood).compareTo(a.comfortScore(prefersCalm: preferences.prefersCalm, soloMode: preferences.soloMode, wantsFood: preferences.wantsFood)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Tonight, find your screen.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('Profile: ${preferences.team} • ${preferences.prefersCalm ? 'calm' : 'atmosphere'} • ${preferences.soloMode ? 'solo-friendly' : 'group-friendly'}', style: TextStyle(color: muted)),
        const SizedBox(height: 20),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => onOpenMatch(heroMatch),
            child: Ink(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Theme.of(context).colorScheme.primary.withOpacity(0.28), AppTheme.pintGold.withOpacity(0.16)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Best match to plan', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(heroMatch.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('${heroMatch.competition} • ${heroMatch.venue}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85))),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.search),
                    label: const Text('Find pubs for this match'),
                    onPressed: () => onOpenMatch(heroMatch),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _SectionHeader(title: 'Upcoming matches', action: 'View all', onTap: onShowMatches),
        const SizedBox(height: 12),
        ...mockFixtures.take(2).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchCard(fixture: m, onTap: () => onOpenMatch(m)),
            )),
        const SizedBox(height: 10),
        _SectionHeader(title: 'Recommended pubs', action: 'View all', onTap: onShowPubs),
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
  const _SectionHeader({required this.title, required this.action, required this.onTap});
  final String title;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }
}
