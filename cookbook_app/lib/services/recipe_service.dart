import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../models/ai_suggestion_model.dart';
import '../utils/constants.dart';

class RecipeService {
  Future<List<RecipeModel>> getRecipes({String? search, String? category}) async {
    final queryParams = <String, String>{};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (category != null && category.isNotEmpty) {
      queryParams['category'] = category;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}/recipes')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(uri);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data as List).map((item) => RecipeModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load recipes');
    }
  }

  Future<RecipeModel> getRecipeById(String id) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/recipes/$id'));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return RecipeModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Failed to load recipe');
    }
  }

  Future<RecipeModel> updateRecipe({
    required String token,
    required String recipeId,
    required Map<String, dynamic> updates,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/recipes/$recipeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return RecipeModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Failed to update recipe');
    }
  }

  Future<void> deleteRecipe(String recipeId, String token) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/recipes/$recipeId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete recipe');
    }
  }

  Future<List<RecipeModel>> getMyRecipes(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/recipes/user/mine'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data as List).map((item) => RecipeModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load your recipes');
    }
  }

  Future<RecipeModel> createRecipe({
    required String token,
    required String title,
    required String category,
    required String imageUrl,
    required List<String> ingredients,
    required String instructions,
    required int cookingTime,
    required String difficulty,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/recipes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title,
        'category': category,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
        'instructions': instructions,
        'cookingTime': cookingTime,
        'difficulty': difficulty,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return RecipeModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Failed to create recipe');
    }
  }

  Future<List<AiSuggestionModel>> getRecipeSuggestions({
    required String token,
    required List<String> ingredients,
    String? instructions,
    String? dietaryPreferences,
    int? maxTime,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/recipes/suggestions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ingredients': ingredients,
        if (instructions != null) 'instructions': instructions,
        if (dietaryPreferences != null) 'dietaryPreferences': dietaryPreferences,
        if (maxTime != null) 'maxTime': maxTime,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['recipes'] as List)
          .map((item) => AiSuggestionModel.fromJson(item))
          .toList();
    } else {
      throw Exception(data['message'] ?? 'Failed to generate suggestions');
    }
  }
}