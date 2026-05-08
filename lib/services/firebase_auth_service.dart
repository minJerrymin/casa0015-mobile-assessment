import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';

import '../models/app_user.dart';

class FirebaseConfig {
  const FirebaseConfig._();

  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static bool get hasManualOptions =>
      apiKey.isNotEmpty && appId.isNotEmpty && messagingSenderId.isNotEmpty && projectId.isNotEmpty;

  static FirebaseOptions get manualOptions => FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? null : authDomain,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
      );
}

class MatchPintAuthService {
  bool _available = false;
  String? _lastSetupError;

  bool get isAvailable => _available;
  String? get lastSetupError => _lastSetupError;

  fb_auth.FirebaseAuth? get _auth => _available ? fb_auth.FirebaseAuth.instance : null;

  Future<void> initialise() async {
    try {
      if (Firebase.apps.isEmpty) {
        if (FirebaseConfig.hasManualOptions) {
          await Firebase.initializeApp(options: FirebaseConfig.manualOptions);
        } else {
          await Firebase.initializeApp();
        }
      }
      _available = true;
      _lastSetupError = null;
    } catch (error) {
      _available = false;
      _lastSetupError = error.toString();
    }
  }

  Future<AppUser?> restoreUser() async {
    final auth = _auth;
    final user = auth?.currentUser;
    return user == null ? null : _fromFirebaseUser(user);
  }

  Future<AuthActionResult> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final auth = _auth;
    if (auth == null) return AuthActionResult.failure('Firebase Auth is not configured on this build.');
    try {
      final credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) return AuthActionResult.failure('Account creation did not return a Firebase user.');
      final cleanName = displayName.trim().isEmpty ? 'MatchPint Fan' : displayName.trim();
      await user.updateDisplayName(cleanName);
      await user.sendEmailVerification();
      await user.reload();
      return AuthActionResult.success(_fromFirebaseUser(auth.currentUser ?? user));
    } on fb_auth.FirebaseAuthException catch (error) {
      return AuthActionResult.failure(_friendlyAuthError(error));
    } catch (error) {
      return AuthActionResult.failure('Could not create account. Please try again.');
    }
  }

  Future<AuthActionResult> signIn({required String email, required String password}) async {
    final auth = _auth;
    if (auth == null) return AuthActionResult.failure('Firebase Auth is not configured on this build.');
    try {
      final credential = await auth.signInWithEmailAndPassword(email: email, password: password);
      final user = credential.user;
      if (user == null) return AuthActionResult.failure('Sign-in did not return a Firebase user.');
      return AuthActionResult.success(_fromFirebaseUser(user));
    } on fb_auth.FirebaseAuthException catch (error) {
      return AuthActionResult.failure(_friendlyAuthError(error));
    } catch (_) {
      return AuthActionResult.failure('Could not sign in. Please try again.');
    }
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth != null) await auth.signOut();
  }

  Future<AuthActionResult> updateDisplayName(String displayName) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (user == null) return AuthActionResult.failure('Please sign in again.');
    try {
      final cleanName = displayName.trim();
      if (cleanName.isEmpty) return AuthActionResult.failure('Display name cannot be empty.');
      await user.updateDisplayName(cleanName);
      await user.reload();
      return AuthActionResult.success(_fromFirebaseUser(auth!.currentUser ?? user));
    } on fb_auth.FirebaseAuthException catch (error) {
      return AuthActionResult.failure(_friendlyAuthError(error));
    }
  }

  Future<AuthActionResult> changeEmail({required String currentPassword, required String newEmail}) async {
    final auth = _auth;
    final user = auth?.currentUser;
    final oldEmail = user?.email;
    if (user == null || oldEmail == null) return AuthActionResult.failure('Please sign in again.');
    try {
      await _reauthenticate(user, oldEmail, currentPassword);
      await user.verifyBeforeUpdateEmail(newEmail.trim().toLowerCase());
      return AuthActionResult.success(
        _fromFirebaseUser(user),
        message: 'Verification sent to the new email. The address changes after confirmation.',
      );
    } on fb_auth.FirebaseAuthException catch (error) {
      return AuthActionResult.failure(_friendlyAuthError(error));
    }
  }

  Future<AuthActionResult> changePassword({required String currentPassword, required String newPassword}) async {
    final auth = _auth;
    final user = auth?.currentUser;
    final email = user?.email;
    if (user == null || email == null) return AuthActionResult.failure('Please sign in again.');
    try {
      await _reauthenticate(user, email, currentPassword);
      await user.updatePassword(newPassword);
      return AuthActionResult.success(_fromFirebaseUser(user), message: 'Password updated.');
    } on fb_auth.FirebaseAuthException catch (error) {
      return AuthActionResult.failure(_friendlyAuthError(error));
    }
  }

  Future<AuthActionResult> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) return AuthActionResult.failure('Firebase Auth is not configured on this build.');
    try {
      await auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return AuthActionResult.success(null, message: 'Password reset email sent.');
    } on fb_auth.FirebaseAuthException catch (error) {
      return AuthActionResult.failure(_friendlyAuthError(error));
    }
  }

  Future<AuthActionResult> deleteAccount(String currentPassword) async {
    final auth = _auth;
    final user = auth?.currentUser;
    final email = user?.email;
    if (user == null || email == null) return AuthActionResult.failure('Please sign in again.');
    final appUser = _fromFirebaseUser(user);
    try {
      await _reauthenticate(user, email, currentPassword);
      await user.delete();
      return AuthActionResult.success(appUser, message: 'Account deleted.');
    } on fb_auth.FirebaseAuthException catch (error) {
      return AuthActionResult.failure(_friendlyAuthError(error));
    }
  }

  Future<void> _reauthenticate(fb_auth.User user, String email, String password) async {
    final credential = fb_auth.EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(credential);
  }

  AppUser _fromFirebaseUser(fb_auth.User user) {
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: (user.displayName == null || user.displayName!.trim().isEmpty) ? 'MatchPint Fan' : user.displayName!.trim(),
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      passwordHash: '',
      authProvider: 'firebase',
      emailVerified: user.emailVerified,
    );
  }

  String _friendlyAuthError(fb_auth.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Sign in instead.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'requires-recent-login':
        return 'Please sign in again before changing this account detail.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

class AuthActionResult {
  const AuthActionResult._({this.user, this.error, this.message});

  final AppUser? user;
  final String? error;
  final String? message;

  bool get ok => error == null;

  factory AuthActionResult.success(AppUser? user, {String? message}) {
    return AuthActionResult._(user: user, message: message);
  }

  factory AuthActionResult.failure(String message) {
    return AuthActionResult._(error: message);
  }
}
