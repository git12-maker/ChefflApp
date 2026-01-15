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
      final errorBody = response.body;
      throw Exception(
        'OpenAI request failed (${response.statusCode}): ${errorBody.length > 200 ? errorBody.substring(0, 200) + '...' : errorBody}',
      );
    }

    // Parse response with error handling
    Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse OpenAI response: $e');
    }

    final content = decoded['choices']?[0]?['message']?['content'];
    if (content == null || content.toString().isEmpty) {
      throw Exception('OpenAI response missing content.');
    }

    // Parse recipe JSON with error handling
    Map<String, dynamic> recipeJson;
    try {
      // Remove markdown code blocks if present
      String cleanedContent = content.toString().trim();
      if (cleanedContent.startsWith('```')) {
        // Remove markdown code block markers
        final lines = cleanedContent.split('\n');
        if (lines.first.contains('json')) {
          lines.removeAt(0);
        }
        if (lines.last.trim() == '```') {
          lines.removeLast();
        }
        cleanedContent = lines.join('\n').trim();
      }
      
      recipeJson = jsonDecode(cleanedContent) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to parse recipe JSON: $e. Content: ${content.toString().substring(0, content.toString().length > 100 ? 100 : content.toString().length)}');
    }

    // Validate and create recipe with error handling
    try {
      final recipe = Recipe.fromJson(recipeJson);
      
      // Mark user-provided ingredients and extract missing ones from instructions
      // Normalize user ingredients: lowercase, trim, remove plurals for better matching
      final userIngredientNames = ingredients.map((i) => _normalizeIngredientName(i)).toSet();
      final updatedIngredients = <RecipeIngredient>[];
      
      // First, mark existing ingredients as user-provided if they match user input
      for (final ingredient in recipe.ingredients) {
        final ingredientNameNormalized = _normalizeIngredientName(ingredient.name);
        
        // Check for exact match or substring match (handles plurals, variations)
        final isUserProvided = userIngredientNames.any((userIng) {
          // Exact match after normalization
          if (ingredientNameNormalized == userIng) return true;
          
          // Check if normalized names contain each other (handles "potato" vs "potatoes")
          if (ingredientNameNormalized.contains(userIng) || userIng.contains(ingredientNameNormalized)) {
            // Additional check: ensure it's not just a partial word match
            // e.g., "mayo" shouldn't match "mayonnaise" unless user typed "mayo"
            final words = ingredientNameNormalized.split(RegExp(r'[\s,-]+'));
            final userWords = userIng.split(RegExp(r'[\s,-]+'));
            
            // Check if any word from user input matches any word from ingredient
            for (final userWord in userWords) {
              if (userWord.length < 3) continue; // Skip very short words
              for (final word in words) {
                if (word == userWord || 
                    (word.length >= userWord.length && word.startsWith(userWord)) ||
                    (userWord.length >= word.length && userWord.startsWith(word))) {
                  return true;
                }
              }
            }
          }
          return false;
        });
        
        updatedIngredients.add(ingredient.copyWith(isUserProvided: isUserProvided));
      }
      
      // Extract ingredients mentioned in instructions that aren't in the ingredient list
      // Only extract if they're NOT user-provided (to avoid duplicates)
      final existingIngredientNames = updatedIngredients
          .map((i) => _normalizeIngredientName(i.name))
          .toSet();
      final userProvidedNames = updatedIngredients
          .where((i) => i.isUserProvided)
          .map((i) => _normalizeIngredientName(i.name))
          .toSet();
      
      final instructionIngredients = _extractIngredientsFromInstructions(
        recipe.instructions,
        existingIngredientNames,
        userProvidedNames, // Don't extract ingredients that user already provided
      );
      
      // Add auto-added ingredients (marked as not user-provided)
      for (final extracted in instructionIngredients) {
        updatedIngredients.add(RecipeIngredient(
          name: extracted['name'] as String,
          amount: extracted['amount'] as String? ?? 'as needed',
          isUserProvided: false,
        ));
      }
      
      // Ensure dietary tags match the dietary restrictions from preferences
      // Map dietary tags to match profile dietary preferences format
      final dietaryTags = recipe.dietaryTags.isNotEmpty
          ? recipe.dietaryTags
          : preferences.dietaryRestrictions;
      
      return recipe.copyWith(
        isAiGenerated: true,
        dietaryTags: dietaryTags,
        ingredients: updatedIngredients,
      );
    } catch (e) {
      throw Exception('Failed to create recipe from JSON: $e');
    }
  }

  /// Normalize ingredient name for better matching (lowercase, trim, remove common suffixes)
  /// Handles plurals, capitalization, and common variations
  String _normalizeIngredientName(String name) {
    String normalized = name.toLowerCase().trim();
    
    // Remove common plural endings for better matching
    // This helps match "potato" with "potatoes", "tomato" with "tomatoes", etc.
    
    // Handle irregular plurals first (children, mice, etc. - but these are rare for ingredients)
    
    // Handle -ies -> -y (berries -> berry, cherries -> cherry)
    if (normalized.endsWith('ies') && normalized.length > 4) {
      normalized = normalized.substring(0, normalized.length - 3) + 'y';
    } 
    // Handle -es endings (potatoes, tomatoes, but NOT mayonnaise, rice)
    else if (normalized.endsWith('es') && normalized.length > 4) {
      final beforeEs = normalized.substring(0, normalized.length - 2);
      // Only remove 'es' if it's a clear plural pattern
      // Check for words ending in o, s, x, z, ch, sh before 'es'
      if (beforeEs.endsWith('o') || beforeEs.endsWith('s') || beforeEs.endsWith('x') || 
          beforeEs.endsWith('z') || beforeEs.endsWith('ch') || beforeEs.endsWith('sh')) {
        normalized = beforeEs;
      }
      // Also handle -ves -> -f (leaves -> leaf, but this is rare for ingredients)
    } 
    // Handle simple -s plural (apples, oranges, potatoes if not caught above)
    else if (normalized.endsWith('s') && normalized.length > 3) {
      final beforeS = normalized.substring(0, normalized.length - 1);
      // Only remove 's' if it's likely a plural
      // Don't remove if word naturally ends in 's' (rice, mayonnaise, etc.)
      // Check for common non-plural endings
      if (!beforeS.endsWith('s') && 
          !beforeS.endsWith('e') && // mayonnaise, rice (but we want to keep 'e' for some cases)
          !beforeS.endsWith('i') && 
          beforeS.length > 2) {
        // Additional check: don't remove 's' from words that are typically singular
        final commonSingularEndings = ['ss', 'us', 'is', 'as'];
        if (!commonSingularEndings.any((ending) => beforeS.endsWith(ending))) {
          normalized = beforeS;
        }
      }
    }
    
    return normalized;
  }

  /// Extract ingredients mentioned in instructions that aren't already in the ingredient list
  /// Returns list of maps with 'name' and optional 'amount'
  List<Map<String, dynamic>> _extractIngredientsFromInstructions(
    List<String> instructions,
    Set<String> existingIngredientNames,
    Set<String> userProvidedNames,
  ) {
    final extracted = <Map<String, dynamic>>[];
    final commonIngredients = [
      'salt', 'pepper', 'black pepper', 'oil', 'olive oil', 'vegetable oil', 
      'butter', 'garlic', 'onion', 'water', 'sugar', 'flour', 'vinegar',
      'lemon', 'lime', 'herbs', 'spices', 'paprika', 'cumin', 'oregano',
      'basil', 'parsley', 'thyme', 'rosemary', 'ginger', 'chili', 'chili flakes',
      'bay leaves', 'cinnamon', 'nutmeg', 'vanilla', 'baking powder', 'baking soda',
    ];
    
    // Combine all instructions into one text
    final instructionsText = instructions.join(' ').toLowerCase();
    
      // Look for common ingredients that might be missing
      for (final common in commonIngredients) {
        // Check if ingredient is mentioned in instructions
        // Use word boundaries to avoid partial matches
        final pattern = RegExp(r'\b' + RegExp.escape(common) + r'\b', caseSensitive: false);
        if (pattern.hasMatch(instructionsText)) {
          // Normalize the common ingredient name for comparison
          final commonNormalized = _normalizeIngredientName(common);
          
          // Check if it's already in the ingredient list (case-insensitive, normalized)
          final isAlreadyIncluded = existingIngredientNames.any((existing) => 
            existing == commonNormalized || 
            existing.contains(commonNormalized) || 
            commonNormalized.contains(existing)
          );
          
          // Also check if user already provided this ingredient (don't mark as auto-added)
          final isUserProvided = userProvidedNames.any((userIng) =>
            userIng == commonNormalized ||
            userIng.contains(commonNormalized) ||
            commonNormalized.contains(userIng)
          );
          
          if (!isAlreadyIncluded && !isUserProvided) {
          // Try to extract amount if mentioned nearby
          String? amount;
          // Look for amount patterns before or after the ingredient
          final amountPatterns = [
            RegExp(r'(\d+\s*(?:tbsp|tsp|cup|cups|ml|g|kg|oz|lb|pinch|dash)?)\s+' + RegExp.escape(common), caseSensitive: false),
            RegExp(RegExp.escape(common) + r'\s+(\d+\s*(?:tbsp|tsp|cup|cups|ml|g|kg|oz|lb|pinch|dash)?)', caseSensitive: false),
          ];
          
          for (final pattern in amountPatterns) {
            final match = pattern.firstMatch(instructionsText);
            if (match != null) {
              amount = match.group(1);
              break;
            }
          }
          
          // Capitalize first letter for display
          final displayName = common.split(' ').map((word) => 
            word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
          ).join(' ');
          
          extracted.add({
            'name': displayName,
            'amount': amount ?? 'as needed',
          });
        }
      }
    }
    
    return extracted;
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
      // Request high-quality HD image with better parameters
      final response = await SupabaseService.client.functions.invoke(
        'generate-recipe-image',
        body: {
          'prompt': prompt,
          'width': 1024,  // HD resolution
          'height': 1024, // HD resolution
          'num_outputs': 1,
          'guidance_scale': 7.5, // Higher quality
          'num_inference_steps': 50, // More steps for better quality
        },
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
  /// Uses the visual_description from the recipe for chef-quality accuracy
  String _buildImagePrompt(Recipe recipe) {
    // Use the visual description from the recipe if available
    final visualDesc = recipe.visualDescription;
    
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
    final cookingTechniques = _extractCookingTechniques(recipe.instructions);
    
    // Build the visual description section
    String visualDescriptionSection = '';
    if (visualDesc != null) {
      final descParts = <String>[];
      
      if (visualDesc.overall != null && visualDesc.overall!.isNotEmpty) {
        descParts.add('OVERALL: ${visualDesc.overall}');
      }
      
      if (visualDesc.mainElement != null) {
        final main = visualDesc.mainElement!;
        descParts.add('MAIN ELEMENT: ${main.ingredient}');
        if (main.appearance != null) descParts.add('  - Appearance: ${main.appearance}');
        if (main.portion != null) descParts.add('  - Portion: ${main.portion}');
        if (main.placement != null) descParts.add('  - Position: ${main.placement}');
      }
      
      if (visualDesc.components.isNotEmpty) {
        descParts.add('COMPONENTS:');
        for (final comp in visualDesc.components) {
          descParts.add('  - ${comp.ingredient}: ${comp.appearance ?? ""} (${comp.portion ?? ""}) ${comp.placement != null ? "at ${comp.placement}" : ""}');
        }
      }
      
      if (visualDesc.sauce != null && visualDesc.sauce!.type != null) {
        descParts.add('SAUCE: ${visualDesc.sauce!.type} - ${visualDesc.sauce!.appearance ?? ""}, ${visualDesc.sauce!.presentation ?? ""}');
      }
      
      if (visualDesc.garnishes.isNotEmpty) {
        descParts.add('GARNISHES: ${visualDesc.garnishes.join(", ")}');
      }
      
      if (visualDesc.colorPalette.isNotEmpty) {
        descParts.add('COLOR PALETTE: ${visualDesc.colorPalette.join(", ")}');
      }
      
      if (visualDesc.platingStyle != null) {
        descParts.add('PLATING STYLE: ${visualDesc.platingStyle}');
      }
      
      visualDescriptionSection = descParts.join('\n');
    }
    
    // Build comprehensive, detailed prompt
    final prompt = '''
Professional food photography, chef-quality plating, Michelin-star presentation, 8k detail.

DISH: ${recipe.title}
${recipe.description != null ? 'DESCRIPTION: ${recipe.description}' : ''}

EXACT VISUAL DESCRIPTION:
$visualDescriptionSection

INGREDIENTS IN DISH: $allIngredients
PRIMARY VISIBLE INGREDIENTS: $primaryIngredients
COOKING TECHNIQUES APPLIED: $cookingTechniques

PHOTOGRAPHY REQUIREMENTS:
- Show EXACTLY what is described in the visual description above
- Each ingredient must show the effects of its cooking method (browning, caramelization, char marks, etc.)
- Proportions must match the recipe (${recipe.servings ?? 2} servings)
- Professional restaurant plating on a clean, elegant plate
- Natural daylight, soft shadows, appetizing warm lighting
- 45-degree angle, shallow depth of field
- Clean, minimal background (slate, wood, or marble surface)
- Food must look fresh, properly cooked, and photorealistic

TECHNICAL SPECIFICATIONS:
- Style: Professional food photography, NOT illustration
- No text, labels, watermarks, people, or hands
- Natural, appetizing colors only
- Accurate representation matching the visual description
- Every visible ingredient must be from the recipe

STRICT RULES (what NOT to include):
- NO ingredients not listed in the recipe
- NO unrealistic food combinations
- NO cartoon or illustration style
- NO artificial or oversaturated colors
- NO incorrect cooking methods or textures
- NO generic stock photo appearance

This image must look like it was photographed in a professional kitchen, showing exactly what a chef would plate based on the recipe. The visual description above is the exact guide for how this dish should appear.
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
    // Build prompt with culinary intelligence
    final ingredientsStr = ingredients.join(', ');
    final parts = <String>[];
    
    if (preferences.servings > 0) {
      parts.add('${preferences.servings} servings');
    }
    if (preferences.difficulty != null) parts.add(preferences.difficulty!);
    
    // Handle cuisine(s) - support fusion recipes
    if (preferences.cuisine != null) {
      if (preferences.cuisineInfluences.isNotEmpty) {
        // Fusion recipe: primary cuisine with influences
        final allCuisines = [preferences.cuisine!, ...preferences.cuisineInfluences];
        parts.add('${allCuisines.join('-')} fusion');
      } else {
        // Single cuisine
        parts.add(preferences.cuisine!);
      }
    } else if (preferences.cuisineInfluences.isNotEmpty) {
      // Only influences, no primary (shouldn't happen but handle gracefully)
      parts.add('${preferences.cuisineInfluences.join('-')} fusion');
    }
    
    if (preferences.dietaryRestrictions.isNotEmpty) {
      parts.add(preferences.dietaryRestrictions.join(', '));
    }
    if (preferences.maxTimeMinutes != null) {
      parts.add('max ${preferences.maxTimeMinutes}min');
    }
    
    final prefsStr = parts.isEmpty ? '' : ' Preferences: ${parts.join(', ')}.';
    
    return '''Create a chef-quality recipe using these ingredients: $ingredientsStr.$prefsStr

You are a professional chef. Create a dish with:
- Balanced gustatory profile (sweet, salty, sour, bitter, umami)
- Textural variety (crispy, creamy, tender contrasts)
- Visual appeal worthy of a fine dining presentation
- Proper technique for each ingredient

CRITICAL REQUIREMENTS:
1. The ingredients list MUST include ALL ingredients mentioned in the instructions (salt, pepper, oil, spices, etc.)
2. Every ingredient used in any step must be in the ingredients list with proper amounts in METRIC units (grams, ml)
3. Include all seasonings, condiments, and cooking ingredients
4. Think about how each ingredient will look AFTER its cooking method

VISUAL DESCRIPTION REQUIREMENTS (for the visual_description field):
Create a detailed, precise description of exactly how this dish looks when plated, as if describing to a food photographer:
- Describe EACH ingredient's appearance AFTER cooking (color changes, texture, browning, caramelization)
- Specify the RELATIVE SIZE/AMOUNT of each component visually (e.g., "3 medallions of chicken", "a pool of sauce")
- Describe the ARRANGEMENT on the plate (center, scattered, stacked, layered)
- Note any FINISHING touches (drizzle, dust, garnish placement)
- Mention the COLOR PALETTE and CONTRASTS
- Describe any SAUCE presentation (pool, drizzle, dots, smear)
This description will be used to generate the dish image, so accuracy is essential.

Return JSON:
{
  "title": string,
  "description": string (1-2 sentences about taste/experience),
  "visual_description": {
    "overall": string (one sentence overview of the plated dish),
    "main_element": {
      "ingredient": string,
      "appearance": string (how it looks after cooking: color, texture, shape),
      "portion": string (size/amount visible),
      "position": string (where on plate)
    },
    "components": [
      {
        "ingredient": string,
        "appearance": string,
        "portion": string,
        "placement": string
      }
    ],
    "sauce": {
      "type": string or null,
      "appearance": string,
      "presentation": string (pool, drizzle, dots, smear)
    },
    "garnishes": [string],
    "color_palette": [string],
    "plating_style": string (rustic, fine-dining, family-style, etc.)
  },
  "ingredients": [{"name": string, "amount": string}],
  "instructions": [string] (4-6 steps, include technique details),
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
