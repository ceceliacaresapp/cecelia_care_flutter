// lib/providers/cognitive_provider.dart
//
// Manages cognitive screening assessment data — saves new assessments and
// streams the 12-month history for the active elder. Same architecture as
// AdlProvider.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/models/cognitive_assessment.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';

class CognitiveProvider extends ChangeNotifier {
  bool isLoading = false;
  CognitiveAssessment? currentMonth;
  List<CognitiveAssessment> history = [];

  String? _currentElderId;
  StreamSubscription<QuerySnapshot>? _subscription;

  bool get hasAssessedThisMonth => currentMonth != null;

  /// Latest assessment regardless of month.
  CognitiveAssessment? get latest =>
      history.isNotEmpty ? history.first : null;

  /// Monthly total scores ordered oldest → newest for charting.
  List<double> get scoreTrend =>
      history.reversed.map((a) => a.totalScore.toDouble()).toList();

  void updateForElder(ElderProfile? elder) {
    final newId = elder?.id;
    if (newId == _currentElderId) return;

    _subscription?.cancel();
    _currentElderId = newId;

    if (newId == null || newId.isEmpty) {
      currentMonth = null;
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
        .collection('cognitiveAssessments')
        .orderBy('createdAt', descending: true)
        .limit(12)
        .snapshots()
        .listen(
      (snap) {
        final thisMonth = currentMonthString();
        final assessments = snap.docs
            .map((d) =>
                CognitiveAssessment.fromFirestore(d.id, d.data()))
            .toList();
        history = assessments;
        currentMonth = assessments
            .where((a) => a.monthString == thisMonth)
            .firstOrNull;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('CognitiveProvider: subscription error: $e');
        isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> saveAssessment(CognitiveAssessment assessment) async {
    final elderId = _currentElderId;
    if (elderId == null || elderId.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Use a per-month doc ID so re-running this month overwrites the prior
    // attempt rather than creating duplicates.
    final docId = '${elderId}_${assessment.monthString}';

    await FirebaseFirestore.instance
        .collection('elderProfiles')
        .doc(elderId)
        .collection('cognitiveAssessments')
        .doc(docId)
        .set(assessment.toFirestore(), SetOptions(merge: true));
  }

  static String currentMonthString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
