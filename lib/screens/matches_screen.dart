import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/match_fixture.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({
    super.key,
    required this.fixtures,
    required this.liveDataMessage,
    required this.loadingLiveData,
    required this.onOpenMatch,
  });

  final List<MatchFixture> fixtures;
  final String liveDataMessage;
  final bool loadingLiveData;
  final ValueChanged<MatchFixture> onOpenMatch;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Premier League', 'Champions League', 'Europa League'];
    final source = widget.fixtures.isEmpty ? mockFixtures : widget.fixtures;
    final matches = source.where((match) {
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || match.title.toLowerCase().contains(q) || match.competition.toLowerCase().contains(q) || match.venue.toLowerCase().contains(q);
      if (!matchesQuery) return false;
      if (_filter == 'All') return true;
      return match.competition.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Choose a match', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Start with the fixture. MatchPint then finds the right pub for the type of night you want.', style: TextStyle(color: AppTheme.subtleText(context))),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                widget.loadingLiveData
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.sports_soccer, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.liveDataMessage, style: TextStyle(fontSize: 12.5, color: AppTheme.subtleText(context), height: 1.35))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search team, competition, or venue'),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: filters.map((f) => ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f))).toList(),
        ),
        const SizedBox(height: 18),
        if (matches.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('No fixtures match your search yet.', style: TextStyle(color: AppTheme.subtleText(context))),
            ),
          )
        else
          ...matches.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MatchCard(fixture: m, onTap: () => widget.onOpenMatch(m)),
              )),
      ],
    );
  }
}
