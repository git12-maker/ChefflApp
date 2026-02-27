import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/env.dart';
import 'image_storage_service.dart';
import 'supabase_service.dart';

/// Service for generating ingredient images using Recraft AI
/// Generates consistent, high-quality food photography style images
class RecraftImageService {
  RecraftImageService._();
  static final RecraftImageService instance = RecraftImageService._();

  static const String _baseUrl = 'https://external.api.recraft.ai/v1/images/generations';
  static const String _apiKey = Env.recraftApiKey;

  /// Generate an image for an ingredient using Recraft AI
  /// Returns the URL of the generated image
  Future<String?> generateIngredientImage({
    required String ingredientName,
    String? categoryName,
    String? description,
  }) async {
    try {
      // Build prompt based on ingredient type
      final prompt = _buildPrompt(
        ingredientName: ingredientName,
        categoryName: categoryName,
        description: description,
      );

      // Call Recraft API
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'style': 'photography',
          'aspect_ratio': '1:1',
          'output_format': 'png',
          'resolution': '1024x1024',
          'negative_prompt': _getNegativePrompt(),
        }),
      );

      if (response.statusCode != 200) {
        print('Recraft API error: ${response.statusCode}');
        print('Response: ${response.body}');
        return null;
      }

      final responseData = jsonDecode(response.body);
      
      // Extract image URL from response
      // Note: Recraft API response structure may vary, adjust as needed
      final imageUrl = responseData['data']?[0]?['url'] ?? 
                      responseData['url'] ?? 
                      responseData['image_url'];
      
      if (imageUrl == null) {
        print('No image URL in Recraft response');
        print('Response: ${response.body}');
        return null;
      }

      return imageUrl as String;
    } catch (e) {
      print('Error generating ingredient image: $e');
      return null;
    }
  }

  /// Build a consistent prompt for ingredient image generation
  String _buildPrompt({
    required String ingredientName,
    String? categoryName,
    String? description,
  }) {
    // Determine ingredient type for prompt adaptation
    final ingredientType = _determineIngredientType(ingredientName, categoryName);
    
    // Base prompt template
    final basePrompt = 'Professional food photography of $ingredientName, '
        'shot on clean white background, '
        'soft natural lighting from top, '
        '45-degree angle view, '
        'high resolution, sharp focus, '
        'vibrant true-to-life colors, '
        'single ingredient centered composition, '
        'premium quality, appetizing, '
        'no shadows, no props, no text, '
        'isolated on white background. '
        'CRITICAL: Always realistic – no hallucinations, no invented elements.';

    // Add type-specific details
    switch (ingredientType) {
      case IngredientType.freshVegetable:
      case IngredientType.freshFruit:
        return 'Professional food photography of fresh ripe $ingredientName, '
            'shot on clean white background, '
            'soft natural lighting from top, '
            '45-degree angle view, '
            'high resolution, sharp focus, '
            'vibrant true-to-life colors, '
            'natural texture visible, '
            'organic appearance, '
            'single ingredient centered composition, '
            'premium quality, appetizing, '
            'no shadows, no props, no text, '
            'isolated on white background. '
            'Always realistic, no hallucinations.';

      case IngredientType.freshHerb:
        return 'Professional food photography of fresh bundle of $ingredientName leaves, '
            'shot on clean white background, '
            'soft natural lighting from top, '
            '45-degree angle view, '
            'high resolution, sharp focus, '
            'vibrant green natural colors, '
            'aromatic fresh appearance, '
            'single ingredient centered composition, '
            'premium quality, appetizing, '
            'no shadows, no props, no text, '
            'isolated on white background. '
            'Always realistic, no hallucinations.';

      case IngredientType.protein:
        return 'Professional food photography of fresh raw $ingredientName, '
            'shot on clean white background, '
            'soft natural lighting from top, '
            '45-degree angle view, '
            'high resolution, sharp focus, '
            'natural true-to-life colors, '
            'premium quality cut, '
            'single ingredient centered composition, '
            'appetizing, '
            'no shadows, no props, no text, '
            'isolated on white background. '
            'Always realistic, no hallucinations.';

      case IngredientType.liquid:
      case IngredientType.oil:
        return 'Professional food photography of $ingredientName in clear glass bottle, '
            'shot on clean white background, '
            'soft natural lighting from top, '
            '45-degree angle view, '
            'high resolution, sharp focus, '
            'rich vibrant colors, '
            'liquid texture visible, '
            'single ingredient centered composition, '
            'premium quality, '
            'no shadows, no props, no text, '
            'isolated on white background. '
            'Always realistic, no hallucinations.';

      case IngredientType.grain:
      case IngredientType.legume:
        return 'Professional food photography of dry uncooked $ingredientName, '
            'shot on clean white background, '
            'soft natural lighting from top, '
            '45-degree angle view, '
            'high resolution, sharp focus, '
            'natural texture visible, '
            'close-up detail, '
            'single ingredient centered composition, '
            'premium quality, '
            'no shadows, no props, no text, '
            'isolated on white background. '
            'Always realistic, no hallucinations.';

      case IngredientType.spice:
        return 'Professional food photography of $ingredientName spice, '
            'shot on clean white background, '
            'soft natural lighting from top, '
            '45-degree angle view, '
            'high resolution, sharp focus, '
            'vibrant natural colors, '
            'aromatic appearance, '
            'single ingredient centered composition, '
            'premium quality, '
            'no shadows, no props, no text, '
            'isolated on white background. '
            'Always realistic, no hallucinations.';

      default:
        return basePrompt;
    }
  }

  /// Determine ingredient type for prompt customization
  IngredientType _determineIngredientType(String name, String? category) {
    final nameLower = name.toLowerCase();
    final categoryLower = category?.toLowerCase() ?? '';

    // Check category first
    if (categoryLower.contains('vegetable') || categoryLower.contains('groente')) {
      return IngredientType.freshVegetable;
    }
    if (categoryLower.contains('fruit') || categoryLower.contains('fruit')) {
      return IngredientType.freshFruit;
    }
    if (categoryLower.contains('herb') || categoryLower.contains('kruid')) {
      return IngredientType.freshHerb;
    }
    if (categoryLower.contains('meat') || categoryLower.contains('fish') || 
        categoryLower.contains('vlees') || categoryLower.contains('vis')) {
      return IngredientType.protein;
    }
    if (categoryLower.contains('grain') || categoryLower.contains('graan')) {
      return IngredientType.grain;
    }
    if (categoryLower.contains('legume') || categoryLower.contains('peulvrucht')) {
      return IngredientType.legume;
    }
    if (categoryLower.contains('spice') || categoryLower.contains('specerij')) {
      return IngredientType.spice;
    }
    if (categoryLower.contains('oil') || categoryLower.contains('olie')) {
      return IngredientType.oil;
    }

    // Check name keywords
    if (nameLower.contains('oil') || nameLower.contains('olie') ||
        nameLower.contains('vinegar') || nameLower.contains('azijn') ||
        nameLower.contains('sauce') || nameLower.contains('saus')) {
      return IngredientType.liquid;
    }

    if (nameLower.contains('rice') || nameLower.contains('rijst') ||
        nameLower.contains('pasta') || nameLower.contains('quinoa') ||
        nameLower.contains('barley') || nameLower.contains('gerst')) {
      return IngredientType.grain;
    }

    if (nameLower.contains('lentil') || nameLower.contains('linzen') ||
        nameLower.contains('bean') || nameLower.contains('boon') ||
        nameLower.contains('chickpea') || nameLower.contains('kikkererwt')) {
      return IngredientType.legume;
    }

    if (nameLower.contains('basil') || nameLower.contains('basilicum') ||
        nameLower.contains('parsley') || nameLower.contains('peterselie') ||
        nameLower.contains('cilantro') || nameLower.contains('koriander') ||
        nameLower.contains('mint') || nameLower.contains('munt') ||
        nameLower.contains('dill') || nameLower.contains('dille') ||
        nameLower.contains('rosemary') || nameLower.contains('rozemarijn')) {
      return IngredientType.freshHerb;
    }

    if (nameLower.contains('chicken') || nameLower.contains('kip') ||
        nameLower.contains('beef') || nameLower.contains('rundvlees') ||
        nameLower.contains('pork') || nameLower.contains('varkensvlees') ||
        nameLower.contains('salmon') || nameLower.contains('zalm') ||
        nameLower.contains('tuna') || nameLower.contains('tonijn')) {
      return IngredientType.protein;
    }

    return IngredientType.generic;
  }

  /// Get negative prompt to avoid unwanted elements
  String _getNegativePrompt() {
    return 'blurry, low quality, distorted, '
        'multiple ingredients, '
        'props, utensils, hands, '
        'text, labels, packaging, '
        'dark shadows, harsh lighting, '
        'artificial colors, '
        'unrealistic appearance, '
        'cartoon, illustration, drawing, '
        'hallucinations, invented elements, fake textures, surreal, fantastical, AI artifacts';
  }

  /// Generate and upload ingredient image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String?> generateAndUploadIngredientImage({
    required String ingredientId,
    required String ingredientName,
    String? categoryName,
    String? description,
  }) async {
    try {
      // Generate image via Recraft
      final generatedUrl = await generateIngredientImage(
        ingredientName: ingredientName,
        categoryName: categoryName,
        description: description,
      );

      if (generatedUrl == null) {
        print('Failed to generate image for $ingredientName');
        return null;
      }

      // Upload to Supabase Storage
      final imageStorage = ImageStorageService.instance;
      final uploadedUrl = await imageStorage.uploadIngredientImageFromUrl(
        imageUrl: generatedUrl,
        ingredientId: ingredientId,
        ingredientName: ingredientName,
      );

      if (uploadedUrl == null) {
        print('Failed to upload image for $ingredientName');
        // Return original URL as fallback
        return generatedUrl;
      }

      return uploadedUrl;
    } catch (e) {
      print('Error in generateAndUploadIngredientImage: $e');
      return null;
    }
  }

  /// Update ingredient image URL in database
  Future<bool> updateIngredientImageUrl({
    required String ingredientId,
    required String imageUrl,
  }) async {
    try {
      final client = SupabaseService.client;
      await client
          .from('ingredients')
          .update({'image_url': imageUrl})
          .eq('id', ingredientId);

      return true;
    } catch (e) {
      print('Error updating ingredient image URL: $e');
      return false;
    }
  }
}

/// Ingredient type enum for prompt customization
enum IngredientType {
  freshVegetable,
  freshFruit,
  freshHerb,
  protein,
  liquid,
  oil,
  grain,
  legume,
  spice,
  generic,
}
