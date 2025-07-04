import 'dart:convert';

import 'package:chitchat/appstate/variables.dart';
import 'package:chitchat/components/friendcircle.dart';
import 'package:chitchat/services/groups.dart';
import 'package:chitchat/services/user.dart';
import 'package:http/http.dart' as http;

class WatchlistServices {
  static String baseurl =
      AppVariables.get<String>('baseurl')!.trim() ?? 'http://localhost:3000';
  static Future<Map<String, dynamic>> addToWatchList(
    String groupId,
  ) async {
    try {
      final url = Uri.parse('$baseurl/watchlist/$groupId');
      String? token = await UserService.getAccessToken();
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error':
              jsonDecode(response.body)['message'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> removeFromWatchList(
    String groupId,
  ) async {
    try {
      final url = Uri.parse('$baseurl/watchlist/$groupId');
      String? token = await UserService.getAccessToken();

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {
          'success': false,
          'error':
              jsonDecode(response.body)['message'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getWatchList(uid) async {
    try {
      final url = Uri.parse('$baseurl/watchlist/$uid');
      String? token = await UserService.getAccessToken();
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<FriendCircleGroup> groups = [];
        for (var group in data) {
          groups.add(GroupsService.buildFriendCircleGroup(group));
        }
        return {'success': true, 'data': groups};
      } else {
        return {
          'success': false,
          'error':
              jsonDecode(response.body)['message'] ?? 'Unknown error occurred',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
