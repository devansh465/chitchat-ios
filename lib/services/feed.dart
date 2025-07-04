import 'dart:convert';
import 'package:chitchat/appstate/variables.dart';
import 'package:chitchat/services/user.dart';
import 'package:http/http.dart' as http;

class FeedService {
  static String baseUrl =
      AppVariables.get<String>('baseurl')!.trim() ?? 'http://localhost:3000';

  /// Fetch paginated feed posts
  static Future<Map<String, dynamic>> fetchFeed({
    int page = 1,
    int limit = 20,
    String? lastSeenPostId,
    String? invalidateCache = 'false',
  }) async {
    try {
      String? token = await UserService.getAccessToken();

      // Construct query parameters
      final queryParams = {
        "page": page.toString(),
        "limit": limit.toString(),
        if (lastSeenPostId != null) "lastSeenPostId": lastSeenPostId,
        if (invalidateCache != null) "invalidate": invalidateCache
      };

      final uri =
          Uri.parse('$baseUrl/feed').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          "Authorization": "Bearer $token", // Assuming Bearer token auth
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "posts": data["posts"], // List of posts
          "hasMore": data["hasMore"], // Indicates if more posts are available
        };
      } else {
        throw Exception("Failed to load feed: ${response.body}");
      }
    } catch (e) {
      throw Exception("Error fetching feed: $e");
    }
  }
}
