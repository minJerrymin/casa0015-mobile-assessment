import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/matchpint_logo.dart';

typedef RegisterCallback = Future<String?> Function({
  required String email,
  required String password,
  required String displayName,
});

typedef LoginCallback = Future<String?> Function({
  required String email,
  required String password,
});

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.firebaseAuthAvailable,
    required this.onRegister,
    required this.onLogin,
    this.firebaseSetupMessage,
    this.onResetPassword,
  });

  final bool firebaseAuthAvailable;
  final String? firebaseSetupMessage;
  final RegisterCallback onRegister;
  final LoginCallback onLogin;
  final Future<String> Function(String email)? onResetPassword;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _registerMode = false;
  bool _submitting = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _notice;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final displayName = _nameController.text.trim().isEmpty ? 'MatchPint Fan' : _nameController.text.trim();
    final password = _passwordController.text.trim();

    if (!email.contains('@') || email.length < 5) {
      setState(() {
        _error = 'Enter a valid email address.';
        _notice = null;
      });
      return;
    }
    if (password.length < 8) {
      setState(() {
        _error = 'Use at least 8 characters for your password.';
        _notice = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _notice = null;
    });

    final message = _registerMode
        ? await widget.onRegister(email: email, password: password, displayName: displayName)
        : await widget.onLogin(email: email, password: password);

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (message != null && message.toLowerCase().contains('sent')) {
        _notice = message;
      } else {
        _error = message;
      }
    });
  }

  Future<void> _resetPassword() async {
    final reset = widget.onResetPassword;
    final email = _emailController.text.trim().toLowerCase();
    if (reset == null) return;
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email first, then tap reset password.');
      return;
    }
    final message = await reset(email);
    if (!mounted) return;
    setState(() {
      _notice = message;
      _error = null;
    });
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
                  : 'Sign in to restore your match profile, saved nights, and account settings.',
              style: TextStyle(color: muted, height: 1.35),
            ),
            const SizedBox(height: 22),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Register'), icon: Icon(Icons.person_add_alt_1)),
                ButtonSegment(value: false, label: Text('Sign in'), icon: Icon(Icons.login)),
              ],
              selected: {_registerMode},
              onSelectionChanged: _submitting
                  ? null
                  : (selection) => setState(() {
                        _registerMode = selection.first;
                        _error = null;
                        _notice = null;
                      }),
            ),
            const SizedBox(height: 18),
            if (_registerMode) ...[
              TextField(
                controller: _nameController,
                enabled: !_submitting,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.badge_outlined), labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailController,
              enabled: !_submitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              enabled: !_submitting,
              obscureText: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.lock_outline), labelText: 'Password'),
              onSubmitted: (_) => _submit(),
            ),
            if (!_registerMode && widget.onResetPassword != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _submitting ? null : _resetPassword, child: const Text('Reset password')),
              ),
            ],
            if (_notice != null) ...[
              const SizedBox(height: 10),
              Text(_notice!, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_registerMode ? Icons.person_add_alt_1 : Icons.login),
              label: Text(_submitting ? 'Please wait...' : (_registerMode ? 'Create account' : 'Sign in')),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
