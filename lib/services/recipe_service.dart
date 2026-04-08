import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

class RecipeService {
  static const String _apiKey = 'fae0d4dd4c324b49bdc238f690d13c2b';
  static const String _baseUrl = 'https://api.spoonacular.com/recipes';

  // Spoonacular intolerances parameter mapping
  static const Map<String, String> _allergenToIntolerance = {
    'Gluten': 'gluten',
    'Dairy': 'dairy',
    'Eggs': 'egg',
    'Peanuts': 'peanut',
    'Tree Nuts': 'tree nut',
    'Fish': 'seafood',
    'Shellfish': 'shellfish',
    'Soy': 'soy',
    'Sesame': 'sesame',
    'Sulfites': 'sulfite',
    'Gluten-Free': 'gluten',
    'Dairy-Free': 'dairy',
  };

  Future<List<Recipe>> getRecipesByIngredients(
    List<String> ingredients, {
    List<String> allergens = const [],
    List<String> dietary = const [],
  }) async {
    final ingredientString = ingredients.join(',');

    // Build intolerances from allergens + dietary
    final allRestrictions = [...allergens, ...dietary];
    final intolerances = allRestrictions
        .where((a) => _allergenToIntolerance.containsKey(a))
        .map((a) => _allergenToIntolerance[a]!)
        .join(',');

    // Random ranking (1 = maximise used, 2 = minimise missed)
    // Alternating gives variety on refresh
    final ranking = Random().nextBool() ? 1 : 2;

    try {
      if (intolerances.isNotEmpty) {
        // MUST use complexSearch for allergens. 
        // Note: fillIngredients=true breaks complexSearch on Spoonacular's free tier, so we omit it.
        final url =
            '$_baseUrl/complexSearch?includeIngredients=$ingredientString'
            '&intolerances=$intolerances'
            '&number=10'
            '&sort=random'
            '&apiKey=$_apiKey';

        debugPrint('Recipe URL (complex): $url');
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          return results.map((json) => Recipe.fromComplexJson(json, true)).toList();
        } else {
          throw Exception('Failed to fetch recipes (status ${response.statusCode})');
        }
      }

      // Default: findByIngredients (better ingredient matching when no allergens present)
      final url =
          '$_baseUrl/findByIngredients?ingredients=$ingredientString'
          '&number=10'
          '&ranking=$ranking'
          '&ignorePantry=true'
          '&apiKey=$_apiKey';

      debugPrint('Recipe URL (find): $url');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Recipe.fromComplexJson(json, false)).toList();
      } else {
        throw Exception('Failed to fetch recipes (status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to fetch recipes: $e');
    }
  }

  Future<RecipeDetail> getRecipeDetail(int id) async {
    final url = Uri.parse(
        '$_baseUrl/$id/information?includeNutrition=false&apiKey=$_apiKey');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return RecipeDetail.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch recipe details');
    }
  }
}

// ── DATA MODELS ──

class Recipe {
  final int id;
  final String title;
  final String image;
  final int usedIngredientCount;
  final int missedIngredientCount;
  final List<String> usedIngredients;
  final List<String> missedIngredients;

  Recipe({
    required this.id,
    required this.title,
    required this.image,
    required this.usedIngredientCount,
    required this.missedIngredientCount,
    required this.usedIngredients,
    required this.missedIngredients,
  });

  // Handles both findByIngredients and complexSearch response formats
  factory Recipe.fromComplexJson(Map<String, dynamic> json, bool isComplex) {
    if (isComplex) {
      return Recipe(
        id: json['id'],
        title: json['title'],
        image: json['image'] ?? '',
        usedIngredientCount: 0,
        missedIngredientCount: 0,
        usedIngredients: [],
        missedIngredients: [],
      );
    }
    return Recipe(
      id: json['id'],
      title: json['title'],
      image: json['image'] ?? '',
      usedIngredientCount: json['usedIngredientCount'] ?? 0,
      missedIngredientCount: json['missedIngredientCount'] ?? 0,
      usedIngredients: (json['usedIngredients'] as List? ?? [])
          .map((i) => i['name'].toString())
          .toList(),
      missedIngredients: (json['missedIngredients'] as List? ?? [])
          .map((i) => i['name'].toString())
          .toList(),
    );
  }
}

class RecipeDetail {
  final int id;
  final String title;
  final String image;
  final int readyInMinutes;
  final int servings;
  final String summary;
  final List<String> ingredients;
  final List<String> steps;

  RecipeDetail({
    required this.id,
    required this.title,
    required this.image,
    required this.readyInMinutes,
    required this.servings,
    required this.summary,
    required this.ingredients,
    required this.steps,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    final ingredients = (json['extendedIngredients'] as List? ?? [])
        .map((i) => '${i['amount']} ${i['unit']} ${i['name']}'.trim())
        .toList();

    final steps = <String>[];
    final analyzedInstructions =
        json['analyzedInstructions'] as List? ?? [];
    if (analyzedInstructions.isNotEmpty) {
      final stepsList =
          analyzedInstructions[0]['steps'] as List? ?? [];
      for (final step in stepsList) {
        steps.add(step['step'].toString());
      }
    }

    return RecipeDetail(
      id: json['id'],
      title: json['title'],
      image: json['image'] ?? '',
      readyInMinutes: json['readyInMinutes'] ?? 0,
      servings: json['servings'] ?? 0,
      summary: json['summary'] ?? '',
      ingredients: ingredients.cast<String>(),
      steps: steps,
    );
  }
}