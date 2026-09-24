import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class LikeService {
  Future<bool> checkLikeStatus(String recipeId, String token) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/likes/status/$recipeId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['liked'];
    } else {
      throw Exception('Failed to check like status');
    }
  }

  Future<Map<String, dynamic>> toggleLike(String recipeId, String token) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/likes/$recipeId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data; // { liked: bool, likesCount: int }
    } else {
      throw Exception(data['message'] ?? 'Failed to toggle like');
    }
  }
}