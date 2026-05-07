import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
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
    final teams = ['Arsenal', 'Chelsea', 'Tottenham', 'West Ham', 'Liverpool', 'England Women'];
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(child: MatchPintLogo(size: 82, showText: false)),
                    const SizedBox(height: 24),
                    Text(
                      'Build your match night profile',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'MatchPint recommends football pubs by match, location, noise, crowd level, comfort, and viewing quality.',
                      style: TextStyle(color: AppTheme.muted, height: 1.35),
                    ),
                    const SizedBox(height: 24),
                    const Text('Favourite team', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: teams.map((team) {
                        return ChoiceChip(
                          label: Text(team),
                          selected: _team == team,
                          onSelected: (_) => setState(() => _team = team),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _PreferenceSwitch(
                      title: 'Prefer calmer pubs',
                      subtitle: 'Prioritise lower noise and less crowding',
                      value: _prefersCalm,
                      onChanged: (value) => setState(() => _prefersCalm = value),
                    ),
                    _PreferenceSwitch(
                      title: 'I may watch solo',
                      subtitle: 'Highlight places that feel comfortable alone',
                      value: _soloMode,
                      onChanged: (value) => setState(() => _soloMode = value),
                    ),
                    _PreferenceSwitch(
                      title: 'Food matters',
                      subtitle: 'Include food quality in the recommendation',
                      value: _wantsFood,
                      onChanged: (value) => setState(() => _wantsFood = value),
                    ),
                    const SizedBox(height: 20),
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
          },
        ),
      ),
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.muted)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
