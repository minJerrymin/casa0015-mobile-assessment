class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.passwordHash = '',
    this.authProvider = 'local',
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;

  // Kept only for older local accounts. New accounts use Firebase Authentication.
  final String passwordHash;
  final String authProvider;
  final bool emailVerified;

  bool get usesFirebase => authProvider == 'firebase';

  static String hashPassword(String password) {
    final trimmed = password.trim();
    var hash = 5381;
    for (final codeUnit in trimmed.codeUnits) {
      hash = ((hash << 5) + hash) ^ codeUnit;
      hash = hash & 0x7fffffff;
    }
    return 'mp_$hash';
  }

  bool matchesPassword(String password) {
    if (usesFirebase) return false;
    if (passwordHash.isEmpty) return true;
    return passwordHash == hashPassword(password);
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    String? passwordHash,
    String? authProvider,
    bool? emailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      passwordHash: passwordHash ?? this.passwordHash,
      authProvider: authProvider ?? this.authProvider,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'passwordHash': passwordHash,
      'authProvider': authProvider,
      'emailVerified': emailVerified,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'MatchPint Fan',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      passwordHash: json['passwordHash'] as String? ?? '',
      authProvider: json['authProvider'] as String? ?? 'local',
      emailVerified: json['emailVerified'] as bool? ?? false,
    );
  }
}
