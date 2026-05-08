import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
import '../data/team_data.dart';
import '../theme/app_theme.dart';
import '../widgets/matchpint_logo.dart';

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
            DropdownButtonFormField<String>(
              value: premierLeagueTeams.contains(_team) ? _team : premierLeagueTeams.first,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.shield),
                labelText: 'Select a Premier League club',
              ),
              items: premierLeagueTeams
                  .map((team) => DropdownMenuItem<String>(
                        value: team,
                        child: Text(team, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (team) => setState(() => _team = team ?? _team),
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
