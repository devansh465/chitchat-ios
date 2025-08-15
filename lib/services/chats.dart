import 'dart:convert';
import 'package:chitchat/appstate/variables.dart';
import 'package:chitchat/components/appbar.dart';
import 'package:chitchat/services/user.dart';
import 'package:event_handeler/event_handeler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChatServices {
  static String baseUrl =
      AppVariables.get<String>('baseurl')!.trim() ?? 'http://localhost:3000';

  static Future<String> getChatToken() async {
    try {
      String? token = await UserService.getAccessToken();

      final response = await http.get(
        Uri.parse('$baseUrl/get/chat/token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token'] ?? '';
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  static Future<void> initializePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("messageNotificationCount", 0);
  }

  static Future<void> resetMessageNotificationCount() async {
    // Reset the message notification count to zero
    // This function can be called when the user opens the app or a specific screen
    // where you want to reset the count.
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("messageNotificationCount", 0);
    dispatchCustomEvent(0, "messageNotificationCountUpdate");
  }

  static Future<int> getMessageNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt("messageNotificationCount") ?? 0;
  }

  static Future<void> incrementMessageNotificationCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt("messageNotificationCount") ?? 0;
    prefs.setInt("messageNotificationCount", currentCount + 1);
    NotificationIcon.updateCount(
        currentCount + 1, NotificationIconType.Message);
  }

  static Future<void> setMessageNotificationCount(int count) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("messageNotificationCount", count);
  }
}
