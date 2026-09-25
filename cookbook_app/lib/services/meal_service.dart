import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/meal_model.dart';

class MealService {
  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  Future<List<MealModel>> searchMeals(String query) async {
    final response = await http.get(Uri.parse('$_baseUrl/search.php?s=$query'));
    final data = jsonDecode(response.body);

    if (data['meals'] == null) return [];
    return (data['meals'] as List).map((m) => MealModel.fromDetailJson(m)).toList();
  }

  Future<List<MealModel>> filterByCategory(String category) async {
    final response = await http.get(Uri.parse('$_baseUrl/filter.php?c=$category'));
    final data = jsonDecode(response.body);

    if (data['meals'] == null) return [];
    return (data['meals'] as List).map((m) => MealModel.fromSummaryJson(m)).toList();
  }

  Future<MealModel> getMealById(String id) async {
    final response = await http.get(Uri.parse('$_baseUrl/lookup.php?i=$id'));
    final data = jsonDecode(response.body);
    return MealModel.fromDetailJson(data['meals'][0]);
  }
}