import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/match_fixture.dart';
import '../theme/app_theme.dart';
import '../widgets/match_card.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, required this.onOpenMatch});
  final ValueChanged<MatchFixture> onOpenMatch;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  String _filter = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Premier League', 'Women’s football', 'London'];
    final matches = mockFixtures.where((match) {
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || match.title.toLowerCase().contains(q) || match.competition.toLowerCase().contains(q) || match.venue.toLowerCase().contains(q);
      if (!matchesQuery) return false;
      if (_filter == 'All') return true;
      if (_filter == 'Women’s football') return match.title.toLowerCase().contains('women');
      if (_filter == 'London') return ['Arsenal', 'Chelsea', 'Tottenham', 'West Ham'].any(match.title.contains);
      return match.competition == _filter;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Choose a match', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Start with the fixture. MatchPint then finds the right pub for the type of night you want.', style: TextStyle(color: AppTheme.subtleText(context))),
        const SizedBox(height: 18),
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
