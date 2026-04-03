// lib/providers/adl_provider.dart
//
// Manages ADL assessment data — saves, streams history, caches current week.
// Same architecture as WellnessProvider but scoped per elder.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/models/adl_assessment.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';

class AdlProvider extends ChangeNotifier {
  bool isLoading = false;
  AdlAssessment? currentWeek;
  List<AdlAssessment> history = [];

  String? _currentElderId;
  StreamSubscription<QuerySnapshot>? _subscription;

  bool get hasAssessedThisWeek => currentWeek != null;

  /// Trend data for chart — oldest first.
  List<double> get scoreTrend =>
      history.reversed.map((a) => a.totalScore.toDouble()).toList();

  void updateForElder(ElderProfile? elder) {
    final newId = elder?.id;
    if (newId == _currentElderId) return;

    _subscription?.cancel();
    _currentElderId = newId;

    if (newId == null || newId.isEmpty) {
      currentWeek = null;
      history = [];
      isLoading = false;
      notifyListeners();
      return;
    }
    _subscribe(newId);
  }

  void _subscribe(String elderId) {
    isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('elderProfiles')
        .doc(elderId)
        .collection('adlAssessments')
        .orderBy('weekString', descending: true)
        .limit(12)
        .snapshots()
        .listen(
      (snap) {
        final thisWeek = currentWeekString();
        final assessments = snap.docs
            .map((d) =>
                AdlAssessment.fromFirestore(d.id, d.data()))
            .toList();

        history = assessments;
        currentWeek = assessments
            .where((a) => a.weekString == thisWeek)
            .firstOrNull;

        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('AdlProvider: subscription error: $e');
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> saveAssessment({
    required int bathing,
    required int dressing,
    required int eating,
    required int toileting,
    required int transferring,
    required int continence,
    String? notes,
  }) async {
    final elderId = _currentElderId;
    if (elderId == null || elderId.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final week = currentWeekString();
    final docId = '${elderId}_$week';

    final assessment = AdlAssessment(
      elderId: elderId,
      assessedBy: user.uid,
      assessedByName: user.displayName ?? user.email ?? 'Unknown',
      weekString: week,
      bathing: bathing,
      dressing: dressing,
      eating: eating,
      toileting: toileting,
      transferring: transferring,
      continence: continence,
      notes: notes,
    );

    await FirebaseFirestore.instance
        .collection('elderProfiles')
        .doc(elderId)
        .collection('adlAssessments')
        .doc(docId)
        .set(assessment.toFirestore(), SetOptions(merge: true));
  }

  static String currentWeekString() {
    final now = DateTime.now();
    // ISO 8601 week number calculation.
    final dayOfYear =
        now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final weekNum = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  /// Returns the Monday date string for a given ISO week string.
  static String weekLabel(String weekString) {
    try {
      final parts = weekString.split('-W');
      final year = int.parse(parts[0]);
      final week = int.parse(parts[1]);
      // Jan 4 is always in ISO week 1.
      final jan4 = DateTime(year, 1, 4);
      final dayOfWeek = jan4.weekday;
      final monday =
          jan4.add(Duration(days: (week - 1) * 7 - dayOfWeek + 1));
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return 'Week of ${months[monday.month - 1]} ${monday.day}';
    } catch (_) {
      return weekString;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
