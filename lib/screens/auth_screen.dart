import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_theme.dart';
import '../widgets/matchpint_logo.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.savedUsers,
    required this.onRegister,
    required this.onLogin,
  });

  final List<AppUser> savedUsers;
  final ValueChanged<AppUser> onRegister;
  final ValueChanged<AppUser> onLogin;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _registerMode;
  final TextEditingController _nameController = TextEditingController(text: 'MatchPint Fan');
  final TextEditingController _emailController = TextEditingController(text: 'fan@matchpint.local');
  final TextEditingController _passwordController = TextEditingController(text: 'matchnight');
  String? _error;

  @override
  void initState() {
    super.initState();
    // Existing users should see a return-user flow first. A commercial app
    // should keep a valid session and only ask for credentials after sign-out.
    _registerMode = widget.savedUsers.isEmpty;
    if (widget.savedUsers.isNotEmpty) {
      final lastUser = widget.savedUsers.last;
      _nameController.text = lastUser.displayName;
      _emailController.text = lastUser.email;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim().toLowerCase();
    final name = _nameController.text.trim().isEmpty ? 'MatchPint Fan' : _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (!email.contains('@') || password.length < 6) {
      setState(() => _error = 'Use an email address and a password with at least 6 characters.');
      return;
    }

    final existing = widget.savedUsers.where((u) => u.email.toLowerCase() == email).toList();
    if (_registerMode) {
      if (existing.isNotEmpty) {
        setState(() => _error = 'This account already exists locally. Use sign in or switch account.');
        return;
      }
      final user = AppUser(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        email: email,
        displayName: name,
        createdAt: DateTime.now(),
      );
      widget.onRegister(user);
    } else {
      if (existing.isEmpty) {
        setState(() => _error = 'No local account found. Create one first for this prototype build.');
        return;
      }
      widget.onLogin(existing.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
          children: [
            const Center(child: MatchPintLogo(size: 112, showText: true)),
            const SizedBox(height: 34),
            Text(_registerMode ? 'Create your matchday account' : 'Welcome back', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              widget.savedUsers.isEmpty
                  ? 'Create a local prototype account once. MatchPint will keep you signed in on this device until you choose switch account.'
                  : 'You should only see this screen after signing out or switching account. Normal app launches now restore the active session automatically.',
              style: TextStyle(color: muted, height: 1.35),
            ),
            const SizedBox(height: 22),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Register'), icon: Icon(Icons.person_add_alt_1)),
                ButtonSegment(value: false, label: Text('Sign in'), icon: Icon(Icons.login)),
              ],
              selected: {_registerMode},
              onSelectionChanged: (selection) => setState(() {
                _registerMode = selection.first;
                _error = null;
              }),
            ),
            const SizedBox(height: 18),
            if (_registerMode) ...[
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined), labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), labelText: 'Password'),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              icon: Icon(_registerMode ? Icons.person_add_alt_1 : Icons.login),
              label: Text(_registerMode ? 'Create account' : 'Sign in'),
              onPressed: _submit,
            ),
            if (widget.savedUsers.isNotEmpty) ...[
              const SizedBox(height: 26),
              Text('Switch account', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              ...widget.savedUsers.reversed.map((user) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.16),
                          child: Text(user.displayName.isNotEmpty ? user.displayName.substring(0, 1).toUpperCase() : '?'),
                        ),
                        title: Text(user.displayName),
                        subtitle: Text(user.email, style: TextStyle(color: muted)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => widget.onLogin(user),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
