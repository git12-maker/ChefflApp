/// App configuration for free tier and premium features
class AppConfig {
  AppConfig._();

  /// Free tier limits
  static const int freeRecipesPerDay = 10;
  static const int freeRecipesPerMonth = 100;
  
  /// Image generation settings
  /// Set to false for free tier to reduce costs
  static const bool enableImageGeneration = false; // Disable for free tier
  
  /// Premium features
  static const bool enablePremiumFeatures = false; // Future: premium tier
}
