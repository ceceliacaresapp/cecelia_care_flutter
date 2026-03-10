import 'dart:async'; // For StreamSubscription
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/self_care_reminder.dart';
import '../models/daily_mood.dart'; // Import the new DailyMood model
import 'package:intl/intl.dart'; // For date formatting

// --- I18N UPDATE ---
// A data class to hold structured error information for localization.
class SelfCareError {
  final String type; // e.g., 'mood', 'reminders', 'history', 'save'
  final String details; // The raw error message

  SelfCareError({required this.type, required this.details});
}

class SelfCareProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _uid;

  // Mood of today
  String? _todayMood; // 🙂 😐 😔 😡 😍
  String? _todayNote;
  StreamSubscription<DocumentSnapshot>? _todayMoodSubscription;

  // Reminders
  StreamSubscription<DocumentSnapshot>? _remindersSubscription;
  final Map<String, SelfCareReminder> _reminders = {};

  // History and Streak
  final List<DailyMood> _history = [];
  int _currentStreak = 0;
  StreamSubscription<QuerySnapshot>? _historySubscription;

  bool _isLoading = false;
  // --- I18N UPDATE ---
  // Replaced the simple String with a structured error object.
  SelfCareError? _errorInfo;

  String? get todayMood => _todayMood;
  String? get todayNote => _todayNote;
  Map<String, SelfCareReminder> get reminders => Map.unmodifiable(_reminders);
  List<DailyMood> get history => List.unmodifiable(_history);
  int get currentStreak => _currentStreak;
  bool get isLoading => _isLoading;
  // --- I18N UPDATE ---
  // Getter returns the new error object.
  SelfCareError? get errorInfo => _errorInfo;

  SelfCareProvider() {
    _uid = _auth.currentUser?.uid;
    _auth.authStateChanges().listen(_onAuthStateChanged);
    if (_uid != null) {
      load();
      loadHistory();
    }
  }

  void clearErrorMessage() {
    _errorInfo = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _todayMoodSubscription?.cancel();
    _remindersSubscription?.cancel();
    _historySubscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (_uid != user?.uid) {
      _uid = user?.uid;
      await _cancelAllSubscriptions();

      _todayMood = null;
      _todayNote = null;
      _reminders.clear();
      _history.clear();
      _currentStreak = 0;
      _errorInfo = null;
      if (_uid != null) {
        await load();
        await loadHistory();
      } else {
        notifyListeners();
      }
    }
  }

  String _dateToDocId(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _cancelAllSubscriptions() async {
    await _todayMoodSubscription?.cancel();
    _todayMoodSubscription = null;
    await _remindersSubscription?.cancel();
    _remindersSubscription = null;
    await _historySubscription?.cancel();
    _historySubscription = null;
  }

  Future<void> _initPrimarySubscriptions() async {
    if (_uid == null) {
      // --- I18N UPDATE ---
      _errorInfo = SelfCareError(type: 'auth', details: 'User not logged in.');
      _isLoading = false;
      notifyListeners();
      return;
    }

    final Completer<void> moodCompleter = Completer<void>();
    await _todayMoodSubscription?.cancel();
    await _remindersSubscription?.cancel();

    _isLoading = true;
    _errorInfo = null;
    notifyListeners();

    final todayKey = _dateToDocId(DateTime.now());
    _todayMoodSubscription = _db
        .collection('users')
        .doc(_uid!)
        .collection('selfCare')
        .doc('moods')
        .collection('entries')
        .doc(todayKey)
        .snapshots()
        .listen(
      (moodSnap) {
        _errorInfo = null;
        if (moodSnap.exists) {
          _todayMood = moodSnap.data()?['moodEmoji'] as String?;
          _todayNote = moodSnap.data()?['note'] as String?;
        } else {
          _todayMood = null;
          _todayNote = null;
        }
        _isLoading = false;
        if (!moodCompleter.isCompleted) moodCompleter.complete();
        notifyListeners();
      },
      onError: (e) {
        // --- I18N UPDATE ---
        _errorInfo = SelfCareError(type: 'load_mood', details: e.toString());
        _todayMood = null;
        _todayNote = null;
        _isLoading = false;
        debugPrint(
            'SelfCareProvider._todayMoodSubscription error: ${_errorInfo?.details}');
        if (!moodCompleter.isCompleted) moodCompleter.completeError(e);
        notifyListeners();
      },
    );

    _remindersSubscription = _db
        .collection('users')
        .doc(_uid!)
        .collection('selfCare')
        .doc('reminders')
        .snapshots()
        .listen(
      (remSnap) {
        _errorInfo = null;
        _reminders.clear();
        if (remSnap.exists && remSnap.data() != null) {
          for (final entry in remSnap.data()!.entries) {
            final dynamic value = entry.value;
            _reminders[entry.key] = SelfCareReminder(
              id: entry.key,
              timeOfDay: value is String ? value : null,
            );
          }
        }
        for (String id in ['hydrate', 'stretch', 'walk']) {
          if (!_reminders.containsKey(id)) {
            _reminders[id] = SelfCareReminder(id: id, timeOfDay: null);
          }
        }
        notifyListeners();
      },
      onError: (e) {
        // --- I18N UPDATE ---
        _errorInfo =
            SelfCareError(type: 'load_reminders', details: e.toString());
        _reminders.clear();
        for (String id in ['hydrate', 'stretch', 'walk']) {
          _reminders.putIfAbsent(
              id, () => SelfCareReminder(id: id, timeOfDay: null));
        }
        _isLoading = false;
        debugPrint(
            'SelfCareProvider._remindersSubscription error: ${_errorInfo?.details}');
        notifyListeners();
      },
    );

    return moodCompleter.future;
  }

  Future<void> _initHistorySubscription() async {
    if (_uid == null) {
      // --- I18N UPDATE ---
      _errorInfo = SelfCareError(type: 'auth', details: 'User not logged in.');
      _history.clear();
      _currentStreak = 0;
      notifyListeners();
      return;
    }

    final Completer<void> historyCompleter = Completer<void>();
    _errorInfo = null;
    await _historySubscription?.cancel();

    final today = DateTime.now();
    final historyStartDate = today.subtract(const Duration(days: 59));
    final historyStartDateStr = _dateToDocId(historyStartDate);

    _historySubscription = _db
        .collection('users')
        .doc(_uid!)
        .collection('selfCare')
        .doc('moods')
        .collection('entries')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: historyStartDateStr)
        .orderBy(FieldPath.documentId, descending: true)
        .snapshots()
        .listen(
      (querySnapshot) {
        _errorInfo = null;
        final Map<String, String> dateToEmojiMap = {};
        for (final doc in querySnapshot.docs) {
          final moodEmoji = doc.data()['moodEmoji'] as String?;
          if (moodEmoji != null) {
            dateToEmojiMap[doc.id] = moodEmoji;
          }
        }
        _history.clear();
        for (int i = 6; i >= 0; i--) {
          final date = today.subtract(Duration(days: i));
          final dateKey = _dateToDocId(date);
          if (dateToEmojiMap.containsKey(dateKey)) {
            _history.add(
                DailyMood(date: date, emoji: dateToEmojiMap[dateKey]!));
          }
        }
        _currentStreak = 0;
        for (int i = 0; i < 60; i++) {
          final date = today.subtract(Duration(days: i));
          final dateKey = _dateToDocId(date);
          if (dateToEmojiMap.containsKey(dateKey)) {
            _currentStreak++;
          } else {
            break;
          }
        }
        if (!historyCompleter.isCompleted) historyCompleter.complete();
        notifyListeners();
      },
      onError: (e, s) {
        // --- I18N UPDATE ---
        _errorInfo =
            SelfCareError(type: 'load_history', details: e.toString());
        _history.clear();
        _currentStreak = 0;
        debugPrint(
            'SelfCareProvider._historySubscription error: ${_errorInfo?.details}\nStack: $s');
        if (!historyCompleter.isCompleted) historyCompleter.completeError(e);
        notifyListeners();
      },
    );
    return historyCompleter.future;
  }

  Future<void> load() async {
    return _initPrimarySubscriptions();
  }

  Future<void> loadHistory() async {
    return _initHistorySubscription();
  }

  Future<void> saveMood(String emoji, String? note) async {
    if (_uid == null) return;
    _errorInfo = null;
    _todayMood = emoji;
    _todayNote = note;
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('selfCare')
          .doc('moods')
          .collection('entries')
          .doc(_dateToDocId(DateTime.now()))
          .set({
        'moodEmoji': emoji,
        'note': note,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      // --- I18N UPDATE ---
      _errorInfo = SelfCareError(type: 'save_mood', details: e.toString());
      debugPrint(
          'SelfCareProvider.saveMood error: ${_errorInfo?.details}\nStack: $s');
      notifyListeners();
    }
  }

  Future<void> saveReminder(SelfCareReminder rem) async {
    if (_uid == null) return;
    _errorInfo = null;
    _reminders[rem.id] = rem;
    notifyListeners();

    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('selfCare')
          .doc('reminders')
          .set({rem.id: rem.timeOfDay}, SetOptions(merge: true));
    } catch (e, s) {
      // --- I18N UPDATE ---
      _errorInfo =
          SelfCareError(type: 'save_reminder', details: e.toString());
      debugPrint(
          'SelfCareProvider.saveReminder error for ${rem.id}: ${_errorInfo?.details}\nStack: $s');
      notifyListeners();
    }
  }
}