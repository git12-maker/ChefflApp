import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/env.dart';

/// Supabase service - Singleton pattern for Supabase client
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Initialize Supabase client
  /// Call this once in main.dart before runApp
  static Future<void> initialize() async {
    if (_initialized) return;

    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );

    _client = Supabase.instance.client;
    _initialized = true;
  }

  /// Get Supabase client instance
  /// Throws if not initialized
  static SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Get current authenticated user
  /// Returns null if not authenticated
  static User? getCurrentUser() {
    return _client?.auth.currentUser;
  }

  /// Get auth state changes stream
  /// Listen to this for real-time auth state updates
  static Stream<AuthState> get authStateChanges {
    return _client!.auth.onAuthStateChange;
  }

  /// Check if user is authenticated
  static bool get isAuthenticated {
    return _client?.auth.currentUser != null;
  }
}
