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
    required this.fixtures,
    required this.pubs,
    required this.liveDataMessage,
    required this.loadingLiveData,
    required this.onRefreshLiveData,
    required this.onOpenMatch,
    required this.onOpenPub,
    required this.onShowMatches,
    required this.onShowPubs,
  });

  final UserPreferences preferences;
  final List<MatchFixture> fixtures;
  final List<PubSpot> pubs;
  final String liveDataMessage;
  final bool loadingLiveData;
  final Future<void> Function({double? latitude, double? longitude}) onRefreshLiveData;
  final ValueChanged<MatchFixture> onOpenMatch;
  final ValueChanged<PubSpot> onOpenPub;
  final VoidCallback onShowMatches;
  final VoidCallback onShowPubs;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final fixtureSource = fixtures.isEmpty ? mockFixtures : fixtures;
    final pubSource = pubs.isEmpty ? mockPubs : pubs;
    final heroMatch = bestMatchForHome(preferences, fixtureSource);
    final recommended = [...pubSource]
      ..sort((a, b) {
        final aScore = a.comfortScore(prefersCalm: preferences.prefersCalm, soloMode: preferences.soloMode, wantsFood: preferences.wantsFood) + (a.sportsEvidenceScore / 4).round();
        final bScore = b.comfortScore(prefersCalm: preferences.prefersCalm, soloMode: preferences.soloMode, wantsFood: preferences.wantsFood) + (b.sportsEvidenceScore / 4).round();
        return bScore.compareTo(aScore);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Tonight, find your screen.', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('${preferences.team} • ${preferences.prefersCalm ? 'calm' : 'atmosphere'} • ${preferences.soloMode ? 'solo-friendly' : 'group-friendly'}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
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
        ...fixtureSource.take(2).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchCard(fixture: m, onTap: () => onOpenMatch(m)),
            )),
        const SizedBox(height: 10),
        _SectionHeader(title: 'Recommended pubs', action: 'View all', onTap: onShowPubs),
        const SizedBox(height: 12),
        ...recommended.take(2).map((p) {
          final fixture = bestFixtureForPub(p, preferences: preferences, fixtures: fixtureSource);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: PubCard(
              pub: p,
              preferences: preferences,
              matchLabel: fixture.title,
              broadcastConfidence: fixtureBroadcastScore(p, fixture),
              onTap: () => onOpenPub(p),
            ),
          );
        }),
      ],
    );
  }
}

class _LiveDataCard extends StatelessWidget {
  const _LiveDataCard({required this.message, required this.loading, required this.onRefresh});
  final String message;
  final bool loading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.cloud_done, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontSize: 12.5, color: AppTheme.subtleText(context), height: 1.35))),
            IconButton(onPressed: loading ? null : onRefresh, icon: const Icon(Icons.refresh)),
          ],
        ),
      ),
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
