// lib/providers/custom_entry_types_provider.dart
//
// Watches elderProfiles/{elderId}/customEntryTypes and provides the list
// of custom entry type definitions to the widget tree.
//
// Registered in main.dart as a ChangeNotifierProxyProvider that auto-updates
// when the active elder switches.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cecelia_care_flutter/models/custom_entry_type.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';

class CustomEntryTypesProvider extends ChangeNotifier {
  List<CustomEntryType> _types = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;
  String? _currentElderId;

  List<CustomEntryType> get types => _types;
  bool get isLoading => _isLoading;

  void updateForElder(ElderProfile? elder) {
    final newId = elder?.id;
    if (newId == _currentElderId) return;
    _currentElderId = newId;
    _subscription?.cancel();
    _types = [];

    if (newId == null || newId.isEmpty) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _subscription = FirebaseFirestore.instance
        .collection('elderProfiles')
        .doc(newId)
        .collection('customEntryTypes')
        .orderBy('name')
        .snapshots()
        .listen(
      (snapshot) {
        _types = snapshot.docs
            .map((doc) => CustomEntryType.fromFirestore(
                  doc.id,
                  doc.data(),
                ))
            .toList();
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('CustomEntryTypesProvider error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
