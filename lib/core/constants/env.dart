/// Environment constants for Cheffl
/// 
/// IMPORTANT: Replace the placeholder values below with your actual Supabase credentials.
/// You can find these in your Supabase project settings:
/// 1. Go to https://app.supabase.com
/// 2. Select your project
/// 3. Go to Settings > API
/// 4. Copy the "Project URL" and "anon public" key
class Env {
  Env._();

  /// Supabase Project URL
  /// Replace with your actual Supabase project URL
  /// Example: 'https://your-project-id.supabase.co'
  static const String supabaseUrl = 'https://ygkhhkezjtieuxeppgwe.supabase.co';

  /// Supabase Anon Key (public key)
  /// Replace with your actual Supabase anon key
  /// This is safe to use in client-side code
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlna2hoa2V6anRpZXV4ZXBwZ3dlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMxMTE0NDQsImV4cCI6MjA3ODY4NzQ0NH0.SxiAC9NDc95ZIBEYSaOTD2M97hpfpM3ordcngc_ep6U';

  /// OpenAI API Key
  /// Replace with your actual OpenAI API key before running generation
  /// Example: 'sk-...'
  /// IMPORTANT: Never commit real API keys to version control!
  /// Use environment variables or a secrets file that is gitignored
  static const String openAiApiKey = ''; // Set locally - never commit real keys

  /// Replicate API Key
  /// Replace with your actual Replicate API key for image generation
  /// You can find this at: https://replicate.com/account/api-tokens
  /// Example: 'r8_...'
  /// IMPORTANT: Never commit real API keys to version control!
  static const String replicateApiKey = ''; // Set locally - never commit real keys
}
