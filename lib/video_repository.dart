import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoRepository {
  final String apiUrl = "https://67c95a960acf98d07089e52b.mockapi.io/videos";

  Future<List<String>> getVideos() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty && data[0]["videos"] is List) {
          return List<String>.from(data[0]["videos"]);
        } else {
          throw Exception("Invalid data format");
        }
      } else {
        throw Exception("Failed to load videos: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching videos: $e");
      return [];
    }
  }
}
