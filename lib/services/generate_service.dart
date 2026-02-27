import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/env.dart';
import '../shared/models/recipe.dart';
import 'ingredients_service.dart';
import 'supabase_service.dart';

/// Simplified recipe generation - LLM + optional image
class GenerateService {
  GenerateService._();
  static final GenerateService instance = GenerateService._();

  static const _chatEndpoint = 'https://api.openai.com/v1/chat/completions';

  Future<Recipe> generateRecipe(List<String> ingredients) async {
    if (Env.openAiApiKey.startsWith('YOUR_') || Env.openAiApiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    final prompt = _buildPrompt(ingredients);

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
            'content': 'You are a creative Michelin-star chef. Return ONLY valid JSON, no markdown.',
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.8,
        'max_tokens': 1500,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Recipe generation failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content'];
    if (content == null) throw Exception('No recipe in response');

    String cleaned = content.toString().trim();
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.first.contains('json')) lines.removeAt(0);
      if (lines.isNotEmpty && lines.last.trim() == '```') lines.removeLast();
      cleaned = lines.join('\n').trim();
    }

    final recipeJson = jsonDecode(cleaned) as Map<String, dynamic>;
    var recipe = Recipe.fromJson(_normalizeRecipeJson(recipeJson));

    final imageMap = await IngredientsService.instance.getIngredientNameToImageMap();
    recipe = recipe.copyWith(
      ingredients: recipe.ingredients.map((ing) {
        final url = _matchImageUrl(ing.name, imageMap);
        return url != null ? ing.copyWith(imageUrl: url) : ing;
      }).toList(),
    );

    final imageUrl = await _generateImage(recipe);
    return recipe.copyWith(imageUrl: imageUrl ?? recipe.imageUrl);
  }

  /// Match recipe ingredient name to DB image (exact lowercase, or recipe contains DB name)
  String? _matchImageUrl(String name, Map<String, String> imageMap) {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return null;
    if (imageMap.containsKey(n)) return imageMap[n];
    String? best;
    int bestLen = 0;
    for (final entry in imageMap.entries) {
      if (entry.key.length > bestLen && n.contains(entry.key)) {
        best = entry.value;
        bestLen = entry.key.length;
      }
    }
    return best;
  }

  String _buildPrompt(List<String> ingredients) {
    final ingList = ingredients.join(', ');
    return '''
Create a SURPRISING, chef-quality recipe using these ingredients: $ingList

Be creative - combine them in unexpected but delicious ways. Think Michelin-star innovation.
You may add common pantry staples (salt, pepper, oil, butter, etc.) as needed.

Return JSON with this exact structure:
{
  "title": "Creative dish name",
  "description": "1-2 sentence enticing description",
  "ingredients": [
    {"name": "Ingredient", "amount": "quantity", "is_user_provided": true/false}
  ],
  "instructions": ["Step 1...", "Step 2...", ...],
  "prep_time": minutes as int,
  "cook_time": minutes as int,
  "servings": number,
  "difficulty": "Easy|Medium|Hard",
  "cuisine": "e.g. Fusion, Italian",
  "dietary_tags": ["vegetarian"] or []
}

Mark is_user_provided: true only for ingredients the user provided. For pantry staples use false.
''';
  }

  Map<String, dynamic> _normalizeRecipeJson(Map<String, dynamic> json) {
    return {
      'title': json['title'] ?? 'Chef\'s Creation',
      'description': json['description'],
      'ingredients': (json['ingredients'] as List<dynamic>? ?? [])
          .map((e) => {
                'name': (e as Map)['name'] ?? '',
                'amount': (e['amount'] ?? 'as needed').toString(),
                'is_user_provided': e['is_user_provided'] ?? false,
              })
          .toList(),
      'instructions': (json['instructions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      'prep_time': json['prep_time'],
      'cook_time': json['cook_time'],
      'servings': json['servings'],
      'difficulty': json['difficulty'],
      'cuisine': json['cuisine'],
      'dietary_tags': json['dietary_tags'] ?? [],
    };
  }

  Future<String?> _generateImage(Recipe recipe) async {
    try {
      final ingredients = recipe.ingredients.take(5).map((i) => i.name).join(', ');
      final prompt = 'Editorial food photography, modern food blog style: ${recipe.title}. '
          '${recipe.description ?? ''} '
          'Ingredients: $ingredients. '
          'Contemporary restaurant plating, soft natural daylight, warm golden tones, '
          '40-degree overhead angle, shallow depth of field, artisan ceramic plate on light wood, '
          'photorealistic, magazine-quality, fresh and appetizing. '
          'CRITICAL: Always realistic – no hallucinations, no invented elements. Only depict ingredients listed above.';

      final response = await SupabaseService.client.functions.invoke(
        'generate-recipe-image',
        body: {
          'prompt': prompt,
          'width': 1024,
          'height': 1024,
        },
      );

      if (response.status != 200) return null;
      final data = response.data;
      if (data is Map) return data['imageUrl'] as String?;
      if (data is String) return data;
      return null;
    } catch (_) {
      return null;
    }
  }
}
