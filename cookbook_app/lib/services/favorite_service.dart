import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../utils/constants.dart';

class FavoriteService {
  Future<bool> checkFavoriteStatus(String recipeId, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/favorites/status/$recipeId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['favorited'];
    } else {
      throw Exception('Failed to check favorite status');
    }
  }

  Future<bool> toggleFavorite(String recipeId, String token) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/favorites/$recipeId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['favorited'];
    } else {
      throw Exception(data['message'] ?? 'Failed to toggle favorite');
    }
  }

  Future<List<RecipeModel>> getFavorites(String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/favorites'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data as List).map((item) => RecipeModel.fromJson(item['recipe'])).toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }
}