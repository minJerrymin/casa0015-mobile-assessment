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
import 'services/firebase_auth_service.dart';
import 'services/live_data_service.dart';
import 'services/local_store.dart';
import 'services/location_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final authService = MatchPintAuthService();
  await authService.initialise();
  runApp(MatchPintApp(authService: authService));
}

class MatchPintApp extends StatefulWidget {
  const MatchPintApp({super.key, required this.authService});

  final MatchPintAuthService authService;

  @override
  State<MatchPintApp> createState() => _MatchPintAppState();
}

class _MatchPintAppState extends State<MatchPintApp> {
  final LocalStore _store = LocalStore();
  final MatchPintLiveDataService _liveData = MatchPintLiveDataService();
  final LocationService _locationService = LocationService();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool _showSplash = true;
  bool _loading = true;
  bool _loadingLiveData = false;
  bool _gettingLocation = false;
  bool _locationExplainerShown = false;
  bool _onboarded = false;
  int _tabIndex = 0;
  ThemeMode _themeMode = ThemeMode.system;
  UserPreferences _preferences = const UserPreferences();
  AppUser? _currentUser;
  List<AppUser> _users = [];
  List<CheckIn> _checkIns = [];
  List<MatchFixture> _fixtures = mockFixtures;
  List<PubSpot> _pubs = mockPubs;
  double? _userLatitude;
  double? _userLongitude;
  String _locationMessage = 'Location not shared yet. MatchPint can use it to rank nearby pubs when you allow it.';
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
    var users = await _store.loadUsers();
    var user = await widget.authService.restoreUser() ?? await _store.loadCurrentUser();
    if (user != null) {
      users = _mergeUser(users, user);
      await _store.saveUsers(users);
      await _store.setCurrentUser(user);
    }
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
    if (user != null && onboarded) {
      _scheduleLocationExplainer();
    }
  }

  List<AppUser> _mergeUser(List<AppUser> users, AppUser user) {
    var found = false;
    final merged = users.map((existing) {
      if (existing.id == user.id) {
        found = true;
        return user;
      }
      return existing;
    }).toList();
    if (!found) merged.add(user);
    return merged;
  }

  Future<void> _refreshLiveData({double? latitude, double? longitude}) async {
    if (_loadingLiveData) return;
    if (mounted) {
      setState(() {
        _loadingLiveData = true;
        // Keep existing screen content visible. Fresh data will replace it as soon as each source returns.
        _liveDataMessage = _fixtures.isEmpty
            ? 'Loading latest fixtures and nearby pubs...'
            : 'Showing current data while MatchPint refreshes in the background...';
      });
    }

    try {
      final fixtureResult = await _liveData.fetchFootballFixtures();
      if (!mounted) return;
      final nextFixtures = fixtureResult.fixtures.isEmpty ? _fixtures : fixtureResult.fixtures;
      setState(() {
        _fixtures = nextFixtures;
        _liveDataMessage = fixtureResult.message;
      });

      final lat = latitude ?? _userLatitude ?? MatchPintLiveDataService.defaultLatitude;
      final lng = longitude ?? _userLongitude ?? MatchPintLiveDataService.defaultLongitude;
      final pubResult = await _liveData.fetchNearbyPubs(
        latitude: lat,
        longitude: lng,
        fixtures: nextFixtures,
      );

      if (!mounted) return;
      setState(() {
        _pubs = pubResult.pubs.isEmpty ? _pubs : pubResult.pubs;
        _loadingLiveData = false;
        _liveDataMessage = '${fixtureResult.message} ${pubResult.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLiveData = false;
        _liveDataMessage = 'Showing latest available fixtures and pubs. MatchPint will retry live refresh shortly.';
      });
    }
  }



  void _scheduleLocationExplainer() {
    if (_locationExplainerShown || _gettingLocation) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _offerLocationAndRefresh();
      });
    });
  }

  Future<void> _offerLocationAndRefresh() async {
    if (_locationExplainerShown || _gettingLocation) return;
    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      _scheduleLocationExplainer();
      return;
    }
    _locationExplainerShown = true;
    final allow = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Use your location?'),
        content: const Text(
          'MatchPint can use your location to find nearby pubs and rank them by real distance. You can continue without sharing location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow location'),
          ),
        ],
      ),
    );
    if (allow == true) {
      await _requestLocationAndRefresh();
    } else if (mounted) {
      setState(() {
        _locationMessage = 'Location not shared. Using Central London as the default search area.';
      });
    }
  }

  Future<void> _requestLocationAndRefresh() async {
    if (_gettingLocation) return;
    if (mounted) {
      setState(() {
        _gettingLocation = true;
        _locationMessage = 'Requesting location permission so MatchPint can rank pubs near you.';
      });
    }
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    if (result.success && result.latitude != null && result.longitude != null) {
      setState(() {
        _userLatitude = result.latitude;
        _userLongitude = result.longitude;
        _gettingLocation = false;
        _locationMessage = result.message;
      });
      await _refreshLiveData(latitude: result.latitude, longitude: result.longitude);
    } else {
      setState(() {
        _gettingLocation = false;
        _locationMessage = result.message;
      });
    }
  }

  Future<void> _completeOnboarding(UserPreferences preferences) async {
    final userId = _currentUser?.id;
    await _store.savePreferences(preferences, userId: userId);
    await _store.setOnboarded(true, userId: userId);
    if (!mounted) return;
    setState(() {
      _preferences = preferences;
      _onboarded = true;
      _locationExplainerShown = false;
    });
    _scheduleLocationExplainer();
  }

  Future<void> _updatePreferences(UserPreferences preferences) async {
    await _store.savePreferences(preferences, userId: _currentUser?.id);
    if (!mounted) return;
    setState(() => _preferences = preferences);
  }

  Future<String?> _registerUser({required String email, required String password, required String displayName}) async {
    if (widget.authService.isAvailable) {
      final result = await widget.authService.register(email: email, password: password, displayName: displayName);
      if (!result.ok || result.user == null) return result.error ?? 'Could not create account.';
      final user = result.user!;
      final users = _mergeUser(_users, user);
      final prefs = const UserPreferences();
      await _store.saveUsers(users);
      await _store.setCurrentUser(user);
      await _store.savePreferences(prefs, userId: user.id);
      await _store.setOnboarded(false, userId: user.id);
      if (!mounted) return null;
      setState(() {
        _users = users;
        _currentUser = user;
        _preferences = prefs;
        _onboarded = false;
        _checkIns = [];
        _tabIndex = 0;
        _locationExplainerShown = false;
      });
      return result.message;
    }

    // Local fallback keeps development builds usable before Firebase Android config is added.
    final cleanEmail = email.trim().toLowerCase();
    final existing = _users.any((u) => u.email.toLowerCase() == cleanEmail);
    if (existing) return 'This account already exists. Sign in instead.';
    final user = AppUser(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      email: cleanEmail,
      displayName: displayName.trim().isEmpty ? 'MatchPint Fan' : displayName.trim(),
      createdAt: DateTime.now(),
      passwordHash: AppUser.hashPassword(password),
      authProvider: 'local',
    );
    final users = [..._users, user];
    final prefs = const UserPreferences();
    await _store.saveUsers(users);
    await _store.setCurrentUser(user);
    await _store.savePreferences(prefs, userId: user.id);
    await _store.setOnboarded(false, userId: user.id);
    if (!mounted) return null;
    setState(() {
      _users = users;
      _currentUser = user;
      _preferences = prefs;
      _onboarded = false;
      _checkIns = [];
      _tabIndex = 0;
      _locationExplainerShown = false;
    });
    return 'Development fallback account created. Configure Firebase for production Auth.';
  }

  Future<String?> _loginUser({required String email, required String password}) async {
    if (widget.authService.isAvailable) {
      final result = await widget.authService.signIn(email: email, password: password);
      if (!result.ok || result.user == null) return result.error ?? 'Could not sign in.';
      final user = result.user!;
      final users = _mergeUser(_users, user);
      final prefs = await _store.loadPreferences(userId: user.id);
      final onboarded = await _store.isOnboarded(userId: user.id);
      final checkIns = await _store.loadCheckIns(userId: user.id);
      await _store.saveUsers(users);
      await _store.setCurrentUser(user);
      if (!mounted) return null;
      setState(() {
        _users = users;
        _currentUser = user;
        _preferences = prefs;
        _onboarded = onboarded;
        _checkIns = checkIns;
        _tabIndex = 0;
        _locationExplainerShown = false;
      });
      if (onboarded) _scheduleLocationExplainer();
      return result.message;
    }

    final cleanEmail = email.trim().toLowerCase();
    final matches = _users.where((u) => u.email.toLowerCase() == cleanEmail).toList();
    if (matches.isEmpty) return 'No account found for this email.';
    final user = matches.first;
    if (!user.matchesPassword(password)) return 'Incorrect password.';
    final prefs = await _store.loadPreferences(userId: user.id);
    final onboarded = await _store.isOnboarded(userId: user.id);
    final checkIns = await _store.loadCheckIns(userId: user.id);
    await _store.setCurrentUser(user);
    if (!mounted) return null;
    setState(() {
      _currentUser = user;
      _preferences = prefs;
      _onboarded = onboarded;
      _checkIns = checkIns;
      _tabIndex = 0;
      _locationExplainerShown = false;
    });
    if (onboarded) _scheduleLocationExplainer();
    return null;
  }

  Future<void> _updateCurrentUser(AppUser updated) async {
    AppUser next = updated;
    if (_currentUser?.usesFirebase == true && widget.authService.isAvailable) {
      final result = await widget.authService.updateDisplayName(updated.displayName);
      if (result.ok && result.user != null) {
        next = result.user!;
      }
    }
    final users = _mergeUser(_users, next);
    await _store.saveUsers(users);
    await _store.setCurrentUser(next);
    if (!mounted) return;
    setState(() {
      _users = users;
      _currentUser = next;
    });
  }

  Future<bool> _changeEmail(String currentPassword, String newEmail) async {
    final user = _currentUser;
    if (user == null) return false;
    final cleanEmail = newEmail.trim().toLowerCase();
    if (!cleanEmail.contains('@')) return false;
    if (user.usesFirebase && widget.authService.isAvailable) {
      final result = await widget.authService.changeEmail(currentPassword: currentPassword, newEmail: cleanEmail);
      return result.ok;
    }
    if (!user.matchesPassword(currentPassword)) return false;
    final emailTaken = _users.any((u) => u.id != user.id && u.email.toLowerCase() == cleanEmail);
    if (emailTaken) return false;
    await _updateCurrentUser(user.copyWith(email: cleanEmail));
    return true;
  }

  Future<bool> _changePassword(String currentPassword, String newPassword) async {
    final user = _currentUser;
    if (user == null || newPassword.trim().length < 8) return false;
    if (user.usesFirebase && widget.authService.isAvailable) {
      final result = await widget.authService.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return result.ok;
    }
    if (!user.matchesPassword(currentPassword)) return false;
    await _updateCurrentUser(user.copyWith(passwordHash: AppUser.hashPassword(newPassword)));
    return true;
  }

  Future<bool> _deleteAccount(String currentPassword) async {
    final user = _currentUser;
    if (user == null) return false;
    if (user.usesFirebase && widget.authService.isAvailable) {
      final result = await widget.authService.deleteAccount(currentPassword);
      if (!result.ok) return false;
    } else if (!user.matchesPassword(currentPassword)) {
      return false;
    }
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
      _locationExplainerShown = false;
    });
    return true;
  }

  Future<void> _signOut() async {
    await widget.authService.signOut();
    await _store.setCurrentUser(null);
    if (!mounted) return;
    setState(() {
      _currentUser = null;
      _onboarded = false;
      _checkIns = [];
      _tabIndex = 0;
      _locationExplainerShown = false;
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
          locationMessage: _locationMessage,
          gettingLocation: _gettingLocation,
          onUseCurrentLocation: _requestLocationAndRefresh,
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
        currentUser: _currentUser,
        onStartMatchMode: () => _openMatchMode(pub, selectedFixture),
      ),
    ));
  }

  void _openMatchMode(PubSpot pub, MatchFixture fixture) {
    _nav?.push(MaterialPageRoute(
      builder: (_) => MatchModeScreen(
        pub: pub,
        fixture: fixture,
        currentUser: _currentUser,
        onSave: _saveCheckIn,
      ),
    ));
  }


  Widget _buildActiveTab() {
    switch (_tabIndex) {
      case 0:
        return HomeScreen(
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
        );
      case 1:
        return MatchesScreen(fixtures: _fixtures, liveDataMessage: _liveDataMessage, loadingLiveData: _loadingLiveData, onOpenMatch: _openMatch);
      case 2:
        return PubListScreen(
          locationMessage: _locationMessage,
          gettingLocation: _gettingLocation,
          onUseCurrentLocation: _requestLocationAndRefresh,
          preferences: _preferences,
          pubs: _pubs,
          fixtures: _fixtures,
          liveDataMessage: _liveDataMessage,
          onOpenPub: (pub) => _openPub(pub),
        );
      case 3:
        return HistoryScreen(checkIns: _checkIns);
      case 4:
        final user = _currentUser;
        if (user == null) {
          return const Center(child: Text('Please sign in again.'));
        }
        return SettingsScreen(
          user: user,
          preferences: _preferences,
          onUpdatePreferences: _updatePreferences,
          themeMode: _themeMode,
          onSetThemeMode: _setThemeMode,
          onUpdateUser: _updateCurrentUser,
          onChangeEmail: _changeEmail,
          onChangePassword: _changePassword,
          onDeleteAccount: _deleteAccount,
          onSignOut: _signOut,
        );
      default:
        return const SizedBox.shrink();
    }
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
        firebaseAuthAvailable: widget.authService.isAvailable,
        firebaseSetupMessage: widget.authService.isAvailable ? null : widget.authService.lastSetupError,
        onRegister: _registerUser,
        onLogin: _loginUser,
        onResetPassword: widget.authService.isAvailable
            ? (email) => widget.authService.sendPasswordResetEmail(email).then((result) => result.error ?? result.message ?? 'Password reset email sent.')
            : null,
      );
    }
    if (!_onboarded) {
      return OnboardingScreen(onComplete: _completeOnboarding);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('MatchPint')),
      body: _buildActiveTab(),
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
