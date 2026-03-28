// lib/providers/message_provider.dart
//
// Tracks unread message count for the current user across the active elder's
// timeline. Drives the notification badge on the Timeline nav tab.
//
// Design:
//   - Watches Firestore journalEntries in real time, filtering to
//     type == 'message' entries visible to the current user.
//   - Compares each entry's entryTimestamp against a lastSeenTimestamp
//     stored in SharedPreferences (key: 'msg_last_seen_{uid}_{elderId}').
//   - Exposes unreadCount — the number of messages newer than lastSeenTimestamp
//     that were NOT posted by the current user (you don't get a badge for
//     your own messages).
//   - markRead() stamps the current time as lastSeenTimestamp and resets
//     the count to 0. Call this when the user navigates to the Timeline tab.
//
// Lifecycle:
//   - Created in main.dart as a ChangeNotifierProxyProvider listening to
//     both ActiveElderProvider and UserProfileProvider so it automatically
//     re-subscribes when either changes.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/elder_profile.dart';

class MessageProvider with ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------

  MessageProvider() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  // ---------------------------------------------------------------------------
  // Private state
  // ---------------------------------------------------------------------------

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _messageSubscription;

  ElderProfile? _activeElder;
  String? _currentUserId;

  int _unreadCount = 0;
  DateTime? _lastSeen; // null = never seen = all messages are "new"

  static const String _prefsPrefix = 'msg_last_seen_';

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Number of messages newer than the last time the user viewed the timeline,
  /// posted by other caregivers (not themselves).
  int get unreadCount => _unreadCount;

  /// True when there is at least one unread message.
  bool get hasUnread => _unreadCount > 0;

  /// Called by HomeScreen when the user taps the Timeline tab.
  /// Stamps now as lastSeenTimestamp and resets the unread count.
  Future<void> markRead() async {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    _lastSeen = DateTime.now();
    notifyListeners();
    await _persistLastSeen();
  }

  /// Called from the ProxyProvider when the active elder changes.
  void updateForElder(ElderProfile? elder) {
    if (elder?.id == _activeElder?.id) return;
    _activeElder = elder;
    _resubscribe();
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _authSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _onAuthChanged(User? user) {
    _currentUserId = user?.uid;
    _resubscribe();
  }

  void _resubscribe() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _unreadCount = 0;

    final uid = _currentUserId;
    final elderId = _activeElder?.id;

    if (uid == null || uid.isEmpty || elderId == null || elderId.isEmpty) {
      notifyListeners();
      return;
    }

    // Load lastSeen from prefs before opening the stream, so the first
    // snapshot correctly computes the unread count.
    _loadLastSeen(uid, elderId).then((_) {
      if (!_isActive) return; // disposed between the async gap

      _messageSubscription = FirebaseFirestore.instance
          .collection('journalEntries')
          .where('elderId', isEqualTo: elderId)
          .where('type', isEqualTo: 'message')
          // Firestore can't combine arrayContainsAny with orderBy across
          // different fields, so we fetch all visible messages and filter
          // the "from others" check in the listener.
          .where('visibleToUserIds', arrayContainsAny: [uid, 'all'])
          .orderBy('entryTimestamp', descending: true)
          .limit(50) // last 50 messages is plenty for badge purposes
          .snapshots()
          .listen(
            (snapshot) => _onMessageSnapshot(snapshot, uid),
            onError: (e) =>
                debugPrint('MessageProvider: stream error: $e'),
          );
    });
  }

  bool get _isActive {
    // Cheap alive-check — if _authSubscription is cancelled we're disposed.
    return _authSubscription != null;
  }

  void _onMessageSnapshot(QuerySnapshot snapshot, String currentUserId) {
    int count = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Don't count the current user's own messages.
      final postedBy = data['loggedByUserId'] as String?;
      if (postedBy == currentUserId) continue;

      // Check if this message is newer than lastSeen.
      final ts = data['entryTimestamp'] as Timestamp?;
      if (ts == null) continue;

      final msgTime = ts.toDate();
      if (_lastSeen == null || msgTime.isAfter(_lastSeen!)) {
        count++;
      }
    }

    if (count != _unreadCount) {
      _unreadCount = count;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // SharedPreferences persistence
  // ---------------------------------------------------------------------------

  String _prefsKey(String uid, String elderId) =>
      '${_prefsPrefix}${uid}_$elderId';

  Future<void> _loadLastSeen(String uid, String elderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_prefsKey(uid, elderId));
      if (millis != null) {
        _lastSeen = DateTime.fromMillisecondsSinceEpoch(millis);
      } else {
        // First launch — treat all existing messages as read so the user
        // doesn't get bombarded with a count on first open.
        _lastSeen = DateTime.now();
        await prefs.setInt(
            _prefsKey(uid, elderId), _lastSeen!.millisecondsSinceEpoch);
      }
    } catch (e) {
      debugPrint('MessageProvider._loadLastSeen error: $e');
      _lastSeen = DateTime.now();
    }
  }

  Future<void> _persistLastSeen() async {
    final uid = _currentUserId;
    final elderId = _activeElder?.id;
    if (uid == null || elderId == null || _lastSeen == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _prefsKey(uid, elderId), _lastSeen!.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('MessageProvider._persistLastSeen error: $e');
    }
  }
}
