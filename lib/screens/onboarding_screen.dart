import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
import '../data/team_data.dart';
import '../theme/app_theme.dart';
import '../widgets/matchpint_logo.dart';
import '../widgets/team_badge.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final ValueChanged<UserPreferences> onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _team = 'Arsenal';
  bool _prefersCalm = false;
  bool _soloMode = false;
  bool _wantsFood = true;

  Future<void> _pickTeam() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final height = MediaQuery.of(context).size.height * 0.72;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Text(
                    'Choose your favourite team',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: premierLeagueTeams.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final team = premierLeagueTeams[index];
                      final selected = team == _team;
                      return ListTile(
                        leading: TeamBadge(team: team, size: 32),
                        title: Text(team, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: selected ? const Icon(Icons.check_circle) : null,
                        onTap: () => Navigator.of(context).pop(team),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && selected != _team && mounted) {
      setState(() => _team = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 10),
            const Center(child: MatchPintLogo(size: 96, showText: false)),
            const SizedBox(height: 32),
            Text('Build your match night profile', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text('MatchPint recommends football pubs by match, location, noise, crowd level, comfort, and viewing quality. You can edit this later in Settings.', style: TextStyle(color: muted, height: 1.4)),
            const SizedBox(height: 28),
            const Text('Favourite team', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _pickTeam,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    TeamBadge(team: _team, size: 34),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_team, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text('Tap to change', style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prefer calmer pubs'),
              subtitle: Text('Prioritise lower noise and less crowding', style: TextStyle(color: muted)),
              value: _prefersCalm,
              onChanged: (value) => setState(() => _prefersCalm = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('I may watch solo'),
              subtitle: Text('Highlight places that feel comfortable alone', style: TextStyle(color: muted)),
              value: _soloMode,
              onChanged: (value) => setState(() => _soloMode = value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Food matters'),
              subtitle: Text('Include food quality in the recommendation', style: TextStyle(color: muted)),
              value: _wantsFood,
              onChanged: (value) => setState(() => _wantsFood = value),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.sports_bar),
                label: const Text('Start finding pubs'),
                onPressed: () => widget.onComplete(UserPreferences(
                  team: _team,
                  prefersCalm: _prefersCalm,
                  soloMode: _soloMode,
                  wantsFood: _wantsFood,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
