import 'supabase_service.dart';

const int freeRecipesCount = 3;
const int creditsPerRecipe = 1;

/// Manages user credits - 3 free recipes, then must buy
class CreditsService {
  CreditsService._();
  static final CreditsService instance = CreditsService._();

  Future<int> getAvailableCredits() async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) return 0;

    final response = await SupabaseService.client
        .from('user_profiles')
        .select('credits_balance, free_recipes_used')
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return 0;

    final freeUsed = response['free_recipes_used'] as int? ?? 0;
    final credits = response['credits_balance'] as int? ?? 0;
    final freeRemaining = (freeRecipesCount - freeUsed).clamp(0, freeRecipesCount);
    return freeRemaining + credits;
  }

  Future<bool> canGenerateRecipe() async {
    return (await getAvailableCredits()) >= creditsPerRecipe;
  }

  Future<void> deductCredit() async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) throw Exception('Not logged in');

    final profile = await SupabaseService.client
        .from('user_profiles')
        .select('credits_balance, free_recipes_used')
        .eq('id', userId)
        .single();

    final freeUsed = profile['free_recipes_used'] as int? ?? 0;
    final credits = profile['credits_balance'] as int? ?? 0;

    if (freeUsed < freeRecipesCount) {
      await SupabaseService.client
          .from('user_profiles')
          .update({'free_recipes_used': freeUsed + 1})
          .eq('id', userId);
    } else if (credits >= creditsPerRecipe) {
      await SupabaseService.client
          .from('user_profiles')
          .update({'credits_balance': credits - creditsPerRecipe})
          .eq('id', userId);
    } else {
      throw Exception('No credits remaining');
    }
  }

  Future<int> getFreeRemaining() async {
    final userId = SupabaseService.getCurrentUser()?.id;
    if (userId == null) return 0;
    final r = await SupabaseService.client
        .from('user_profiles')
        .select('free_recipes_used')
        .eq('id', userId)
        .maybeSingle();
    final used = r?['free_recipes_used'] as int? ?? 0;
    return (freeRecipesCount - used).clamp(0, freeRecipesCount);
  }
}
