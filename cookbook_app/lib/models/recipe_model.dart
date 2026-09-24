class RecipeModel {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final List<String> ingredients;
  final String instructions;
  final int cookingTime;
  final String difficulty;
  final String createdById;
  final String createdByName;
  final int likesCount;
  final int commentsCount;

  RecipeModel({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.ingredients,
    required this.instructions,
    required this.cookingTime,
    required this.difficulty,
    required this.createdById,
    required this.createdByName,
    required this.likesCount,
    required this.commentsCount,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['_id'],
      title: json['title'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: json['instructions'],
      cookingTime: json['cookingTime'],
      difficulty: json['difficulty'],
      createdById: json['createdBy']['_id'],
      createdByName: json['createdBy']['name'],
      likesCount: json['likesCount'],
      commentsCount: json['commentsCount'],
    );
  }
}