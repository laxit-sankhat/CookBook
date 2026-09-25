/**
 * ai_suggestion_provider.dart
 * 
 * PURPOSE:
 * This acts as the "State Management" for the AI Recipe screen.
 * It handles the loading states (true/false) and stores the results
 * so the UI can just "listen" to this file and automatically update.
 */
import 'package:flutter/material.dart';
import '../models/ai_suggestion_model.dart';
import '../services/recipe_service.dart';

class AiSuggestionProvider with ChangeNotifier {
  final RecipeService _recipeService = RecipeService();
  
  List<AiSuggestionModel> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  List<AiSuggestionModel> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSuggestions({
    required String token,
    required List<String> ingredients,
    String? instructions,
    String? dietaryPreferences,
    int? maxTime,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suggestions = await _recipeService.getRecipeSuggestions(
        token: token,
        ingredients: ingredients,
        instructions: instructions,
        dietaryPreferences: dietaryPreferences,
        maxTime: maxTime,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _suggestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSuggestions() {
    _suggestions = [];
    _error = null;
    notifyListeners();
  }
}
