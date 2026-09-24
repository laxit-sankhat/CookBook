import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/constants.dart';

class UploadService {
  Future<String> uploadImage(File imageFile, String token) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeSubtype = (extension == 'jpg') ? 'jpeg' : extension;

    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', mimeSubtype),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['imageUrl'];
    } else {
      throw Exception(data['message'] ?? 'Image upload failed');
    }
  }
}