import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/user_preferences.dart';

class LocalStore {
  static const String _legacyOnboardedKey = 'matchpint.onboarded';
  static const String _legacyTeamKey = 'matchpint.preferences.team';
  static const String _legacyCalmKey = 'matchpint.preferences.prefersCalm';
  static const String _legacySoloKey = 'matchpint.preferences.soloMode';
  static const String _legacyFoodKey = 'matchpint.preferences.wantsFood';
  static const String _usersKey = 'matchpint.users';
  static const String _currentUserKey = 'matchpint.currentUserId';
  static const String _themeModeKey = 'matchpint.themeMode';

  String _userOnboardedKey(String userId) => 'matchpint.users.$userId.onboarded';
  String _userTeamKey(String userId) => 'matchpint.users.$userId.preferences.team';
  String _userCalmKey(String userId) => 'matchpint.users.$userId.preferences.prefersCalm';
  String _userSoloKey(String userId) => 'matchpint.users.$userId.preferences.soloMode';
  String _userFoodKey(String userId) => 'matchpint.users.$userId.preferences.wantsFood';

  Future<bool> isOnboarded({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      return prefs.getBool(_userOnboardedKey(userId)) ?? false;
    }
    return prefs.getBool(_legacyOnboardedKey) ?? false;
  }

  Future<void> setOnboarded(bool value, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setBool(_userOnboardedKey(userId), value);
      return;
    }
    await prefs.setBool(_legacyOnboardedKey, value);
  }

  Future<UserPreferences> loadPreferences({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      return UserPreferences(
        team: prefs.getString(_userTeamKey(userId)) ?? prefs.getString(_legacyTeamKey) ?? 'Arsenal',
        prefersCalm: prefs.getBool(_userCalmKey(userId)) ?? prefs.getBool(_legacyCalmKey) ?? false,
        soloMode: prefs.getBool(_userSoloKey(userId)) ?? prefs.getBool(_legacySoloKey) ?? false,
        wantsFood: prefs.getBool(_userFoodKey(userId)) ?? prefs.getBool(_legacyFoodKey) ?? true,
      );
    }
    return UserPreferences(
      team: prefs.getString(_legacyTeamKey) ?? 'Arsenal',
      prefersCalm: prefs.getBool(_legacyCalmKey) ?? false,
      soloMode: prefs.getBool(_legacySoloKey) ?? false,
      wantsFood: prefs.getBool(_legacyFoodKey) ?? true,
    );
  }

  Future<void> savePreferences(UserPreferences value, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString(_userTeamKey(userId), value.team);
      await prefs.setBool(_userCalmKey(userId), value.prefersCalm);
      await prefs.setBool(_userSoloKey(userId), value.soloMode);
      await prefs.setBool(_userFoodKey(userId), value.wantsFood);
      return;
    }
    await prefs.setString(_legacyTeamKey, value.team);
    await prefs.setBool(_legacyCalmKey, value.prefersCalm);
    await prefs.setBool(_legacySoloKey, value.soloMode);
    await prefs.setBool(_legacyFoodKey, value.wantsFood);
  }

  Future<List<AppUser>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => AppUser.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveUsers(List<AppUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  Future<AppUser?> loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_currentUserKey);
    if (id == null || id.trim().isEmpty) return null;
    final users = await loadUsers();
    for (final user in users) {
      if (user.id == id) return user;
    }
    return null;
  }

  Future<void> setCurrentUser(AppUser? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_currentUserKey);
    } else {
      await prefs.setString(_currentUserKey, user.id);
    }
  }

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themeModeKey) ?? 'system';
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_themeModeKey, raw);
  }
}
