import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ButtonType { post, comment, user }

class LikeButton extends StatefulWidget {
  final String postId;
  final ButtonType buttonType;
  final int initialLikes;
  final bool initiallyLiked;
  final bool showLikeCount;
  final Future<bool> Function(bool isLiked) onLikeChanged;

  // Customization properties
  final Color? likedColor;
  final Color? unlikedColor;
  final Color? textColor;
  final double? iconSize;
  final double? fontSize;

  const LikeButton({
    super.key,
    required this.buttonType,
    required this.initialLikes,
    required this.initiallyLiked,
    required this.onLikeChanged,
    this.showLikeCount = false,
    required this.postId,
    // Customization with sensible defaults
    this.likedColor,
    this.unlikedColor,
    this.textColor,
    this.iconSize,
    this.fontSize,
  });

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  late bool isLiked;
  late int likes;
  late SharedPreferences prefs;

  // Default colors based on button type
  Color get _likedColor => widget.likedColor ?? Colors.red;
  Color get _unlikedColor =>
      widget.unlikedColor ??
      (widget.buttonType == ButtonType.post ? Colors.grey : Colors.white54);
  Color get _textColor =>
      widget.textColor ??
      (widget.buttonType == ButtonType.post ? Colors.white : Colors.white54);
  double get _iconSize =>
      widget.iconSize ?? (widget.buttonType == ButtonType.post ? 24.0 : 20.0);
  double get _fontSize =>
      widget.fontSize ?? (widget.buttonType == ButtonType.post ? 16.0 : 10.0);

  @override
  void initState() {
    super.initState();
    isLiked = widget.initiallyLiked;
    likes = widget.initialLikes;

    loadLike();
  }

  @override
  void didUpdateWidget(covariant LikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialLikes != widget.initialLikes) {
      setState(() {
        likes = widget.initialLikes;
      });
    }
    if (oldWidget.initiallyLiked != widget.initiallyLiked) {
      setState(() {
        isLiked = widget.initiallyLiked;
      });
    }
  }

  String formatLikes(int number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(1)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  void loadLike() async {
    prefs = await SharedPreferences.getInstance();
    final like = prefs.getString(widget.postId);
    if (like != null) {
      setState(() {
        isLiked = true;
      });
    }
  }

  void toggleLike() async {
    // Store original state before optimistic update
    final bool originalIsLiked = isLiked;
    final int originalLikes = likes;

    setState(() {
      isLiked = !isLiked;
      likes += isLiked ? 1 : -1;
      if (likes < 0) likes = 0;
    });

    bool result = await widget.onLikeChanged(isLiked); // Notify parent widget
    if (result == false) {
      await prefs.remove(widget.postId);
      // Revert to original state on failure
      setState(() {
        isLiked = originalIsLiked;
        likes = originalLikes;
      });
    } else {
      prefs.setString(widget.postId, isLiked.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.buttonType == ButtonType.post
        ? buildLikeButtonForPosts()
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                onTap: toggleLike,
                child: Icon(
                  Icons.favorite,
                  color: isLiked ? _likedColor : _unlikedColor,
                  size: _iconSize,
                ),
              ),
              if (widget.showLikeCount)
                Text(
                  formatLikes(likes),
                  style: TextStyle(fontSize: _fontSize, color: _textColor),
                ),
            ],
          );
  }

  Widget buildLikeButtonForPosts() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: toggleLike,
            child: Icon(
              Icons.favorite,
              color: isLiked ? _likedColor : _unlikedColor,
              size: _iconSize,
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            formatLikes(likes),
            style: TextStyle(
              fontSize: _fontSize,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }
}
