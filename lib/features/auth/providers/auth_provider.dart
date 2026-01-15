import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/auth_service.dart';

/// Provider for AuthService instance
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService.instance;
});

/// Provider for current user
/// Automatically updates when auth state changes
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((authState) {
    return authState.session?.user;
  });
});

/// Provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(currentUserProvider);
  return authState.valueOrNull != null;
});
