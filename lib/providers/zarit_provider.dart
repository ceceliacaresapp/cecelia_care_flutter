// lib/providers/zarit_provider.dart
//
// Loads and saves Zarit Burden Interview (ZBI-12) assessments.
//
// Shape mirrors WellnessProvider — auth-scoped, auto-rewires on
// auth changes, exposes a loading flag + error message. The self-care
// screen consumes `latest`, `history`, and `trendPoints` to render
// the summary card + trend chart without any Firestore access of its
// own.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/models/zarit_assessment.dart';

class ZaritProvider with ChangeNotifier {
  ZaritProvider() {
    _authSub =
        FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
    // If we already have a signed-in user at construction time, kick off
    // the subscription immediately — otherwise first load waits for an
    // auth-state change that will never come.
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) _onAuthChanged(current);
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'zaritAssessments';
  static const int _historyLimit = 24; // 2 years of monthly data

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _historySub;

  String? _userId;
  bool _isLoading = false;
  String? _error;

  List<ZaritAssessment> _history = const [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Newest-first list of past assessments.
  List<ZaritAssessment> get history => _history;

  /// Most recent assessment, or null if the user hasn't taken one.
  ZaritAssessment? get latest => _history.isEmpty ? null : _history.first;

  bool get hasHistory => _history.isNotEmpty;

  /// Chronologically-ordered (oldest→newest) points for the trend chart.
  /// Each point is (DateTime, total 0–48). Filtered to assessments with
  /// a completedAt timestamp so we don't plot NaNs.
  List<({DateTime at, int total})> get trendPoints {
    final pts = <({DateTime at, int total})>[];
    for (final a in _history.reversed) {
      final at = a.completedAt?.toDate();
      if (at == null) continue;
      pts.add((at: at, total: a.total));
    }
    return pts;
  }

  /// Compares the latest assessment to the one before it.
  /// Returns null when fewer than two data points exist.
  int? get deltaFromPrevious {
    if (_history.length < 2) return null;
    return _history.first.total - _history[1].total;
  }

  /// True when 30+ days have elapsed since the last completed assessment.
  /// The self-care screen uses this to render a "time for a check-in" CTA.
  bool get isDueForMonthly {
    final l = latest;
    if (l == null) return true;
    final at = l.completedAt?.toDate();
    if (at == null) return true;
    return DateTime.now().difference(at).inDays >= 30;
  }

  /// Days since the last assessment, or null if none.
  int? get daysSinceLast {
    final l = latest;
    if (l == null) return null;
    final at = l.completedAt?.toDate();
    if (at == null) return null;
    return DateTime.now().difference(at).inDays;
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// Writes a new assessment and returns the created document id.
  /// Fails silently (logs + sets [error]) when no user is signed in.
  Future<String?> saveAssessment({
    required List<int> itemScores,
    String? elderId,
    String? note,
  }) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) {
      _error = 'Sign-in required to save an assessment.';
      notifyListeners();
      return null;
    }

    if (itemScores.length != kZaritItems.length) {
      _error = 'All ${kZaritItems.length} items must be answered.';
      notifyListeners();
      return null;
    }

    final assessment = ZaritAssessment(
      userId: uid,
      elderId: elderId,
      itemScores: itemScores,
      note: (note != null && note.trim().isNotEmpty) ? note.trim() : null,
    );

    try {
      final docRef = await _db
          .collection(_collection)
          .add(assessment.toFirestore());
      return docRef.id;
    } catch (e) {
      _error = 'Could not save assessment: $e';
      debugPrint('ZaritProvider.saveAssessment error: $e');
      notifyListeners();
      return null;
    }
  }

  Future<void> deleteAssessment(String id) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty || id.isEmpty) return;
    try {
      await _db.collection(_collection).doc(id).delete();
    } catch (e) {
      _error = 'Could not delete: $e';
      debugPrint('ZaritProvider.deleteAssessment error: $e');
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Auth / Firestore wiring
  // ---------------------------------------------------------------------------

  void _onAuthChanged(User? user) {
    _historySub?.cancel();
    _historySub = null;
    _history = const [];
    _error = null;
    _userId = user?.uid;

    if (user == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _subscribe(user.uid);
  }

  void _subscribe(String uid) {
    _isLoading = true;
    notifyListeners();

    _historySub = _db
        .collection(_collection)
        .where('userId', isEqualTo: uid)
        .orderBy('completedAt', descending: true)
        .limit(_historyLimit)
        .snapshots()
        .listen(
      (snap) {
        _error = null;
        _history = snap.docs
            .map((d) => ZaritAssessment.fromFirestore(d))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _error = 'Could not load burden history.';
        _isLoading = false;
        debugPrint('ZaritProvider subscribe error: $e');
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}
