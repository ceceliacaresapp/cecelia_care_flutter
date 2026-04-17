// lib/models/invite_code.dart
//
// Client-side view of an invite code document. Authoring + redemption
// happen in Cloud Functions (see functions/index.js) — this class just
// deserializes what the server wrote so the admin UI can show codes
// back to the caregiver who created them, along with their expiry
// and use status.
//
// Storage: `inviteCodes/{code}` — top-level, doc id IS the code. This
// makes redemption a single O(1) get() without a query, and keeps
// the code case-preserved.
//
// Security: clients CANNOT write to this collection directly (rules
// deny all writes). Every create / redeem / revoke goes through a
// callable Cloud Function that verifies the caller's role.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Lifecycle states for an invite code.
enum InviteCodeStatus {
  active, // not yet fully redeemed, not expired, not revoked
  expired, // server-observed expiry (also enforced in rules/functions)
  revoked, // explicitly revoked by an admin
  exhausted, // maxUses reached
  unknown, // defensive default when reading an unknown string
}

extension InviteCodeStatusX on InviteCodeStatus {
  String get label {
    switch (this) {
      case InviteCodeStatus.active:
        return 'Active';
      case InviteCodeStatus.expired:
        return 'Expired';
      case InviteCodeStatus.revoked:
        return 'Revoked';
      case InviteCodeStatus.exhausted:
        return 'All uses claimed';
      case InviteCodeStatus.unknown:
        return 'Unknown';
    }
  }

  String get firestoreValue {
    switch (this) {
      case InviteCodeStatus.active:
        return 'active';
      case InviteCodeStatus.expired:
        return 'expired';
      case InviteCodeStatus.revoked:
        return 'revoked';
      case InviteCodeStatus.exhausted:
        return 'exhausted';
      case InviteCodeStatus.unknown:
        return 'unknown';
    }
  }

  static InviteCodeStatus fromString(String? s) {
    switch (s) {
      case 'active':
        return InviteCodeStatus.active;
      case 'expired':
        return InviteCodeStatus.expired;
      case 'revoked':
        return InviteCodeStatus.revoked;
      case 'exhausted':
        return InviteCodeStatus.exhausted;
      default:
        return InviteCodeStatus.unknown;
    }
  }
}

/// The invite code record a caregiver creates.
class InviteCode {
  /// The code itself — 8 uppercase alphanumerics excluding ambiguous
  /// characters (0/O, 1/I/L). Also the Firestore doc id.
  final String code;

  final String elderId;

  /// Denormalized for display in the redemption UI without requiring the
  /// redeemer to have read access to the elder profile (they don't yet).
  final String elderName;

  /// Role to grant the redeemer. Default 'viewer' to match the spec —
  /// the "family portal" use case. Admins can choose 'caregiver' from
  /// the create-invite UI when inviting a paid / pro caregiver.
  final String role;

  final String createdByUid;
  final String? createdByName;

  final Timestamp createdAt;
  final Timestamp expiresAt;

  final int maxUses;
  final int uses;

  /// UIDs that have successfully redeemed this code. Prevents a single
  /// user from redeeming twice and seeds the audit trail.
  final List<String> redeemedByUids;

  final InviteCodeStatus status;

  const InviteCode({
    required this.code,
    required this.elderId,
    required this.elderName,
    required this.role,
    required this.createdByUid,
    this.createdByName,
    required this.createdAt,
    required this.expiresAt,
    this.maxUses = 1,
    this.uses = 0,
    this.redeemedByUids = const [],
    this.status = InviteCodeStatus.active,
  });

  // ---------------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------------

  bool get isExpired => DateTime.now().isAfter(expiresAt.toDate());

  bool get isUsable =>
      status == InviteCodeStatus.active && !isExpired && uses < maxUses;

  int get remainingUses => (maxUses - uses).clamp(0, maxUses);

  Duration get timeUntilExpiry =>
      expiresAt.toDate().difference(DateTime.now());

  /// The effective status, accounting for client-observed expiry even
  /// if the server hasn't swept the doc yet.
  InviteCodeStatus get effectiveStatus {
    if (status != InviteCodeStatus.active) return status;
    if (isExpired) return InviteCodeStatus.expired;
    if (uses >= maxUses) return InviteCodeStatus.exhausted;
    return InviteCodeStatus.active;
  }

  /// Shareable URL. Universal-link / App-Link setup on Android & iOS is
  /// required before taps route directly into the app — until that
  /// infra lands, the link works as a visible fallback pointing at the
  /// eventual landing page, and users can copy/paste the code instead.
  String get shareUrl => 'https://ceceliacare.app/invite/$code';

  /// A human-readable one-line invitation body. The admin can edit it
  /// before handing it off via share-sheet.
  String invitationMessage(String inviterName) =>
      '$inviterName invited you to help care for $elderName on Cecelia Care.\n\n'
      'Open the app and tap "I have an invite code", then enter:\n'
      '    $code\n\n'
      '(Or use the link: $shareUrl)';

  // ---------------------------------------------------------------------------
  // Firestore
  // ---------------------------------------------------------------------------

  factory InviteCode.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap, [
    SnapshotOptions? _,
  ]) {
    final data = snap.data() ?? const <String, dynamic>{};
    return InviteCode(
      code: snap.id,
      elderId: data['elderId'] as String? ?? '',
      elderName: data['elderName'] as String? ?? '',
      role: data['role'] as String? ?? 'viewer',
      createdByUid: data['createdByUid'] as String? ?? '',
      createdByName: data['createdByName'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiresAt: data['expiresAt'] as Timestamp? ??
          Timestamp.fromDate(DateTime.now()),
      maxUses: (data['maxUses'] as num?)?.toInt() ?? 1,
      uses: (data['uses'] as num?)?.toInt() ?? 0,
      redeemedByUids: (data['redeemedByUids'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      status: InviteCodeStatusX.fromString(data['status'] as String?),
    );
  }
}
