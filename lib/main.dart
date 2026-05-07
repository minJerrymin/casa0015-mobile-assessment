import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'models/app_user.dart';
import 'models/check_in.dart';
import 'models/match_fixture.dart';
import 'models/pub_spot.dart';
import 'models/user_preferences.dart';
import 'screens/auth_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/match_mode_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pub_detail_screen.dart';
import 'screens/pub_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/local_store.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MatchPintApp());
}

class MatchPintApp extends StatefulWidget {
  const MatchPintApp({super.key});

  @override
  State<MatchPintApp> createState() => _MatchPintAppState();
}

class _MatchPintAppState extends State<MatchPintApp> {
  final LocalStore _store = LocalStore();
  bool _showSplash = true;
  bool _loading = true;
  bool _onboarded = false;
  int _tabIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;
  UserPreferences _preferences = const UserPreferences();
  AppUser? _currentUser;
  List<AppUser> _users = [];
  final List<CheckIn> _checkIns = [];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final users = await _store.loadUsers();
    final user = await _store.loadCurrentUser();
    final onboarded = user == null ? false : await _store.isOnboarded(userId: user.id);
    final prefs = user == null ? const UserPreferences() : await _store.loadPreferences(userId: user.id);
    final themeMode = await _store.loadThemeMode();
    if (!mounted) return;
    setState(() {
      _users = users;
      _currentUser = user;
      _onboarded = onboarded;
      _preferences = prefs;
      _themeMode = themeMode;
      _loading = false;
    });
  }

  Future<void> _completeOnboarding(UserPreferences preferences) async {
    final userId = _currentUser?.id;
    await _store.savePreferences(preferences, userId: userId);
    await _store.setOnboarded(true, userId: userId);
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _onboarded = true;
    });
  }

  Future<void> _updatePreferences(UserPreferences preferences) async {
    await _store.savePreferences(preferences, userId: _currentUser?.id);
    if (!mounted) return;
    setState(() => _preferences = preferences);
  }

  Future<void> _registerUser(AppUser user) async {
    final users = [..._users, user];
    final prefs = const UserPreferences();
    await _store.saveUsers(users);
    await _store.setCurrentUser(user);
    await _store.savePreferences(prefs, userId: user.id);
    await _store.setOnboarded(false, userId: user.id);
    if (!mounted) return;
    setState(() {
      _users = users;
      _currentUser = user;
      _preferences = prefs;
      _onboarded = false;
      _tabIndex = 0;
    });
  }

  Future<void> _loginUser(AppUser user) async {
    final prefs = await _store.loadPreferences(userId: user.id);
    final onboarded = await _store.isOnboarded(userId: user.id);
    await _store.setCurrentUser(user);
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _preferences = prefs;
      _onboarded = onboarded;
      _tabIndex = 0;
    });
  }

  Future<void> _switchAccount() async {
    await _store.setCurrentUser(null);
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _onboarded = false;
      _tabIndex = 0;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await _store.saveThemeMode(mode);
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  Future<void> _resetProfile() async {
    await _store.setOnboarded(false, userId: _currentUser?.id);
    if (!mounted) return;
    setState(() => _onboarded = false);
  }

  void _openMatch(MatchFixture fixture) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(fixture.title)),
        body: PubListScreen(
          preferences: _preferences,
          fixture: fixture,
          onOpenPub: (pub) => _openPub(pub, fixture: fixture),
        ),
      ),
    ));
  }

  void _openPub(PubSpot pub, {MatchFixture? fixture}) {
    final selectedFixture = fixture ?? mockFixtures.first;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PubDetailScreen(
        pub: pub,
        preferences: _preferences,
        fixture: selectedFixture,
        onStartMatchMode: () => _openMatchMode(pub, selectedFixture),
      ),
    ));
  }

  void _openMatchMode(PubSpot pub, MatchFixture fixture) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MatchModeScreen(
        pub: pub,
        fixture: fixture,
        onSave: (entry) => setState(() => _checkIns.add(entry)),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatchPint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_showSplash || _loading) {
      return SplashScreen(onFinished: () => setState(() => _showSplash = false));
    }
    if (_currentUser == null) {
      return AuthScreen(
        savedUsers: _users,
        onRegister: _registerUser,
        onLogin: _loginUser,
      );
    }
    if (!_onboarded) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('MatchPint')),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(
            preferences: _preferences,
            onOpenMatch: _openMatch,
            onOpenPub: (pub) => _openPub(pub),
            onShowMatches: () => setState(() => _tabIndex = 1),
            onShowPubs: () => setState(() => _tabIndex = 2),
          ),
          MatchesScreen(onOpenMatch: _openMatch),
          PubListScreen(preferences: _preferences, onOpenPub: (pub) => _openPub(pub)),
          HistoryScreen(checkIns: _checkIns),
          SettingsScreen(
            user: _currentUser!,
            preferences: _preferences,
            onUpdatePreferences: _updatePreferences,
            themeMode: _themeMode,
            onSetThemeMode: _setThemeMode,
            onSwitchAccount: _switchAccount,
            onResetProfile: _resetProfile,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (index) => setState(() => _tabIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Matches'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_bar), label: 'Pubs'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: 'Nights'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
