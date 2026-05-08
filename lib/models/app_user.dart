class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.passwordHash,
  });

  final String id;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final String passwordHash;

  static String hashPassword(String password) {
    // Prototype-only deterministic hash. V1 production should use Firebase Auth
    // or another server-side auth provider rather than storing passwords locally.
    final trimmed = password.trim();
    var hash = 5381;
    for (final codeUnit in trimmed.codeUnits) {
      hash = ((hash << 5) + hash) ^ codeUnit;
      hash = hash & 0x7fffffff;
    }
    return 'mp_$hash';
  }

  bool matchesPassword(String password) {
    if (passwordHash.isEmpty) {
      // Legacy V0.2/V0.3 local accounts did not store a password hash.
      // Allow a one-time compatibility sign-in and encourage changing password.
      return true;
    }
    return passwordHash == hashPassword(password);
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? createdAt,
    String? passwordHash,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      passwordHash: passwordHash ?? this.passwordHash,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'passwordHash': passwordHash,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      passwordHash: json['passwordHash'] as String? ?? '',
    );
  }
}
