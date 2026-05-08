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
import 'services/live_data_service.dart';
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
  final MatchPintLiveDataService _liveData = MatchPintLiveDataService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _showSplash = true;
  bool _loading = true;
  bool _loadingLiveData = false;
  bool _onboarded = false;
  int _tabIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;
  UserPreferences _preferences = const UserPreferences();
  AppUser? _currentUser;
  List<AppUser> _users = [];
  List<CheckIn> _checkIns = [];
  List<MatchFixture> _fixtures = mockFixtures;
  List<PubSpot> _pubs = mockPubs;
  String _liveDataMessage = 'Prototype data is ready. Live fixtures and OSM pubs will load automatically when network access is available.';

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _liveData.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final users = await _store.loadUsers();
    final user = await _store.loadCurrentUser();
    final onboarded = user == null ? false : await _store.isOnboarded(userId: user.id);
    final prefs = user == null ? const UserPreferences() : await _store.loadPreferences(userId: user.id);
    final themeMode = await _store.loadThemeMode();
    final checkIns = user == null ? <CheckIn>[] : await _store.loadCheckIns(userId: user.id);
    if (!mounted) return;
    setState(() {
      _users = users;
      _currentUser = user;
      _onboarded = onboarded;
      _preferences = prefs;
      _themeMode = themeMode;
      _checkIns = checkIns;
      _loading = false;
    });
    _refreshLiveData();
  }

  Future<void> _refreshLiveData({double? latitude, double? longitude}) async {
    if (_loadingLiveData) return;
    if (mounted) {
      setState(() {
        _loadingLiveData = true;
        _liveDataMessage = 'Loading live fixtures and nearby pubs...';
      });
    }

    final fixtureResult = await _liveData.fetchFootballFixtures();
    final lat = latitude ?? MatchPintLiveDataService.defaultLatitude;
    final lng = longitude ?? MatchPintLiveDataService.defaultLongitude;
    final pubResult = await _liveData.fetchNearbyPubs(
      latitude: lat,
      longitude: lng,
      fixtures: fixtureResult.fixtures,
    );

    if (!mounted) return;
    setState(() {
      _fixtures = fixtureResult.fixtures;
      _pubs = pubResult.pubs;
      _loadingLiveData = false;
      _liveDataMessage = '${fixtureResult.message} ${pubResult.message}';
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
      _checkIns = [];
      _tabIndex = 0;
    });
  }

  Future<void> _loginUser(AppUser user) async {
    final prefs = await _store.loadPreferences(userId: user.id);
    final onboarded = await _store.isOnboarded(userId: user.id);
    final checkIns = await _store.loadCheckIns(userId: user.id);
    await _store.setCurrentUser(user);
    if (!mounted) return;
    setState(() {
      _currentUser = user;
      _preferences = prefs;
      _onboarded = onboarded;
      _checkIns = checkIns;
      _tabIndex = 0;
    });
  }

  Future<void> _updateCurrentUser(AppUser updated) async {
    final users = _users.map((user) => user.id == updated.id ? updated : user).toList();
    await _store.saveUsers(users);
    await _store.setCurrentUser(updated);
    if (!mounted) return;
    setState(() {
      _users = users;
      _currentUser = updated;
    });
  }

  Future<bool> _changeEmail(String currentPassword, String newEmail) async {
    final user = _currentUser;
    if (user == null) return false;
    final cleanEmail = newEmail.trim().toLowerCase();
    if (!user.matchesPassword(currentPassword) || !cleanEmail.contains('@')) return false;
    final emailTaken = _users.any((u) => u.id != user.id && u.email.toLowerCase() == cleanEmail);
    if (emailTaken) return false;
    await _updateCurrentUser(user.copyWith(email: cleanEmail));
    return true;
  }

  Future<bool> _changePassword(String currentPassword, String newPassword) async {
    final user = _currentUser;
    if (user == null) return false;
    if (!user.matchesPassword(currentPassword) || newPassword.trim().length < 8) return false;
    await _updateCurrentUser(user.copyWith(passwordHash: AppUser.hashPassword(newPassword)));
    return true;
  }

  Future<bool> _deleteAccount(String currentPassword) async {
    final user = _currentUser;
    if (user == null || !user.matchesPassword(currentPassword)) return false;
    final users = _users.where((u) => u.id != user.id).toList();
    await _store.saveUsers(users);
    await _store.deleteUserData(user.id);
    await _store.setCurrentUser(null);
    if (!mounted) return true;
    setState(() {
      _users = users;
      _currentUser = null;
      _onboarded = false;
      _checkIns = [];
      _tabIndex = 0;
    });
    return true;
  }

  Future<void> _signOut() async {
    await _store.setCurrentUser(null);
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _onboarded = false;
      _checkIns = [];
      _tabIndex = 0;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    await _store.saveThemeMode(mode);
    if (!mounted) return;
    setState(() => _themeMode = mode);
  }

  Future<void> _saveCheckIn(CheckIn entry) async {
    final updated = [..._checkIns, entry];
    await _store.saveCheckIns(updated, userId: _currentUser?.id);
    if (!mounted) return;
    setState(() => _checkIns = updated);
  }

  NavigatorState? get _nav => _navigatorKey.currentState;

  void _openMatch(MatchFixture fixture) {
    _nav?.push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(fixture.title)),
        body: PubListScreen(
          preferences: _preferences,
          fixture: fixture,
          pubs: _pubs,
          fixtures: _fixtures,
          liveDataMessage: _liveDataMessage,
          onOpenPub: (pub) => _openPub(pub, fixture: fixture),
        ),
      ),
    ));
  }

  void _openPub(PubSpot pub, {MatchFixture? fixture}) {
    final selectedFixture = fixture ?? bestFixtureForPub(pub, preferences: _preferences, fixtures: _fixtures);
    _nav?.push(MaterialPageRoute(
      builder: (_) => PubDetailScreen(
        pub: pub,
        preferences: _preferences,
        fixture: selectedFixture,
        onStartMatchMode: () => _openMatchMode(pub, selectedFixture),
      ),
    ));
  }

  void _openMatchMode(PubSpot pub, MatchFixture fixture) {
    _nav?.push(MaterialPageRoute(
      builder: (_) => MatchModeScreen(
        pub: pub,
        fixture: fixture,
        onSave: _saveCheckIn,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
            fixtures: _fixtures,
            pubs: _pubs,
            liveDataMessage: _liveDataMessage,
            loadingLiveData: _loadingLiveData,
            onRefreshLiveData: _refreshLiveData,
            onOpenMatch: _openMatch,
            onOpenPub: (pub) => _openPub(pub),
            onShowMatches: () => setState(() => _tabIndex = 1),
            onShowPubs: () => setState(() => _tabIndex = 2),
          ),
          MatchesScreen(fixtures: _fixtures, liveDataMessage: _liveDataMessage, loadingLiveData: _loadingLiveData, onOpenMatch: _openMatch),
          PubListScreen(
            preferences: _preferences,
            pubs: _pubs,
            fixtures: _fixtures,
            liveDataMessage: _liveDataMessage,
            onOpenPub: (pub) => _openPub(pub),
          ),
          HistoryScreen(checkIns: _checkIns),
          SettingsScreen(
            user: _currentUser!,
            preferences: _preferences,
            onUpdatePreferences: _updatePreferences,
            themeMode: _themeMode,
            onSetThemeMode: _setThemeMode,
            onUpdateUser: _updateCurrentUser,
            onChangeEmail: _changeEmail,
            onChangePassword: _changePassword,
            onDeleteAccount: _deleteAccount,
            onSignOut: _signOut,
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
