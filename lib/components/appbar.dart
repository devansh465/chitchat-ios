import 'package:chitchat/screens/chat.dart';
import 'package:chitchat/screens/notifications.dart';
import 'package:chitchat/services/notification_manager.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

enum NotificationIconType {
  Notification,
  Message,
}

class NotificationIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final Color iconColor;
  final Color badgeColor;
  final double rightPadding;
  final double badgeSize;
  final NotificationIconType type;

  const NotificationIcon({
    Key? key,
    required this.icon,
    required this.type,
    this.onPressed,
    this.iconSize = 30,
    this.iconColor = Colors.white,
    this.badgeColor = Colors.red,
    this.rightPadding = 20,
    this.badgeSize = 10,
  }) : super(key: key);

  /// Static method conserved for backward compatibility with existing code
  static void updateCount(int newCount, NotificationIconType type) {
    if (type == NotificationIconType.Notification) {
      NotificationManager.instance.notificationCount.value = newCount;
    } else {
      NotificationManager.instance.messageCount.value = newCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the centralized NotificationManager's ValueNotifiers
    final valueNotifier = type == NotificationIconType.Notification
        ? NotificationManager.instance.notificationCount
        : NotificationManager.instance.messageCount;

    return ValueListenableBuilder<int>(
      valueListenable: valueNotifier,
      builder: (context, count, _) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(icon),
              onPressed: onPressed ??
                  () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: type == NotificationIconType.Notification
                            ? const NotificationsScreen()
                            : const ChatScreen(),
                      ),
                    );
                  },
              color: iconColor,
              iconSize: iconSize,
              padding: EdgeInsets.only(right: rightPadding),
            ),
            if (count > 0)
              Positioned(
                right: rightPadding - 5,
                top: 8,
                child: GestureDetector(
                  onTap: onPressed ??
                      () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeft,
                            child: type == NotificationIconType.Notification
                                ? const NotificationsScreen()
                                : const ChatScreen(),
                          ),
                        );
                      },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: badgeSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
