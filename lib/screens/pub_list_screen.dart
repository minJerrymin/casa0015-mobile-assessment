import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/pub_card.dart';

class PubListScreen extends StatefulWidget {
  const PubListScreen({
    super.key,
    required this.preferences,
    required this.onOpenPub,
    required this.pubs,
    required this.fixtures,
    required this.liveDataMessage,
    required this.locationMessage,
    required this.gettingLocation,
    required this.onUseCurrentLocation,
    this.fixture,
  });

  final UserPreferences preferences;
  final ValueChanged<PubSpot> onOpenPub;
  final List<PubSpot> pubs;
  final List<MatchFixture> fixtures;
  final String liveDataMessage;
  final String locationMessage;
  final bool gettingLocation;
  final Future<void> Function() onUseCurrentLocation;
  final MatchFixture? fixture;

  @override
  State<PubListScreen> createState() => _PubListScreenState();
}

class _PubListScreenState extends State<PubListScreen> {
  bool _calmOnly = false;
  bool _soloOnly = false;
  bool _foodFirst = false;
  String _query = '';

  bool _matchesFixture(PubSpot pub, MatchFixture fixture) => pubIsShowingFixture(pub, fixture);

  int _fixtureBoost(PubSpot pub, MatchFixture? fixture) {
    final selectedFixture = fixture ?? bestFixtureForPub(pub, preferences: widget.preferences, fixtures: _fixtures);
    return (fixtureBroadcastScore(pub, selectedFixture) / 4).round();
  }

  List<MatchFixture> get _fixtures => widget.fixtures.isEmpty ? mockFixtures : widget.fixtures;
  List<PubSpot> get _pubs => widget.pubs.isEmpty ? mockPubs : widget.pubs;

  double _distanceFor(PubSpot pub) => pub.distanceKm;

  @override
  Widget build(BuildContext context) {
    final title = widget.fixture == null ? 'Find pubs' : 'Pubs for ${widget.fixture!.title}';
    final q = _query.trim().toLowerCase();
    final fixture = widget.fixture;
    final allPubs = _pubs;
    final fixtureMatched = fixture == null ? allPubs : allPubs.where((p) => _matchesFixture(p, fixture)).toList();
    final basePubs = fixture == null || fixtureMatched.isNotEmpty ? fixtureMatched : allPubs;
    final pubs = basePubs.where((p) {
      if (_calmOnly && p.noiseDb > 65) return false;
      if (_soloOnly && !p.soloFriendly) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.area.toLowerCase().contains(q) || p.features.any((f) => f.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) {
        if (_foodFirst) return b.foodScore.compareTo(a.foodScore);
        final aDistance = _distanceFor(a);
        final bDistance = _distanceFor(b);
        final aScore = a.comfortScore(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly, wantsFood: widget.preferences.wantsFood || _foodFirst) +
            _fixtureBoost(a, fixture) -
            (aDistance * 4).round();
        final bScore = b.comfortScore(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly, wantsFood: widget.preferences.wantsFood || _foodFirst) +
            _fixtureBoost(b, fixture) -
            (bDistance * 4).round();
        return bScore.compareTo(aScore);
      });

    final prefs = widget.preferences.copyWith(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly);
    final subtitle = fixture == null
        ? '${pubs.length} spots ranked by atmosphere fit, screen quality, comfort, and live distance.'
        : '${pubs.length} spots likely to show this fixture. Broadcast status is estimated unless users or venues confirm it.';

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(color: AppTheme.subtleText(context))),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.public, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.liveDataMessage, style: TextStyle(color: AppTheme.subtleText(context), fontSize: 12.5, height: 1.35))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search pub, area, or feature'),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.locationMessage, style: TextStyle(color: AppTheme.subtleText(context)))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: widget.gettingLocation ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.location_searching),
                    label: Text(widget.gettingLocation ? 'Updating nearby pubs...' : 'Refresh my location'),
                    onPressed: widget.gettingLocation ? null : widget.onUseCurrentLocation,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilterChip(label: const Text('Calm only'), selected: _calmOnly, onSelected: (v) => setState(() => _calmOnly = v)),
          FilterChip(label: const Text('Solo-friendly'), selected: _soloOnly, onSelected: (v) => setState(() => _soloOnly = v)),
          FilterChip(label: const Text('Food first'), selected: _foodFirst, onSelected: (v) => setState(() => _foodFirst = v)),
        ]),
        const SizedBox(height: 18),
        if (pubs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('No pubs match your current filters yet.', style: TextStyle(color: AppTheme.subtleText(context))),
            ),
          )
        else
          ...pubs.map((p) {
            final selectedFixture = fixture ?? bestFixtureForPub(p, preferences: widget.preferences, fixtures: _fixtures);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PubCard(
                pub: p,
                preferences: prefs,
                distanceKmOverride: _distanceFor(p),
                matchLabel: selectedFixture.title,
                broadcastConfidence: fixtureBroadcastScore(p, selectedFixture),
                onTap: () => widget.onOpenPub(p),
              ),
            );
          }),
      ],
    );
  }
}
