import 'package:flutter/material.dart';

import 'models/check_in.dart';
import 'models/match_fixture.dart';
import 'models/pub_spot.dart';
import 'models/user_preferences.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/match_mode_screen.dart';
import 'screens/matches_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pub_detail_screen.dart';
import 'screens/pub_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'data/mock_data.dart';

void main() {
  runApp(const MatchPintApp());
}

class MatchPintApp extends StatefulWidget {
  const MatchPintApp({super.key});

  @override
  State<MatchPintApp> createState() => _MatchPintAppState();
}

class _MatchPintAppState extends State<MatchPintApp> {
  bool _showSplash = true;
  bool _onboarded = false;
  int _tabIndex = 0;
  UserPreferences _preferences = const UserPreferences();
  final List<CheckIn> _checkIns = [];

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
      theme: AppTheme.dark(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_showSplash) {
      return SplashScreen(onFinished: () => setState(() => _showSplash = false));
    }
    if (!_onboarded) {
      return OnboardingScreen(
        onComplete: (preferences) => setState(() {
          _preferences = preferences;
          _onboarded = true;
        }),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('MatchPint'),
        actions: [
          IconButton(
            tooltip: 'Find pubs',
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _tabIndex = 2),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          HomeScreen(preferences: _preferences, onOpenMatch: _openMatch, onOpenPub: (pub) => _openPub(pub)),
          MatchesScreen(onOpenMatch: _openMatch),
          PubListScreen(preferences: _preferences, onOpenPub: (pub) => _openPub(pub)),
          HistoryScreen(checkIns: _checkIns),
          SettingsScreen(preferences: _preferences, onUpdate: (prefs) => setState(() => _preferences = prefs)),
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
