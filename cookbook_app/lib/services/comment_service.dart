import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comment_model.dart';
import '../utils/constants.dart';

class CommentService {
  Future<List<CommentModel>> getComments(String recipeId) async {
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/comments/$recipeId'));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data as List).map((item) => CommentModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<CommentModel> addComment(String recipeId, String text, String token) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/comments/$recipeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return CommentModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Failed to add comment');
    }
  }

  Future<void> deleteComment(String commentId, String token) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/comments/$commentId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to delete comment');
    }
  }
}