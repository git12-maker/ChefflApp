import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import '../core/constants/env.dart';
import '../shared/models/recipe.dart';
import '../shared/models/recipe_preferences.dart';
import '../shared/models/recognized_ingredient.dart';
import 'supabase_service.dart';

/// OpenAI service for recipe generation
class OpenAIService {
  OpenAIService._();
  static final OpenAIService instance = OpenAIService._();

  static const _chatEndpoint = 'https://api.openai.com/v1/chat/completions';

  Future<Recipe> generateRecipe({
    required List<String> ingredients,
    required RecipePreferences preferences,
  }) async {
    if (Env.openAiApiKey.startsWith('YOUR_')) {
      throw Exception('OpenAI API key is not set. Update Env.openAiApiKey.');
    }

    final prompt = _buildPrompt(ingredients, preferences);

    final response = await http.post(
      Uri.parse(_chatEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${Env.openAiApiKey}',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': 'Chef AI. Return ONLY valid JSON matching the schema.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'temperature': 0.5, // Lower for faster, more consistent results
        'max_tokens': 1200, // Limit tokens for speed and cost
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'OpenAI request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content'];
    if (content == null) {
      throw Exception('OpenAI response missing content.');
    }

    final Map<String, dynamic> recipeJson = jsonDecode(content);
    return Recipe.fromJson(recipeJson).copyWith(
      isAiGenerated: true,
    );
  }

  /// Generate a recipe image using Replicate (Flux model) via Supabase Edge Function.
  /// Returns image URL or null if generation fails.
  /// Uses full recipe details to ensure image matches the actual dish.
  Future<String?> generateRecipeImage({
    required Recipe recipe,
  }) async {
    final prompt = _buildImagePrompt(recipe);

    try {
      // Call Supabase Edge Function (handles CORS and Replicate API)
      // Use Map for body instead of JSON string for better compatibility
      final response = await SupabaseService.client.functions.invoke(
        'generate-recipe-image',
        body: {'prompt': prompt},
      );

      if (response.status != 200) {
        // Log error for debugging
        print('Edge Function error: ${response.status} - ${response.data}');
        return null;
      }

      // Handle both Map and direct string responses
      final data = response.data;
      String? imageUrl;
      
      if (data is Map<String, dynamic>) {
        imageUrl = data['imageUrl'] as String?;
      } else if (data is String) {
        // Try to parse as JSON
        try {
          final parsed = jsonDecode(data) as Map<String, dynamic>;
          imageUrl = parsed['imageUrl'] as String?;
        } catch (_) {
          // If not JSON, might be direct URL
          imageUrl = data;
        }
      }

      return imageUrl;
    } catch (e) {
      // Log error for debugging
      print('Image generation error: $e');
      return null;
    }
  }

  /// Build a detailed, high-quality image prompt that matches the recipe exactly
  /// Uses advanced prompt engineering to reduce hallucinations and improve accuracy
  String _buildImagePrompt(Recipe recipe) {
    // Extract ALL ingredients with amounts for accuracy
    final allIngredients = recipe.ingredients
        .map((i) => '${i.amount} ${i.name}'.toLowerCase())
        .join(', ');
    
    // Extract primary ingredients (first 5) for visual focus
    final primaryIngredients = recipe.ingredients
        .take(5)
        .map((i) => i.name.toLowerCase())
        .join(', ');

    // Extract cooking methods and techniques from instructions
    final visualKeywords = _extractVisualKeywords(recipe.instructions);
    
    // Determine dish type and presentation
    final dishType = _determineDishType(recipe);
    final presentation = _determinePresentation(recipe);
    
    // Extract key cooking techniques
    final cookingTechniques = _extractCookingTechniques(recipe.instructions);
    
    // Build comprehensive, detailed prompt with negative prompts to prevent hallucinations
    final prompt = '''
Professional food photography, restaurant quality, high resolution, 8k detail.

DISH: ${recipe.title}
INGREDIENTS VISIBLE: $primaryIngredients
ALL INGREDIENTS USED: $allIngredients
COOKING METHOD: $cookingTechniques
PRESENTATION: $dishType
STYLE: $presentation

VISUAL REQUIREMENTS:
- Accurately show ONLY the ingredients listed: $primaryIngredients
- Match the cooking method: $visualKeywords
- Professional plating, restaurant presentation
- Natural daylight, soft shadows, appetizing lighting
- 45-degree angle or top-down view
- Shallow depth of field, focus on main dish
- Clean, minimal background, no distracting elements
- Food must look fresh, properly cooked, and realistic
- Colors must be natural and appetizing

TECHNICAL SPECIFICATIONS:
- Food photography style, not illustration
- No text, no labels, no people, no hands
- No unrealistic colors or proportions
- No ingredients that are not in the recipe
- Accurate representation of the actual dish

NEGATIVE PROMPT (what NOT to include):
- No ingredients not listed in recipe
- No unrealistic food combinations
- No cartoon or illustration style
- No text or labels
- No people or hands
- No artificial colors
- No incorrect cooking methods
- No food that doesn't match the recipe description

The image must be a photorealistic representation of exactly how this dish appears when prepared following the recipe instructions. Every visible ingredient must be from the recipe list.
'''.trim();

    return prompt;
  }
  
  /// Extract cooking techniques from instructions
  String _extractCookingTechniques(List<String> instructions) {
    final techniques = <String>[];
    final techniqueKeywords = {
      'grill': 'grilled',
      'roast': 'roasted',
      'fry': 'fried',
      'bake': 'baked',
      'steam': 'steamed',
      'boil': 'boiled',
      'sauté': 'sautéed',
      'sear': 'seared',
      'braise': 'braised',
      'stir-fry': 'stir-fried',
      'simmer': 'simmered',
      'poach': 'poached',
    };
    
    final instructionText = instructions.join(' ').toLowerCase();
    
    for (final entry in techniqueKeywords.entries) {
      if (instructionText.contains(entry.key)) {
        techniques.add(entry.value);
      }
    }
    
    return techniques.isNotEmpty ? techniques.join(', ') : 'cooked';
  }

  /// Extract visual keywords from instructions (cooking methods, techniques)
  String _extractVisualKeywords(List<String> instructions) {
    final keywords = <String>[];
    final visualTerms = [
      'grilled', 'roasted', 'fried', 'baked', 'steamed', 'boiled',
      'sautéed', 'seared', 'braised', 'stir-fried', 'crispy', 'golden',
      'layered', 'stacked', 'drizzled', 'garnished', 'sliced', 'chopped',
      'diced', 'minced', 'shredded', 'whole', 'halved', 'quartered',
      'topped with', 'served with', 'accompanied by', 'dressed with',
    ];

    final instructionText = instructions.join(' ').toLowerCase();
    
    for (final term in visualTerms) {
      if (instructionText.contains(term)) {
        keywords.add(term);
      }
    }

    return keywords.take(3).join(', ');
  }

  /// Determine dish type (soup, salad, pasta, etc.)
  String _determineDishType(Recipe recipe) {
    final titleLower = recipe.title.toLowerCase();
    final descLower = (recipe.description ?? '').toLowerCase();
    final combined = '$titleLower $descLower';

    if (combined.contains('soup') || combined.contains('stew') || 
        combined.contains('broth')) {
      return 'served in a bowl';
    }
    if (combined.contains('salad')) {
      return 'fresh salad on a plate';
    }
    if (combined.contains('pasta') || combined.contains('spaghetti') || 
        combined.contains('noodle')) {
      return 'pasta dish on a plate';
    }
    if (combined.contains('sandwich') || combined.contains('burger') || 
        combined.contains('wrap')) {
      return 'sandwich or handheld item';
    }
    if (combined.contains('pizza')) {
      return 'pizza on a wooden board';
    }
    if (combined.contains('cake') || combined.contains('dessert') || 
        combined.contains('sweet')) {
      return 'dessert on a plate';
    }
    if (combined.contains('drink') || combined.contains('smoothie') || 
        combined.contains('juice')) {
      return 'beverage in a glass';
    }

    return 'main dish on a plate';
  }

  /// Determine presentation style
  String _determinePresentation(Recipe recipe) {
    final instructions = recipe.instructions.join(' ').toLowerCase();
    
    if (instructions.contains('garnish') || instructions.contains('sprinkle')) {
      return 'Garnished and beautifully presented.';
    }
    if (instructions.contains('drizzle') || instructions.contains('sauce')) {
      return 'With sauce or dressing visible.';
    }
    if (instructions.contains('serve') && instructions.contains('hot')) {
      return 'Steaming hot, fresh from cooking.';
    }
    if (instructions.contains('chill') || instructions.contains('cold')) {
      return 'Chilled and refreshing.';
    }

    return 'Freshly prepared and ready to serve.';
  }

  /// Recognize ingredients from an image using GPT-4 Vision
  Future<List<RecognizedIngredient>> recognizeIngredients(File imageFile) async {
    if (Env.openAiApiKey.startsWith('YOUR_')) {
      throw Exception('OpenAI API key is not set. Update Env.openAiApiKey.');
    }

    try {
      // Read and encode image as base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Determine image format
      final imageFormat = imageFile.path.toLowerCase().endsWith('.png') 
          ? 'png' 
          : 'jpeg';

      final response = await http.post(
        Uri.parse(_chatEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openAiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'response_format': {'type': 'json_object'}, // Force JSON object response
          'messages': [
            {
              'role': 'system',
              'content': 'You are a food ingredient recognition system. Always return valid JSON only, no markdown, no code blocks, no explanations.',
            },
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': '''Analyze this image and identify all visible food ingredients. 

Return a JSON object with an "ingredients" array. Each ingredient object must have:
- name: string (ingredient name)
- category: one of: vegetable, protein, dairy, grain, fruit, condiment, other
- confidence: one of: high, medium, low

Format: {"ingredients": [{"name": "tomato", "category": "vegetable", "confidence": "high"}, {"name": "chicken", "category": "protein", "confidence": "medium"}]}

Only include actual food items visible in the image.''',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/$imageFormat;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 800,
          'temperature': 0.2, // Lower temperature for more consistent JSON
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'OpenAI Vision request failed (${response.statusCode}): ${response.body}',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['choices']?[0]?['message']?['content'];
      if (content == null) {
        throw Exception('OpenAI Vision response missing content.');
      }

      // Parse the JSON response
      // With response_format: json_object, GPT should return a JSON object
      String cleanedContent = content.trim();
      
      // Remove markdown code blocks if present (fallback for older models)
      if (cleanedContent.startsWith('```')) {
        cleanedContent = cleanedContent.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
        cleanedContent = cleanedContent.replaceFirst(RegExp(r'\s*```$'), '');
        cleanedContent = cleanedContent.trim();
      }
      
      // Parse as JSON object or array
      dynamic parsedJson;
      List<dynamic> ingredientsJson;
      
      try {
        parsedJson = jsonDecode(cleanedContent);
        
        // Handle both object format {"ingredients": [...]} and array format [...]
        if (parsedJson is Map<String, dynamic>) {
          // Check if it's wrapped in an "ingredients" key
          if (parsedJson.containsKey('ingredients')) {
            ingredientsJson = parsedJson['ingredients'] as List<dynamic>;
          } else {
            // Try to find any array in the object
            final arrayValue = parsedJson.values.firstWhere(
              (v) => v is List,
              orElse: () => <dynamic>[],
            );
            ingredientsJson = arrayValue as List<dynamic>;
          }
        } else if (parsedJson is List) {
          // Direct array format
          ingredientsJson = parsedJson;
        } else {
          throw Exception('Unexpected JSON format: ${parsedJson.runtimeType}');
        }
      } catch (jsonError) {
        // Fallback: try to extract JSON array from text
        final jsonMatch = RegExp(r'\[[\s\S]*?\]').firstMatch(cleanedContent);
        if (jsonMatch != null) {
          try {
            ingredientsJson = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
          } catch (_) {
            throw Exception(
              'Failed to parse JSON. Response preview: ${cleanedContent.length > 200 ? cleanedContent.substring(0, 200) + "..." : cleanedContent}. Error: $jsonError',
            );
          }
        } else {
          throw Exception(
            'Failed to parse JSON from response. Content preview: ${cleanedContent.length > 200 ? cleanedContent.substring(0, 200) + "..." : cleanedContent}. Error: $jsonError',
          );
        }
      }

      // Validate and parse ingredients
      if (ingredientsJson.isEmpty) {
        throw Exception('No ingredients found in the image.');
      }

      return ingredientsJson
          .map((e) {
            try {
              return RecognizedIngredient.fromJson(e as Map<String, dynamic>);
            } catch (e) {
              print('⚠️ Error parsing ingredient: $e');
              return null;
            }
          })
          .whereType<RecognizedIngredient>()
          .toList();
    } catch (e) {
      // Provide more detailed error message
      final errorMessage = e.toString();
      print('❌ Error recognizing ingredients: $errorMessage');
      throw Exception('Failed to recognize ingredients: ${errorMessage.replaceAll("Exception: ", "")}');
    }
  }

  String _buildPrompt(
    List<String> ingredients,
    RecipePreferences preferences,
  ) {
    // Build compact prompt for speed and cost efficiency
    final ingredientsStr = ingredients.join(', ');
    final parts = <String>[];
    
    if (preferences.servings != null) parts.add('${preferences.servings} servings');
    if (preferences.difficulty != null) parts.add(preferences.difficulty!);
    if (preferences.cuisine != null) parts.add(preferences.cuisine!);
    if (preferences.dietaryRestrictions.isNotEmpty) {
      parts.add(preferences.dietaryRestrictions.join(', '));
    }
    if (preferences.maxTimeMinutes != null) {
      parts.add('max ${preferences.maxTimeMinutes}min');
    }
    
    final prefsStr = parts.isEmpty ? '' : ' Preferences: ${parts.join(', ')}.';
    
    return '''Ingredients: $ingredientsStr.$prefsStr

Return JSON:
{
  "title": string,
  "description": string (1-2 sentences),
  "ingredients": [{"name": string, "amount": string}],
  "instructions": [string] (3-6 steps, concise),
  "prep_time": integer,
  "cook_time": integer,
  "servings": integer,
  "difficulty": "easy"|"medium"|"hard",
  "cuisine": string,
  "dietary_tags": [string],
  "image_url": null
}''';
  }
}
