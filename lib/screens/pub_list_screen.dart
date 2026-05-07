import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/pub_card.dart';

class PubListScreen extends StatefulWidget {
  const PubListScreen({super.key, required this.preferences, required this.onOpenPub, this.fixture});
  final UserPreferences preferences;
  final ValueChanged<PubSpot> onOpenPub;
  final MatchFixture? fixture;

  @override
  State<PubListScreen> createState() => _PubListScreenState();
}

class _PubListScreenState extends State<PubListScreen> {
  bool _calmOnly = false;
  bool _soloOnly = false;
  bool _foodFirst = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final title = widget.fixture == null ? 'Find pubs' : 'Pubs for ${widget.fixture!.title}';
    final q = _query.trim().toLowerCase();
    final pubs = mockPubs.where((p) {
      if (_calmOnly && p.noiseDb > 65) return false;
      if (_soloOnly && !p.soloFriendly) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.area.toLowerCase().contains(q) || p.features.any((f) => f.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) {
        if (_foodFirst) return b.foodScore.compareTo(a.foodScore);
        return b.comfortScore(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly, wantsFood: widget.preferences.wantsFood || _foodFirst).compareTo(a.comfortScore(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly, wantsFood: widget.preferences.wantsFood || _foodFirst));
      });

    final prefs = widget.preferences.copyWith(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('${pubs.length} spots ranked by atmosphere fit, screen quality, comfort, and distance.', style: TextStyle(color: AppTheme.subtleText(context))),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search pub, area, or feature'),
          onChanged: (value) => setState(() => _query = value),
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
              child: Text('No pubs match your search yet.', style: TextStyle(color: AppTheme.subtleText(context))),
            ),
          )
        else
          ...pubs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PubCard(pub: p, preferences: prefs, onTap: () => widget.onOpenPub(p)),
              )),
      ],
    );
  }
}
