import 'package:flutter/material.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.preferences, required this.onUpdate});

  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onUpdate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Control the recommendation logic and review the data that MatchPint plans to use.', style: TextStyle(color: AppTheme.muted)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Prefer calmer pubs'),
                  subtitle: const Text('Lower noise and less crowding rank higher', style: TextStyle(color: AppTheme.muted)),
                  value: preferences.prefersCalm,
                  onChanged: (v) => onUpdate(preferences.copyWith(prefersCalm: v)),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Solo watching mode'),
                  subtitle: const Text('Prioritise places that feel comfortable alone', style: TextStyle(color: AppTheme.muted)),
                  value: preferences.soloMode,
                  onChanged: (v) => onUpdate(preferences.copyWith(soloMode: v)),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Food matters'),
                  subtitle: const Text('Use food quality in the fit score', style: TextStyle(color: AppTheme.muted)),
                  value: preferences.wantsFood,
                  onChanged: (v) => onUpdate(preferences.copyWith(wantsFood: v)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _InfoTile(icon: Icons.location_on, title: 'Location', body: 'V0.2 will use GPS to rank pubs by distance. V0.1 uses mock Central London data.'),
        _InfoTile(icon: Icons.mic, title: 'Microphone', body: 'V0.2 will measure live volume level only. It will not store raw audio.'),
        _InfoTile(icon: Icons.cloud, title: 'External services', body: 'Planned services: football fixture API, places/OSM data, weather API, and Firebase for saved nights.'),
        _InfoTile(icon: Icons.privacy_tip, title: 'Privacy principle', body: 'Store only what improves the matchday experience: pub, match, fit score, dB estimate, mood, and notes.'),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.pitchGreen),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(body, style: const TextStyle(color: AppTheme.muted, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
