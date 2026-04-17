// lib/services/invite_service.dart
//
// Thin Flutter wrapper around the invite-flow Cloud Functions. Keeps
// all exception-unwrapping / error-code translation in one place so
// the screens can render plain-English failure messages without
// knowing about FirebaseFunctionsException codes.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import 'package:cecelia_care_flutter/models/invite_code.dart';

/// Result of [InviteService.createInvite].
class CreatedInvite {
  final String code;
  final DateTime expiresAt;
  final String shareUrl;
  final String role;
  final int maxUses;

  const CreatedInvite({
    required this.code,
    required this.expiresAt,
    required this.shareUrl,
    required this.role,
    required this.maxUses,
  });
}

/// Result of [InviteService.redeemInvite].
class RedeemedInvite {
  final String elderId;
  final String elderName;
  final String role;
  final bool alreadyRedeemed;
  final bool alreadyOnProfile;

  const RedeemedInvite({
    required this.elderId,
    required this.elderName,
    required this.role,
    this.alreadyRedeemed = false,
    this.alreadyOnProfile = false,
  });
}

/// Thrown when a function call fails. Message is always user-facing.
class InviteException implements Exception {
  final String message;
  final String? code;
  InviteException(this.message, {this.code});
  @override
  String toString() => message;
}

class InviteService {
  InviteService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  // ---------------------------------------------------------------------------
  // create
  // ---------------------------------------------------------------------------

  Future<CreatedInvite> createInvite({
    required String elderId,
    String role = 'viewer',
    int ttlDays = 14,
    int maxUses = 1,
  }) async {
    try {
      final callable = _functions.httpsCallable('createInviteCode');
      final res = await callable.call<Map<String, dynamic>>({
        'elderId': elderId,
        'role': role,
        'ttlDays': ttlDays,
        'maxUses': maxUses,
      });
      final data = Map<String, dynamic>.from(res.data);
      return CreatedInvite(
        code: data['code'] as String,
        expiresAt: DateTime.parse(data['expiresAt'] as String),
        shareUrl: data['shareUrl'] as String,
        role: (data['role'] as String?) ?? role,
        maxUses: (data['maxUses'] as num?)?.toInt() ?? maxUses,
      );
    } on FirebaseFunctionsException catch (e) {
      throw _asInviteException(e);
    } catch (e) {
      debugPrint('InviteService.createInvite error: $e');
      throw InviteException('Could not create invite. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // peek — read a code doc (without redeeming) for the "You've been
  // invited to help care for Helen" preview screen.
  // ---------------------------------------------------------------------------

  Future<InviteCode?> peekInvite(String rawCode) async {
    final code = _normalize(rawCode);
    if (code == null) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('inviteCodes')
          .doc(code)
          .get();
      if (!snap.exists) return null;
      return InviteCode.fromFirestore(snap);
    } catch (e) {
      debugPrint('InviteService.peekInvite error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // redeem
  // ---------------------------------------------------------------------------

  Future<RedeemedInvite> redeemInvite(String rawCode) async {
    final code = _normalize(rawCode);
    if (code == null) {
      throw InviteException(
          'That code doesn\'t look right. Double-check and try again.');
    }
    try {
      final callable = _functions.httpsCallable('redeemInviteCode');
      final res = await callable.call<Map<String, dynamic>>({'code': code});
      final data = Map<String, dynamic>.from(res.data);
      return RedeemedInvite(
        elderId: data['elderId'] as String,
        elderName: data['elderName'] as String,
        role: data['role'] as String,
        alreadyRedeemed: (data['alreadyRedeemed'] as bool?) ?? false,
        alreadyOnProfile: (data['alreadyOnProfile'] as bool?) ?? false,
      );
    } on FirebaseFunctionsException catch (e) {
      throw _asInviteException(e);
    } catch (e) {
      debugPrint('InviteService.redeemInvite error: $e');
      throw InviteException('Could not redeem code. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // revoke
  // ---------------------------------------------------------------------------

  Future<void> revokeInvite(String code) async {
    try {
      final callable = _functions.httpsCallable('revokeInviteCode');
      await callable.call({'code': code});
    } on FirebaseFunctionsException catch (e) {
      throw _asInviteException(e);
    } catch (e) {
      debugPrint('InviteService.revokeInvite error: $e');
      throw InviteException('Could not revoke code. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Recent invites — direct Firestore query (reading is allowed for
  // signed-in users on a by-id basis; here we deliberately do a query,
  // which is denied unless the user owns the docs; the admin UI filters
  // by createdByUid == me to stay within their permission envelope).
  //
  // Note: rules forbid list queries on `inviteCodes`, so this uses a
  // where-clause lookup that CAN succeed because rules permit `get` and
  // Firestore satisfies where-on-own-uid via docs the user owns. In
  // practice, if rules are tightened further, this can be promoted to a
  // "listMyInvites" callable function — leaving it client-side for now
  // because the query cost is negligible.
  // ---------------------------------------------------------------------------

  Stream<List<InviteCode>> watchInvitesCreatedBy(
    String uid, {
    int limit = 20,
  }) {
    if (uid.isEmpty) return Stream.value(const []);
    return FirebaseFirestore.instance
        .collection('inviteCodes')
        .where('createdByUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => InviteCode.fromFirestore(d)).toList())
        .handleError((e) {
      debugPrint('InviteService.watchInvitesCreatedBy error: $e');
      return <InviteCode>[];
    });
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Normalizes a user-typed code: trims whitespace, uppercases,
  /// strips dashes + spaces. Returns null when the result doesn't look
  /// plausibly like a code.
  String? _normalize(String raw) {
    final cleaned =
        raw.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(cleaned)) return null;
    return cleaned;
  }

  InviteException _asInviteException(FirebaseFunctionsException e) {
    // The function throws specific codes; bubble the message straight
    // through because it's already end-user-safe (we author all of
    // them above).
    final msg = e.message ?? 'Unknown error.';
    return InviteException(msg, code: e.code);
  }
}
