import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Authentication service for Cheffl
/// Handles all authentication operations with Supabase
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();
  static AuthService get instance => _instance;

  /// Get Supabase auth client
  GoTrueClient get _auth => SupabaseService.client.auth;

  /// Sign up with email and password
  /// 
  /// Returns [AuthResponse] on success
  /// Throws [AuthException] on failure
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  /// Sign in with email and password
  /// 
  /// Returns [Session] on success
  /// Throws [AuthException] on failure
  Future<Session> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response.session!;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  /// 
  /// Throws [AuthException] on failure
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: null, // You can add a redirect URL here if needed
    );
  }

  /// Get current authenticated user
  /// Returns null if not authenticated
  User? getCurrentUser() {
    return SupabaseService.getCurrentUser();
  }

  /// Stream of auth state changes
  /// Listen to this for real-time authentication state updates
  Stream<AuthState> get authStateChanges {
    return SupabaseService.authStateChanges;
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated {
    return SupabaseService.isAuthenticated;
  }
}
