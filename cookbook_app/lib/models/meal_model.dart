class MealModel {
  final String id;
  final String name;
  final String thumbnail;
  final String? category;
  final String? area;
  final String? instructions;
  final List<String> ingredients;

  MealModel({
    required this.id,
    required this.name,
    required this.thumbnail,
    this.category,
    this.area,
    this.instructions,
    this.ingredients = const [],
  });

  // Used for search/filter results — TheMealDB gives limited fields here
  factory MealModel.fromSummaryJson(Map<String, dynamic> json) {
    return MealModel(
      id: json['idMeal'],
      name: json['strMeal'],
      thumbnail: json['strMealThumb'],
    );
  }

  // Used for full detail lookup — includes everything
  factory MealModel.fromDetailJson(Map<String, dynamic> json) {
    List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ingredient = json['strIngredient$i'];
      final measure = json['strMeasure$i'];
      if (ingredient != null && ingredient.toString().trim().isNotEmpty) {
        ingredients.add('$ingredient - ${measure ?? ''}'.trim());
      }
    }

    return MealModel(
      id: json['idMeal'],
      name: json['strMeal'],
      thumbnail: json['strMealThumb'],
      category: json['strCategory'],
      area: json['strArea'],
      instructions: json['strInstructions'],
      ingredients: ingredients,
    );
  }
}