import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/user_preferences.dart';
import '../data/team_data.dart';
import '../theme/app_theme.dart';
import '../widgets/team_badge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.user,
    required this.preferences,
    required this.onUpdatePreferences,
    required this.themeMode,
    required this.onSetThemeMode,
    required this.onUpdateUser,
    required this.onChangeEmail,
    required this.onChangePassword,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  final AppUser user;
  final UserPreferences preferences;
  final ValueChanged<UserPreferences> onUpdatePreferences;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onSetThemeMode;
  final Future<void> Function(AppUser updated) onUpdateUser;
  final Future<bool> Function(String currentPassword, String newEmail) onChangeEmail;
  final Future<bool> Function(String currentPassword, String newPassword) onChangePassword;
  final Future<bool> Function(String currentPassword) onDeleteAccount;
  final VoidCallback onSignOut;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _emailPasswordController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  late final TextEditingController _deletePasswordController;
  late final TextEditingController _deleteConfirmController;

  String? _notice;
  bool _showEmailEditor = false;
  bool _showPasswordEditor = false;
  bool _showDeleteEditor = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _emailPasswordController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _deletePasswordController = TextEditingController();
    _deleteConfirmController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _nameController.text = widget.user.displayName;
      _emailController.text = widget.user.email;
      _clearSensitiveFields();
    } else {
      if (oldWidget.user.displayName != widget.user.displayName && _nameController.text != widget.user.displayName) {
        _nameController.text = widget.user.displayName;
      }
      if (oldWidget.user.email != widget.user.email && _emailController.text != widget.user.email) {
        _emailController.text = widget.user.email;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _emailPasswordController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    _deleteConfirmController.dispose();
    super.dispose();
  }

  void _setNotice(String message) {
    if (!mounted) return;
    setState(() => _notice = message);
  }

  void _clearSensitiveFields() {
    _emailPasswordController.clear();
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    _deletePasswordController.clear();
    _deleteConfirmController.clear();
  }

  Future<void> _saveDisplayName() async {
    final nextName = _nameController.text.trim();
    if (nextName.isEmpty) {
      _setNotice('Display name cannot be empty.');
      return;
    }
    await widget.onUpdateUser(widget.user.copyWith(displayName: nextName));
    _setNotice('Display name updated.');
  }

  Future<void> _saveEmail() async {
    final nextEmail = _emailController.text.trim().toLowerCase();
    if (!nextEmail.contains('@')) {
      _setNotice('Enter a valid email address.');
      return;
    }
    final ok = await widget.onChangeEmail(_emailPasswordController.text, nextEmail);
    if (!mounted) return;
    if (ok) {
      _emailPasswordController.clear();
      setState(() {
        _showEmailEditor = false;
        _notice = widget.user.usesFirebase ? 'Verification sent to the new email. Confirm it to finish the change.' : 'Email updated.';
      });
    } else {
      _setNotice('Email update failed. Check your password or use a different email.');
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPasswordController.text;
    final next = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();
    if (next.length < 8) {
      _setNotice('New password must be at least 8 characters.');
      return;
    }
    if (next != confirm) {
      _setNotice('New passwords do not match.');
      return;
    }
    final ok = await widget.onChangePassword(current, next);
    if (!mounted) return;
    if (ok) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _showPasswordEditor = false;
        _notice = 'Password updated.';
      });
    } else {
      _setNotice('Password update failed. Check your current password.');
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_deleteConfirmController.text.trim() != 'DELETE') {
      _setNotice('Type DELETE exactly to confirm account deletion.');
      return;
    }
    final ok = await widget.onDeleteAccount(_deletePasswordController.text);
    if (!mounted) return;
    if (!ok) {
      _setNotice('Account deletion failed. Check your password.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Account, match profile, appearance, and data controls.', style: TextStyle(color: muted)),
        if (_notice != null) ...[
          const SizedBox(height: 14),
          _NoticeBanner(message: _notice!, onDismiss: () => setState(() => _notice = null)),
        ],
        const SizedBox(height: 20),
        _AccountCard(
          user: widget.user,
          muted: muted,
          nameController: _nameController,
          emailController: _emailController,
          emailPasswordController: _emailPasswordController,
          currentPasswordController: _currentPasswordController,
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          deletePasswordController: _deletePasswordController,
          deleteConfirmController: _deleteConfirmController,
          showEmailEditor: _showEmailEditor,
          showPasswordEditor: _showPasswordEditor,
          showDeleteEditor: _showDeleteEditor,
          onSaveName: _saveDisplayName,
          onToggleEmail: () => setState(() => _showEmailEditor = !_showEmailEditor),
          onTogglePassword: () => setState(() => _showPasswordEditor = !_showPasswordEditor),
          onToggleDelete: () => setState(() => _showDeleteEditor = !_showDeleteEditor),
          onSaveEmail: _saveEmail,
          onSavePassword: _savePassword,
          onDeleteAccount: _confirmDeleteAccount,
          onSignOut: widget.onSignOut,
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
                _TeamSelector(
                  selectedTeam: premierLeagueTeams.contains(widget.preferences.team) ? widget.preferences.team : premierLeagueTeams.first,
                  onSelected: (team) => widget.onUpdatePreferences(widget.preferences.copyWith(team: team)),
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Prefer calmer pubs'),
                  subtitle: Text('Lower noise and less crowding rank higher', style: TextStyle(color: muted)),
                  value: widget.preferences.prefersCalm,
                  onChanged: (v) => widget.onUpdatePreferences(widget.preferences.copyWith(prefersCalm: v)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Solo watching mode'),
                  subtitle: Text('Prioritise places that feel comfortable alone', style: TextStyle(color: muted)),
                  value: widget.preferences.soloMode,
                  onChanged: (v) => widget.onUpdatePreferences(widget.preferences.copyWith(soloMode: v)),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Food matters'),
                  subtitle: Text('Use food quality in the fit score', style: TextStyle(color: muted)),
                  value: widget.preferences.wantsFood,
                  onChanged: (v) => widget.onUpdatePreferences(widget.preferences.copyWith(wantsFood: v)),
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
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ThemeChip(label: 'System', icon: Icons.phone_android, value: ThemeMode.system, groupValue: widget.themeMode, onSelected: widget.onSetThemeMode),
                    _ThemeChip(label: 'Light', icon: Icons.light_mode, value: ThemeMode.light, groupValue: widget.themeMode, onSelected: widget.onSetThemeMode),
                    _ThemeChip(label: 'Dark', icon: Icons.dark_mode, value: ThemeMode.dark, groupValue: widget.themeMode, onSelected: widget.onSetThemeMode),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const _InfoTile(icon: Icons.sports_soccer, title: 'Fixture-to-pub matching', body: 'This prototype filters pubs by team-support and venue metadata. The production version will combine fixtures, venue data, user check-ins, and explicit pub submissions.'),
        const _InfoTile(icon: Icons.location_on, title: 'Location', body: 'Pub lists now include an optional Use my location action. With permission, distances and ranking are recalculated from the phone GPS.'),
        const _InfoTile(icon: Icons.mic, title: 'Microphone', body: 'Match mode now asks for microphone permission and samples amplitude for a live dB estimate. It stores only the number, not audio.'),
        const _InfoTile(icon: Icons.cloud_done, title: 'Firebase services', body: 'MatchPint now uses Firebase Cloud Functions for fixtures and Firebase Authentication for production-style account management.'),
        const _InfoTile(icon: Icons.privacy_tip, title: 'Privacy principle', body: 'Store only what improves the matchday experience: account, preferences, pub, match, fit score, dB estimate, selected tags, and notes.'),
      ],
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.20)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          IconButton(onPressed: onDismiss, icon: const Icon(Icons.close), tooltip: 'Dismiss'),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.user,
    required this.muted,
    required this.nameController,
    required this.emailController,
    required this.emailPasswordController,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.deletePasswordController,
    required this.deleteConfirmController,
    required this.showEmailEditor,
    required this.showPasswordEditor,
    required this.showDeleteEditor,
    required this.onSaveName,
    required this.onToggleEmail,
    required this.onTogglePassword,
    required this.onToggleDelete,
    required this.onSaveEmail,
    required this.onSavePassword,
    required this.onDeleteAccount,
    required this.onSignOut,
  });

  final AppUser user;
  final Color muted;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController emailPasswordController;
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController deletePasswordController;
  final TextEditingController deleteConfirmController;
  final bool showEmailEditor;
  final bool showPasswordEditor;
  final bool showDeleteEditor;
  final VoidCallback onSaveName;
  final VoidCallback onToggleEmail;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleDelete;
  final VoidCallback onSaveEmail;
  final VoidCallback onSavePassword;
  final VoidCallback onDeleteAccount;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Card(
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
            const SizedBox(height: 18),
            TextField(
              controller: nameController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Display name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onSubmitted: (_) => onSaveName(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onSaveName,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save display name'),
              ),
            ),
            const Divider(height: 32),
            _InlineActionHeader(icon: Icons.email_outlined, title: 'Email address', actionLabel: showEmailEditor ? 'Cancel' : 'Change', onPressed: onToggleEmail),
            if (showEmailEditor) ...[
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'New email', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: onSaveEmail, child: const Text('Update email'))),
            ],
            const Divider(height: 32),
            _InlineActionHeader(icon: Icons.lock_outline, title: 'Password', actionLabel: showPasswordEditor ? 'Cancel' : 'Change', onPressed: onTogglePassword),
            if (showPasswordEditor) ...[
              const SizedBox(height: 12),
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password', prefixIcon: Icon(Icons.password_outlined)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password', prefixIcon: Icon(Icons.password_outlined)),
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: onSavePassword, child: const Text('Update password'))),
            ],
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.logout), label: const Text('Sign out'), onPressed: onSignOut)),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.tonalIcon(icon: const Icon(Icons.delete_outline), label: const Text('Delete'), onPressed: onToggleDelete)),
              ],
            ),
            if (showDeleteEditor) ...[
              const SizedBox(height: 14),
              Text(user.usesFirebase ? 'Delete Firebase account' : 'Delete account', style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.error)),
              const SizedBox(height: 6),
              Text(user.usesFirebase ? 'This deletes your Firebase account and removes local MatchPint data from this device.' : 'This removes the local account, preferences, and saved match nights from this device.', style: TextStyle(color: muted)),
              const SizedBox(height: 12),
              TextField(
                controller: deletePasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password', prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: deleteConfirmController,
                decoration: const InputDecoration(labelText: 'Type DELETE to confirm', prefixIcon: Icon(Icons.warning_amber_outlined)),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                  onPressed: onDeleteAccount,
                  child: const Text('Permanently delete account'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineActionHeader extends StatelessWidget {
  const _InlineActionHeader({required this.icon, required this.title, required this.actionLabel, required this.onPressed});
  final IconData icon;
  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900))),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _TeamSelector extends StatelessWidget {
  const _TeamSelector({required this.selectedTeam, required this.onSelected});

  final String selectedTeam;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.45),
      borderRadius: BorderRadius.circular(18),
      child: PopupMenuButton<String>(
        initialValue: selectedTeam,
        onSelected: onSelected,
        itemBuilder: (context) => premierLeagueTeams
            .map(
              (team) => PopupMenuItem<String>(
                value: team,
                child: Row(
                  children: [
                    TeamBadge(team: team, size: 24),
                    const SizedBox(width: 10),
                    Expanded(child: Text(team, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            )
            .toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              TeamBadge(team: selectedTeam, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedTeam,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.label, required this.icon, required this.value, required this.groupValue, required this.onSelected});
  final String label;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      selected: value == groupValue,
      onSelected: (_) => onSelected(value),
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
