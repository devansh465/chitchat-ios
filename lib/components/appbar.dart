import 'dart:async';
import 'package:chitchat/screens/chat.dart';
import 'package:chitchat/screens/notifications.dart';
import 'package:chitchat/services/chats.dart';
import 'package:chitchat/services/notification.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

enum NotificationIconType {
  Notification,
  Message,
}

class NotificationIcon extends StatefulWidget {
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

  @override
  State<NotificationIcon> createState() => _NotificationIconState();

  // Global count holder
  static final ValueNotifier<int> _NotificationCount = ValueNotifier<int>(0);
  static final ValueNotifier<int> _MessageCount = ValueNotifier<int>(0);

  // Expose it if you ever want to update from outside
  static void updateCount(int newCount, NotificationIconType type) {
    if (type == NotificationIconType.Notification) {
      _NotificationCount.value = newCount;
    } else {
      _MessageCount.value = newCount;
    }
  }
}

class _NotificationIconState extends State<NotificationIcon> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Poll every 30 seconds (you can adjust)

    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (widget.type == NotificationIconType.Notification) {
        try {
          final count = await NotificationService.getNotificationCount();
          NotificationIcon.updateCount(
              count, NotificationIconType.Notification);
          print("Notification count: $count");
        } catch (e) {
          debugPrint("Failed to fetch notification count: $e");
        }
      } else if (widget.type == NotificationIconType.Message) {
        try {
          final count = await ChatServices.getMessageNotificationCount();
          NotificationIcon.updateCount(count, NotificationIconType.Message);
          print("Message count: $count");
        } catch (e) {
          debugPrint("Failed to fetch message count: $e");
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.type == NotificationIconType.Notification
          ? NotificationIcon._NotificationCount
          : NotificationIcon._MessageCount,
      builder: (context, count, _) {
        return Stack(
          children: [
            IconButton(
              icon: Icon(widget.icon),
              onPressed: widget.onPressed ??
                  () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: widget.type == NotificationIconType.Notification
                            ? const NotificationsScreen()
                            : const ChatScreen(),
                      ),
                    );
                  },
              color: widget.iconColor,
              iconSize: widget.iconSize,
              padding: EdgeInsets.only(right: widget.rightPadding),
            ),
            if (count > 0)
              Positioned(
                right: widget.rightPadding - 5,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: widget.badgeColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.badgeSize,
                      fontWeight: FontWeight.bold,
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
