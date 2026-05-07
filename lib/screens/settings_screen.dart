import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.user,
    required this.preferences,
    required this.onUpdatePreferences,
    required this.themeMode,
    required this.onSetThemeMode,
    required this.onSwitchAccount,
    required this.onResetProfile,
  });

  final AppUser user;
  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onUpdatePreferences;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onSetThemeMode;
  final VoidCallback onSwitchAccount;
  final VoidCallback onResetProfile;

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final teams = ['Arsenal', 'Chelsea', 'Tottenham', 'West Ham', 'Liverpool', 'England Women'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Account, match profile, appearance, and data controls.', style: TextStyle(color: muted)),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.18),
                      child: Text(user.displayName.isNotEmpty ? user.displayName.substring(0, 1).toUpperCase() : '?'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                          const SizedBox(height: 3),
                          Text(user.email, style: TextStyle(color: muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.switch_account),
                    label: const Text('Switch or sign in as another account'),
                    onPressed: onSwitchAccount,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Match night profile', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Favourite team', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: teams.map((team) {
                    return ChoiceChip(
                      label: Text(team),
                      selected: preferences.team == team,
                      onSelected: (_) => onUpdatePreferences(preferences.copyWith(team: team)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prefer calmer pubs'),
                  subtitle: Text('Lower noise and less crowding rank higher', style: TextStyle(color: muted)),
                  value: preferences.prefersCalm,
                  onChanged: (v) => onUpdatePreferences(preferences.copyWith(prefersCalm: v)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Solo watching mode'),
                  subtitle: Text('Prioritise places that feel comfortable alone', style: TextStyle(color: muted)),
                  value: preferences.soloMode,
                  onChanged: (v) => onUpdatePreferences(preferences.copyWith(soloMode: v)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Food matters'),
                  subtitle: Text('Use food quality in the fit score', style: TextStyle(color: muted)),
                  value: preferences.wantsFood,
                  onChanged: (v) => onUpdatePreferences(preferences.copyWith(wantsFood: v)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Show onboarding profile again'),
                    onPressed: onResetProfile,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Appearance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Follow system by default, or override it for testing.', style: TextStyle(color: muted)),
                const SizedBox(height: 14),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.phone_android)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) => onSetThemeMode(selection.first),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _InfoTile(icon: Icons.location_on, title: 'Location', body: 'GPS ranking is next. V0.2 keeps Central London mock data so the user journey remains stable.'),
        _InfoTile(icon: Icons.mic, title: 'Microphone', body: 'The current match mode records a simulated dB sample only. The Android microphone permission and live amplitude sampler are planned for V0.3.'),
        _InfoTile(icon: Icons.cloud, title: 'External services', body: 'Planned services: football fixture API, places/OSM data, weather API, and Firebase for production authentication.'),
        _InfoTile(icon: Icons.privacy_tip, title: 'Privacy principle', body: 'Store only what improves the matchday experience: account, preferences, pub, match, fit score, dB estimate, mood, and notes.'),
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
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(body, style: TextStyle(color: AppTheme.subtleText(context), height: 1.35)),
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
