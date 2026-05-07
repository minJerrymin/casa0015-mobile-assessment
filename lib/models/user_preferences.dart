class UserPreferences {
  const UserPreferences({
    this.team = 'Arsenal',
    this.prefersCalm = false,
    this.soloMode = false,
    this.wantsFood = true,
  });

  final String team;
  final bool prefersCalm;
  final bool soloMode;
  final bool wantsFood;

  UserPreferences copyWith({
    String? team,
    bool? prefersCalm,
    bool? soloMode,
    bool? wantsFood,
  }) {
    return UserPreferences(
      team: team ?? this.team,
      prefersCalm: prefersCalm ?? this.prefersCalm,
      soloMode: soloMode ?? this.soloMode,
      wantsFood: wantsFood ?? this.wantsFood,
    );
  }
}
