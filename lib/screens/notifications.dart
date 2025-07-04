import 'dart:async';

import 'package:chitchat/components/friendcircle.dart';
import 'package:chitchat/components/renderpost.dart';
import 'package:chitchat/constants/colors.dart';
import 'package:chitchat/services/notification.dart';
import 'package:chitchat/services/user.dart';
import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String type;
  final dynamic requestBody;
  final int votes;
  final int totalMembers;
  final String userId;

  NotificationModel({
    required this.id,
    required this.type,
    required this.requestBody,
    required this.votes,
    required this.totalMembers,
    required this.userId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'],
      type: json['requestType'],
      requestBody: json['requestBody'],
      votes: json['votes']?.length ?? 0,
      totalMembers: json['groupDetails']?['members']?.length ?? 1,
      userId: json['userId'] ?? 'Unknown',
    );
  }
}

class NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final Function(String) onVote; // Callback for voting

  const NotificationCard({
    Key? key,
    required this.notification,
    required this.onVote,
  }) : super(key: key);

  @override
  _NotificationCardState createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  late int votes;
  late int totalMembers;

  @override
  void initState() {
    super.initState();
    votes = widget.notification.votes;
    totalMembers = widget.notification.totalMembers;
  }

  void _handleVote() {
    setState(() {
      votes += 1;
    });
    widget.onVote(widget.notification.id);
  }

  String get _notificationTitle {
    switch (widget.notification.type) {
      case 'joinGroup':
        return "Group Join Request";
      case 'addPost':
        return "Make Post Public";
      default:
        return "New Notification";
    }
  }

  Color get _typeColor {
    switch (widget.notification.type) {
      case 'joinGroup':
        return Colors.blue;
      case 'addPost':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  double get _voteProgress {
    if (totalMembers == 0) return 0.0;
    return (votes / totalMembers).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDarkMode ? 8 : 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.cardColor,
              theme.cardColor.withOpacity(0.95),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and type indicator
              _buildHeader(),
              const SizedBox(height: 16),

              // Main content area
              _buildMainContent(),
              const SizedBox(height: 20),

              // Voting section
              _buildVotingSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _typeColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _typeColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.notification.type == 'joinGroup'
                    ? Icons.person_add
                    : Icons.public,
                size: 16,
                color: _typeColor,
              ),
              const SizedBox(width: 6),
              Text(
                _notificationTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _typeColor,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Icon(
          Icons.notifications_active,
          size: 20,
          color: Colors.grey[400],
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    if (widget.notification.type == 'joinGroup') {
      return _buildJoinGroupContent();
    } else {
      return _buildPostContent();
    }
  }

  Widget _buildJoinGroupContent() {
    final requestBody = widget.notification.requestBody;

    return Row(
      children: [
        // Profile image with online indicator
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[300]!, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.network(
                  requestBody['memberProfilePic'] ??
                      'https://via.placeholder.com/80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),

        // User details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                requestBody['memberName'] ?? 'Unknown User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildEducationInfo('School', requestBody['school']),
              _buildEducationInfo('College', requestBody['college']),
              _buildEducationInfo('University', requestBody['university']),
              _buildEducationInfo(
                  'Education Level', requestBody['educationLevel']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEducationInfo(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DynamicPostWidget(
          borderRadius: 12,
          content: widget.notification.requestBody['content'],
          media: List<Map<String, dynamic>>.from(
            (widget.notification.requestBody['media'] as List<dynamic>? ?? [])
                .map((m) => {
                      'type': m['type'],
                      'url': m['url'],
                    }),
          ),
          postId: widget.notification.requestBody['id'] ?? '',
          author: widget.notification.requestBody['author'],
          group: widget.notification.requestBody['group'] ?? '',
          authorName: widget.notification.requestBody['authorName'],
          profilePic: widget.notification.requestBody['profilePic'],
          likes: widget.notification.requestBody['likes'] ?? 0,
        ),
      ),
    );
  }

  Widget _buildVotingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Vote button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleVote,
              icon: const Icon(Icons.thumb_up, size: 20),
              label: Text(
                'Vote ($votes)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Progress indicator
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${((_voteProgress) * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _voteProgress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _voteProgress > 0.5 ? Colors.green : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$votes out of $totalMembers members voted',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  List<NotificationModel> _notifications = [];
  int _page = 1;
  int _limit = 10;
  int _total = 0;
  int _totalPages = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  FriendCircleGroup? myGroup;
  Map<String, dynamic>? myProfile;
  _getMyprofile() async {
    setState(() {
      _isLoading = true;
    });
    final result = await UserService.fetchMyProfile();

    if (result['success']) {
      print('Profile fetched successfully:');
      print(result['data']);
      myProfile = result['data'];
      setState(() {});

      if (result['group'] != null) {
        myGroup = result['group'] as FriendCircleGroup;
        setState(() {});
        print('Group Name: ${myGroup?.groupData['name']}');
        print('Members:');
        for (var member in myGroup!.members) {
          print('  - ${member.additionalData['memberName']}');
        }
      } else {
        print('No group found for this user.');
        myGroup = FriendCircleGroup(
          groupId: 'defaultGroup',
          groupData: {'name': 'Default Group'},
          members: [],
        );
      }
    } else {
      myGroup = FriendCircleGroup(
        groupId: 'defaultGroup',
        groupData: {'name': 'Default Group'},
        members: [],
      );
      print('Error fetching profile: ${result['error']}');
    }
    setState(() {});
  }

  void _getGroupJoinReqests() async {
    List<Map<String, dynamic>> jsonData =
        (await NotificationService.getGroupJoinRequests(
            context, myGroup!.groupId,
            showLoaders: false))!;
    print(jsonData);

    if (mounted) {
      setState(() {
        _notifications =
            jsonData.map((data) => NotificationModel.fromJson(data)).toList();
        _isLoading = false;
      });
    }
  }

  List _voted = [];
  void _onVote(String id) async {
    if (_voted.contains(id)) {
      return;
    }
    bool res = await NotificationService.vote(context, id);
    setState(() {
      _notifications = _notifications.map((n) {
        if (n.id == id && res) {
          return NotificationModel(
            id: n.id,
            type: n.type,
            requestBody: n.requestBody,
            votes: n.votes + 1,
            totalMembers: n.totalMembers,
            userId: n.userId,
          );
        }
        return n;
      }).toList();
    });
    _voted.add(id);
  }

  Timer? _notificationTimer;

  void _startNotificationTimer() {
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _getGroupJoinReqests();
      }
    });
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    NotificationService.clearAllUnreadNotifications();
    _startNotificationTimer();
    _getMyprofile().then((_) {
      _getGroupJoinReqests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: Colors.white,
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(
                  child: Text(
                  'No notifications yet.',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification =
                        _notifications.reversed.toList()[index];
                    return NotificationCard(
                      notification: notification,
                      onVote: _onVote,
                    );
                  },
                ),
    );
  }
}
