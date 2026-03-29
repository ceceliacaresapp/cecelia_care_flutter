// lib/models/caregiver_role.dart
//
// Single source of truth for the three permission tiers in Cecelia Care.
//
// Role assignment:
//   admin    — uid == ElderProfile.primaryAdminUserId.
//              Full access. All write, manage, and admin operations.
//
//   caregiver — uid in ElderProfile.caregiverRoles with value "caregiver".
//              Can log all entry types, mark meds taken/skipped, send messages,
//              view timeline/calendar/expenses. Cannot add/edit/delete
//              medication definitions, cannot manage elder profiles or
//              caregivers, cannot access Budget or invite others.
//
//   viewer   — uid in ElderProfile.caregiverRoles with value "viewer".
//              Read-only access to timeline and calendar. No logging,
//              no messages, no management actions.
//
//   unknown  — uid not found in this elder's caregiverUserIds at all.
//              Treated as viewer to be safe.

enum CaregiverRole { admin, caregiver, viewer, unknown }

extension CaregiverRoleX on CaregiverRole {
  /// Human-readable label shown in the invite dialog role picker.
  String get label {
    switch (this) {
      case CaregiverRole.admin:
        return 'Admin';
      case CaregiverRole.caregiver:
        return 'Caregiver';
      case CaregiverRole.viewer:
        return 'Viewer';
      case CaregiverRole.unknown:
        return 'Unknown';
    }
  }

  /// Short description shown below the role label in the picker.
  String get description {
    switch (this) {
      case CaregiverRole.admin:
        return 'Full access — manage profiles, medications, and caregivers';
      case CaregiverRole.caregiver:
        return 'Can log entries and send messages, cannot manage profiles';
      case CaregiverRole.viewer:
        return 'Read-only — can view the timeline but cannot log anything';
      case CaregiverRole.unknown:
        return '';
    }
  }

  /// The string value stored in Firestore under caregiverRoles.{uid}.
  String get firestoreValue {
    switch (this) {
      case CaregiverRole.admin:
        return 'admin';
      case CaregiverRole.caregiver:
        return 'caregiver';
      case CaregiverRole.viewer:
        return 'viewer';
      case CaregiverRole.unknown:
        return 'viewer'; // safe fallback
    }
  }

  /// Parses the Firestore string back to a role.
  static CaregiverRole fromString(String? value) {
    switch (value) {
      case 'admin':
        return CaregiverRole.admin;
      case 'caregiver':
        return CaregiverRole.caregiver;
      case 'viewer':
        return CaregiverRole.viewer;
      default:
        return CaregiverRole.unknown;
    }
  }

  // ---------------------------------------------------------------------------
  // Permission gates — use these throughout the UI and Firestore rules.
  // ---------------------------------------------------------------------------

  /// Can write journal entries (log mood, meal, sleep, vitals, pain, activity).
  bool get canLog => this == CaregiverRole.admin || this == CaregiverRole.caregiver;

  /// Can post messages on the timeline.
  bool get canMessage => this == CaregiverRole.admin || this == CaregiverRole.caregiver;

  /// Can mark medications as taken or skipped.
  bool get canMarkMedications =>
      this == CaregiverRole.admin || this == CaregiverRole.caregiver;

  /// Can add, edit, or delete medication *definitions* (the prescription record).
  bool get canManageMedicationDefinitions => this == CaregiverRole.admin;

  /// Can manage an existing elder profile — edit, invite, remove caregivers.
  /// Only admins of that profile can do this.
  bool get canManageProfiles => this == CaregiverRole.admin;

  /// Can access the Manage Care Recipients screen.
  /// ALL roles can access this screen because any user should be able to
  /// create their own care recipient profile (becoming admin of it).
  bool get canAccessProfilesScreen => true;

  /// Can access the Budget screen.
  bool get canAccessBudget => this == CaregiverRole.admin;

  /// Can export care logs.
  bool get canExport =>
      this == CaregiverRole.admin || this == CaregiverRole.caregiver;

  /// Can view the timeline (all roles can read).
  bool get canViewTimeline => this != CaregiverRole.unknown;
}
