import 'package:flutter/foundation.dart';
import '../models/recipe_model.dart';
import '../services/recipe_service.dart';

class RecipeProvider with ChangeNotifier {
  final RecipeService _recipeService = RecipeService();

  List<RecipeModel> _recipes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RecipeModel> get recipes => _recipes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecipes({String? search, String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _recipes = await _recipeService.getRecipes(search: search, category: category);
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createRecipe({
    required String token,
    required String title,
    required String category,
    required String imageUrl,
    required List<String> ingredients,
    required String instructions,
    required int cookingTime,
    required String difficulty,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    bool success = false;
    try {
      await _recipeService.createRecipe(
        token: token,
        title: title,
        category: category,
        imageUrl: imageUrl,
        ingredients: ingredients,
        instructions: instructions,
        cookingTime: cookingTime,
        difficulty: difficulty,
      );
      success = true;
      await fetchRecipes(); // refresh feed so the new recipe shows up immediately
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateRecipe(String token, String recipeId, Map<String, dynamic> updates) async {
    _isLoading = true;
    notifyListeners();

    bool success = false;
    try {
      await _recipeService.updateRecipe(token: token, recipeId: recipeId, updates: updates);
      success = true;
      await fetchRecipes();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteRecipe(String token, String recipeId) async {
    _isLoading = true;
    notifyListeners();

    bool success = false;
    try {
      await _recipeService.deleteRecipe(recipeId, token);
      success = true;
      await fetchRecipes();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}