import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/env.dart';
import '../shared/models/recipe.dart';
import '../shared/models/recipe_preferences.dart';
import '../shared/models/recognized_ingredient.dart';
import '../shared/models/ingredient.dart';
import 'supabase_service.dart';
import 'culinary_intelligence_service.dart';
import 'cooking_methods_service.dart';

/// OpenAI service for recipe generation
class OpenAIService {
  OpenAIService._();
  static final OpenAIService instance = OpenAIService._();

  static const _chatEndpoint = 'https://api.openai.com/v1/chat/completions';

  Future<Recipe> generateRecipe({
    required List<String> ingredients,
    required RecipePreferences preferences,
    Map<String, String>? cookingMethods,
  }) async {
    if (Env.openAiApiKey.startsWith('YOUR_')) {
      throw Exception('OpenAI API key is not set. Update Env.openAiApiKey.');
    }

    // Fetch ingredient data with cooking methods guidance
    final cookingGuidance = await _buildCookingGuidance(
      ingredients,
      cookingMethods: cookingMethods,
    );
    final prompt = await _buildPrompt(ingredients, preferences, cookingGuidance, cookingMethods);

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
    Map<String, String>? cookingMethods,
  }) async {
    final prompt = _buildImagePrompt(recipe, cookingMethods: cookingMethods);

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
  String _buildImagePrompt(Recipe recipe, {Map<String, String>? cookingMethods}) {
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
    
    // Add cooking method effects to visual description
    String cookingMethodEffects = '';
    if (cookingMethods != null && cookingMethods.isNotEmpty) {
      final effects = <String>[];
      for (final entry in cookingMethods.entries) {
        if (entry.value == 'Raw' || entry.value.isEmpty) continue;
        
        switch (entry.value.toLowerCase()) {
          case 'roasting':
            effects.add('${entry.key}: golden brown, caramelized edges, rich color, tender interior');
            break;
          case 'pan-frying':
            effects.add('${entry.key}: crispy golden sear, browned exterior, juicy interior');
            break;
          case 'grilling':
            effects.add('${entry.key}: char marks, smoky appearance, grill lines');
            break;
          case 'sautéing':
            effects.add('${entry.key}: lightly browned, glossy surface, aromatic');
            break;
          case 'braising':
            effects.add('${entry.key}: deep brown, fork-tender, rich sauce coating');
            break;
          case 'steaming':
            effects.add('${entry.key}: vibrant color, moist, tender texture');
            break;
          case 'boiling':
            effects.add('${entry.key}: soft texture, bright color, clean appearance');
            break;
          default:
            effects.add('${entry.key}: prepared by ${entry.value}');
        }
      }
      if (effects.isNotEmpty) {
        cookingMethodEffects = '\n\nCOOKING METHOD EFFECTS:\n${effects.join('\n')}';
      }
    }
    
    // Build the visual description section
    String visualDescriptionSection = '';
    if (visualDesc != null) {
      // Add cooking method effects to visual description
      visualDescriptionSection += cookingMethodEffects;
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
      
      visualDescriptionSection = descParts.join('\n') + cookingMethodEffects;
    }
    
    // Build comprehensive, detailed prompt - modern editorial food blog/restaurant aesthetic
    final prompt = '''
Editorial food photography, modern restaurant website quality, premium food blog aesthetic. 
CRITICAL: Always realistic – photorealistic, magazine-quality image. No hallucinations: only depict ingredients and elements that exist in this recipe. No invented textures, shapes, or fictional elements.

DISH: ${recipe.title}
${recipe.description != null ? 'DESCRIPTION: ${recipe.description}' : ''}

EXACT VISUAL DESCRIPTION:
$visualDescriptionSection

INGREDIENTS IN DISH: $allIngredients
PRIMARY VISIBLE INGREDIENTS: $primaryIngredients
COOKING TECHNIQUES APPLIED: $cookingTechniques

PHOTOGRAPHY STYLE (modern, contemporary):
- Editorial food photography as seen on Bon Appétit, Saveur, or high-end restaurant websites
- Soft natural daylight with warm golden undertones, diffused through a window
- 40-degree overhead angle or 3/4 view - dynamic, appetizing perspective
- Shallow depth of field, creamy bokeh, focus on the dish
- Contemporary plating: artisan ceramics, light oak wood board, or warm stone surface
- Organic textures: linen napkin, fresh herbs as garnish, natural negative space
- Warm color grading, natural saturation - inviting and appetizing
- Food must look freshly prepared, vibrant, properly cooked
- Show cooking method effects: caramelization, char marks, glossy surfaces where appropriate
- Proportions for ${recipe.servings ?? 2} servings

SCENE SETTING:
- Clean, minimal background - light wood, terracotta, warm grey stone, or soft marble
- No cluttered or dated elements
- Sophisticated but approachable - food that looks both impressive and attainable
- Photorealistic, high resolution

STRICT RULES:
- NO text, labels, watermarks, people, hands, or cutlery in frame
- NO cartoon, illustration, or AI-artifact style
- NO oversaturated or artificial colors
- NO ingredients not in the recipe – no hallucinations, no invented elements
- NO 90s stock-photo aesthetic (sterile white plates, harsh flash)
- ONLY ingredients from this recipe, accurately represented – strictly realistic, nothing fictional
- Image must always look realistic and natural – no surreal, fantastical or AI-hallucinated elements

The image should look like a professional food stylist and photographer created it for a contemporary food blog or upscale restaurant menu. Fresh, beautiful, modern, and always realistic.
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
  // ignore: unused_element
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
  // ignore: unused_element
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
  // ignore: unused_element
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

  /// Build cooking guidance for ingredients based on scientific data
  Future<String> _buildCookingGuidance(
    List<String> ingredientNames, {
    Map<String, String>? cookingMethods,
  }) async {
    final guidance = <String>[];
    
    // Get ingredient data from database
    final allIngredients = await CulinaryIntelligenceService.instance.getAllIngredients();
    final cookingService = CookingMethodsService.instance;
    
    for (final name in ingredientNames) {
      // Find ingredient in database
      final ingredient = allIngredients.firstWhere(
        (i) => i.name.toLowerCase() == name.toLowerCase() ||
              i.nameNl?.toLowerCase() == name.toLowerCase(),
        orElse: () => Ingredient(id: '', name: name),
      );
      
      if (ingredient.id.isEmpty) {
        // Ingredient not found, skip
        continue;
      }
      
      // Use provided cooking method or get optimal
      final methodName = cookingMethods?[name] ?? 
          (await cookingService.getOptimalCookingMethod(ingredient.id))?.nameEn ?? 'Raw';
      
      // Get cooking guidance
      final guidanceText = await cookingService.getCookingGuidanceForIngredient(
        ingredient,
        methodName,
      );
      
      guidance.add(guidanceText);
    }
    
    return guidance.join('\n\n');
  }

  Future<String> _buildPrompt(
    List<String> ingredients,
    RecipePreferences preferences,
    String cookingGuidance,
    Map<String, String>? cookingMethods,
  ) async {
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
    
    // Build cooking guidance section
    final cookingGuidanceSection = cookingGuidance.isNotEmpty
        ? '''

INGREDIENT COOKING GUIDANCE (Based on culinary science - Harold McGee, Hervé This):
Follow these scientific principles for each ingredient:
$cookingGuidance

IMPORTANT: Use the recommended cooking methods and temperatures. Consider how each cooking method transforms the ingredient:
- Maillard reaction (140-165°C): Creates umami, browning, roasted aromas
- Caramelization (160-180°C): Develops sweetness and golden color
- Moist heat methods: Preserve structure and nutrients better
- Dry heat methods: Create browning and develop complex flavors
'''
        : '';
    
    // Get visual presentation analysis
    final analysis = await CulinaryIntelligenceService.instance.analyzeComposition(
      ingredients,
      cookingMethods: cookingMethods,
    );
    
    // Build molecule type analysis
    final moleculeTypes = <String, int>{};
    for (final ingredient in analysis.ingredients) {
      final type = ingredient.moleculeType.toString().split('.').last;
      moleculeTypes[type] = (moleculeTypes[type] ?? 0) + 1;
    }
    final moleculeGuidance = moleculeTypes.isNotEmpty
        ? '''

MOLECULE TYPE DISTRIBUTION:
${moleculeTypes.entries.map((e) => '- ${e.key}: ${e.value} ingredient(s)').join('\n')}

UNDERSTANDING MOLECULE TYPES:
- Water: Adds moisture, freshness, and helps dissolve flavors. High-water ingredients (tomatoes, cucumbers) add juiciness.
- Fat: Carries fat-soluble flavors, creates richness and mouthfeel. Essential for browning and flavor release.
- Carbohydrates: Provide structure, energy, and can caramelize. Starches (potatoes, rice) are filling carriers.
- Protein: Provides umami, satisfaction, and structure. Proteins benefit from Maillard reaction for depth.

Consider how each molecule type contributes to the dish's balance and satisfaction.
'''
        : '';
    
    // Build aroma completeness analysis
    final allAromas = <String>{};
    for (final ingredient in analysis.ingredients) {
      allAromas.addAll(ingredient.aromaCategories);
    }
    final aromaGuidance = allAromas.isNotEmpty
        ? '''

AROMA COMPLEXITY:
Aroma categories present: ${allAromas.join(', ')}
${allAromas.length >= 3 ? '✓ Good aromatic complexity' : '⚠ Consider adding ingredients with different aroma profiles for more depth'}

Aromas contribute to the dish's overall flavor experience. A complex aromatic profile (3+ distinct categories) creates a more interesting and complete dish.
'''
        : '';
    
    // Build mouthfeel variety analysis
    final mouthfeels = <String>{};
    for (final ingredient in analysis.ingredients) {
      mouthfeels.add(ingredient.mouthfeel.toString().split('.').last);
    }
    final mouthfeelGuidance = mouthfeels.length >= 2
        ? '✓ Good mouthfeel variety (${mouthfeels.length} different types)'
        : '⚠ Consider adding ingredients with different mouthfeels for textural interest';
    
    final visualGuidance = analysis.visualPresentation != null
        ? '''

VISUAL PRESENTATION GUIDANCE:
Color Palette: ${analysis.visualPresentation!.colorPalette.join(', ')}
${analysis.visualPresentation!.hasColorContrast ? '✓ Good color contrast' : '⚠ Add more color variety'}
${analysis.visualPresentation!.hasOddNumberElements ? '✓ Odd number of elements (good for plating)' : '⚠ Consider odd number of elements (3, 5, or 7)'}
${analysis.visualPresentation!.hasGarnishPotential ? '✓ Has garnish potential' : '⚠ Add finishing touches (herbs, oils)'}
${analysis.visualPresentation!.suggestions.isNotEmpty ? '\nSuggestions:\n${analysis.visualPresentation!.suggestions.map((s) => '- $s').join('\n')}' : ''}

PLATING PRINCIPLES:
- Use odd numbers (3, 5, or 7 elements) for visual appeal
- Create height and depth on the plate
- Use 30-40% negative space
- Position carrier as focal point (slightly off-center, rule of thirds)
- Strategic sauce placement (drizzle, dots, pool, or smear)
- Every garnish must be edible and add flavor
'''
        : '';
    
    return '''Create a chef-quality recipe using these ingredients: $ingredientsStr.$prefsStr$cookingGuidanceSection$moleculeGuidance$aromaGuidance

MOUTHFEEL VARIETY: $mouthfeelGuidance

$visualGuidance

You are a professional chef. Create a dish with:
- Balanced gustatory profile (sweet, salty, sour, bitter, umami)
- Textural variety (crispy, creamy, tender contrasts)
- Complex aromatic profile (multiple aroma categories)
- Varied mouthfeel (refreshing, rich, creamy, etc.)
- Visual appeal worthy of a fine dining presentation
- Proper technique for each ingredient based on scientific cooking principles

CRITICAL REQUIREMENTS:
1. The ingredients list MUST include ALL ingredients mentioned in the instructions (salt, pepper, oil, spices, etc.)
2. Every ingredient used in any step must be in the ingredients list with proper amounts in METRIC units (grams, ml)
3. Include all seasonings, condiments, and cooking ingredients
4. Use the cooking methods and techniques recommended in the guidance above
5. Think about how each ingredient will look AFTER its cooking method (browning, caramelization, texture changes)

COOKING METHOD SELECTION:
- Choose cooking methods that maximize flavor development (Maillard, caramelization)
- Consider texture goals: crispy vs tender, crunchy vs soft
- Match cooking method to ingredient type (protein, vegetable, starch)
- Use optimal temperatures and times from the guidance above

VISUAL DESCRIPTION REQUIREMENTS (for the visual_description field):
Create a detailed, precise description for MODERN editorial food photography (think Bon Appétit, high-end restaurant menus):
- Describe EACH ingredient's appearance AFTER cooking (color, texture, browning, caramelization, glossy surfaces)
- Specify RELATIVE SIZE/AMOUNT (e.g., "3 medallions", "generous pool of sauce")
- Describe ARRANGEMENT: contemporary plating with intentional negative space, focal point, visual flow
- FINISHING touches: fresh herb garnish, microgreens, edible flowers, olive oil drizzle
- COLOR PALETTE: vibrant but natural, warm tones, appetizing contrasts
- SAUCE presentation: artistic pool, elegant drizzle, or modern smear - avoid dated "sauce on the side"
- plating_style: use "contemporary", "artisan", "farm-to-table", "rustic-elegant", or "minimalist" - avoid "fine-dining" (can feel stiff) or "traditional"
- Emphasize fresh, vibrant, photogenic appearance
This feeds the image generator - accuracy and modern aesthetic matter.

Return JSON:
{
  "title": string,
  "description": string (1-2 sentences about taste/experience),
  "visual_description": {
    "overall": string (one sentence overview of the plated dish),
    "main_element": {
      "ingredient": string,
      "appearance": string (how it looks after cooking: color, texture, shape, browning),
      "portion": string (size/amount visible),
      "position": string (where on plate)
    },
    "components": [
      {
        "ingredient": string,
        "appearance": string (include cooking method effects),
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
  "instructions": [string] (4-6 steps, include technique details and cooking methods),
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
