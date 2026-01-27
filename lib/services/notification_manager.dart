import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitchat/services/chats.dart';

/// Centralized notification polling manager.
///
/// This singleton ensures only ONE polling timer exists across the entire app,
/// preventing duplicate API calls that cause rate limiting.
class NotificationManager {
  static NotificationManager? _instance;
  static NotificationManager get instance {
    _instance ??= NotificationManager._();
    return _instance!;
  }

  NotificationManager._();

  // ValueNotifiers for reactive UI updates
  final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);
  final ValueNotifier<int> messageCount = ValueNotifier<int>(0);

  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isInitialized = false;

  // Rate limit backoff
  int _consecutiveFailures = 0;
  static const int _maxBackoffSeconds = 300; // Max 5 minutes between retries

  // Track locally read notification IDs (database will eventually clean server-side)
  Set<String> _locallyReadIds = {};

  /// Initialize the notification manager and start polling.
  /// Call this once at app startup (e.g., in main.dart after login).
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Load locally read IDs from SharedPreferences
    await _loadLocallyReadIds();

    // Fetch initial counts
    await _fetchCounts();

    // Start polling every 30 seconds
    _startPolling();
  }

  /// Stop polling (call on logout)
  void dispose() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isInitialized = false;
    _consecutiveFailures = 0;
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchCounts();
    });
  }

  Future<void> _fetchCounts() async {
    // Prevent concurrent polling
    if (_isPolling) {
      debugPrint('NotificationManager: Skipping poll (previous still running)');
      return;
    }

    _isPolling = true;

    try {
      // Fetch notification count (from SharedPreferences, does NOT call API anymore)
      final notifCount = await _getNotificationCountLocal();
      notificationCount.value = notifCount;

      // Fetch message count
      final msgCount = await ChatServices.getMessageNotificationCount();
      messageCount.value = msgCount;

      // Reset failure count on success
      _consecutiveFailures = 0;

      debugPrint(
          'NotificationManager: counts fetched - notif=$notifCount, msg=$msgCount');
    } catch (e) {
      _consecutiveFailures++;
      debugPrint(
          'NotificationManager: Error fetching counts: $e (failures: $_consecutiveFailures)');

      // Apply exponential backoff if too many failures
      if (_consecutiveFailures >= 3) {
        final backoffSeconds =
            (_consecutiveFailures * 30).clamp(30, _maxBackoffSeconds);
        debugPrint(
            'NotificationManager: Applying backoff of ${backoffSeconds}s');
        _pollingTimer?.cancel();
        _pollingTimer = Timer(Duration(seconds: backoffSeconds), () {
          _startPolling();
          _fetchCounts();
        });
      }
    } finally {
      _isPolling = false;
    }
  }

  /// Get notification count from local storage only (no API call)
  Future<int> _getNotificationCountLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("unreadcount") ?? 0;
  }

  /// Store new unread notification IDs, deduplicating against existing and locally read ones.
  /// Returns the new unique count.
  Future<int> storeUnreadIds(List<String> newIds) async {
    final prefs = await SharedPreferences.getInstance();

    // Get already stored unread IDs
    List<String> storedIds = prefs.getStringList("unreadIds") ?? [];
    Set<String> storedSet = storedIds.toSet();

    // Add only new unique IDs that haven't been locally read
    int addedCount = 0;
    for (String id in newIds) {
      if (!storedSet.contains(id) && !_locallyReadIds.contains(id)) {
        storedSet.add(id);
        addedCount++;
      }
    }

    // Save updated unique list
    final updatedList = storedSet.toList();
    await prefs.setStringList("unreadIds", updatedList);

    // Update unread count
    final newCount = updatedList.length;
    await prefs.setInt("unreadcount", newCount);

    // Update ValueNotifier
    notificationCount.value = newCount;

    debugPrint(
        'NotificationManager: storeUnreadIds added $addedCount new IDs, total=$newCount');

    return newCount;
  }

  /// Mark a notification as read locally
  Future<void> markAsRead(String id) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> storedIds = prefs.getStringList("unreadIds") ?? [];

    // Remove the ID if it exists
    if (storedIds.contains(id)) {
      storedIds.remove(id);
      await prefs.setStringList("unreadIds", storedIds);
      await prefs.setInt("unreadcount", storedIds.length);
      notificationCount.value = storedIds.length;
    }

    // Add to locally read set so it doesn't get re-added on next API fetch
    _locallyReadIds.add(id);
    await _saveLocallyReadIds();
  }

  /// Clear all unread notifications
  Future<void> clearAllUnread() async {
    final prefs = await SharedPreferences.getInstance();

    // Move all unread to locally read
    List<String> storedIds = prefs.getStringList("unreadIds") ?? [];
    _locallyReadIds.addAll(storedIds);
    await _saveLocallyReadIds();

    // Clear unread
    await prefs.remove("unreadIds");
    await prefs.remove("unreadcount");
    notificationCount.value = 0;
  }

  /// Reset message notification count
  Future<void> resetMessageCount() async {
    await ChatServices.resetMessageNotificationCount();
    messageCount.value = 0;
  }

  /// Load locally read IDs from SharedPreferences
  Future<void> _loadLocallyReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList("locallyReadIds") ?? [];
    _locallyReadIds = ids.toSet();

    // Clean up old IDs (keep only last 1000 to prevent memory bloat)
    if (_locallyReadIds.length > 1000) {
      _locallyReadIds = _locallyReadIds
          .toList()
          .sublist(_locallyReadIds.length - 1000)
          .toSet();
      await _saveLocallyReadIds();
    }
  }

  /// Save locally read IDs to SharedPreferences
  Future<void> _saveLocallyReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList("locallyReadIds", _locallyReadIds.toList());
  }

  /// Force refresh notification count (call after viewing notifications screen)
  Future<void> refresh() async {
    await _fetchCounts();
  }
}
