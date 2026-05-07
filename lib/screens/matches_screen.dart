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

  @override
  Widget build(BuildContext context) {
    final filters = ['All', 'Premier League', 'Women’s football', 'London'];
    final matches = mockFixtures.where((match) {
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
        const Text('Start with the fixture. MatchPint then finds the right pub for the type of night you want.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          children: filters.map((f) => ChoiceChip(label: Text(f), selected: _filter == f, onSelected: (_) => setState(() => _filter = f))).toList(),
        ),
        const SizedBox(height: 18),
        ...matches.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: MatchCard(fixture: m, onTap: () => widget.onOpenMatch(m)),
            )),
      ],
    );
  }
}
