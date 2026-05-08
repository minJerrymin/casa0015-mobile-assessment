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
    _registerMode = widget.savedUsers.isEmpty;
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

    if (!email.contains('@') || email.length < 5) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Use at least 8 characters for your password.');
      return;
    }

    final existing = widget.savedUsers.where((u) => u.email.toLowerCase() == email).toList();
    if (_registerMode) {
      if (existing.isNotEmpty) {
        setState(() => _error = 'This account already exists. Sign in instead.');
        return;
      }
      final user = AppUser(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        email: email,
        displayName: name,
        createdAt: DateTime.now(),
        passwordHash: AppUser.hashPassword(password),
      );
      widget.onRegister(user);
    } else {
      if (existing.isEmpty) {
        setState(() => _error = 'No account found for this email on this prototype build.');
        return;
      }
      final user = existing.first;
      if (!user.matchesPassword(password)) {
        setState(() => _error = 'Incorrect password.');
        return;
      }
      widget.onLogin(user);
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
            Text(_registerMode ? 'Create your matchday account' : 'Sign in to MatchPint', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              _registerMode
                  ? 'Create one account for your match nights, pub preferences, and saved experiences.'
                  : 'Normal launches restore your active session. You only see this after signing out, deleting an account, or clearing app data.',
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
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Prototype security note: this build stores a local password hash only to test account UX. Production should use Firebase Authentication, email verification, password reset, and secure tokens.',
                  style: TextStyle(color: muted, height: 1.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
