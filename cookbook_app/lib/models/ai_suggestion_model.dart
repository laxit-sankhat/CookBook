/**
 * ai_suggestion_model.dart
 * 
 * PURPOSE:
 * This is our "Data Transfer Object" (DTO). 
 * It perfectly mirrors the clean JSON data returned by our backend's AI Parser.
 * Having a strict model like this prevents app crashes due to missing or null data.
 */
class AiSuggestionModel {
  final String name;
  final String description;
  final int matchPercentage;
  final List<String> availableIngredients;
  final List<String> missingIngredients;
  final int estimatedCookingTime;
  final String difficulty;
  final List<String> instructions;

  AiSuggestionModel({
    required this.name,
    required this.description,
    required this.matchPercentage,
    required this.availableIngredients,
    required this.missingIngredients,
    required this.estimatedCookingTime,
    required this.difficulty,
    required this.instructions,
  });

  factory AiSuggestionModel.fromJson(Map<String, dynamic> json) {
    return AiSuggestionModel(
      name: json['name'] ?? 'Unknown',
      description: json['description'] ?? '',
      matchPercentage: json['matchPercentage'] ?? 0,
      availableIngredients: List<String>.from(json['availableIngredients'] ?? []),
      missingIngredients: List<String>.from(json['missingIngredients'] ?? []),
      estimatedCookingTime: json['estimatedCookingTime'] ?? 0,
      difficulty: json['difficulty'] ?? 'Medium',
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }
}
