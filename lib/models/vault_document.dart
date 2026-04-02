// lib/models/vault_document.dart
//
// Data model for legal & financial documents stored in the vault.
// Subcollection: elderProfiles/{elderId}/vaultDocuments
// Storage path: elder_documents/{elderId}/{categorySlug}/{filename}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ── Category definitions ──────────────────────────────────────────

class VaultCategory {
  final String name;
  final String slug;
  final IconData icon;
  final Color color;

  const VaultCategory({
    required this.name,
    required this.slug,
    required this.icon,
    required this.color,
  });

  static const List<VaultCategory> all = [
    // Legal
    VaultCategory(
        name: 'Power of Attorney',
        slug: 'power_of_attorney',
        icon: Icons.gavel,
        color: Color(0xFF3949AB)),
    VaultCategory(
        name: 'Advance Directive',
        slug: 'advance_directive',
        icon: Icons.gavel,
        color: Color(0xFF3949AB)),
    VaultCategory(
        name: 'Living Will',
        slug: 'living_will',
        icon: Icons.gavel,
        color: Color(0xFF3949AB)),
    VaultCategory(
        name: 'DNR Order',
        slug: 'dnr_order',
        icon: Icons.gavel,
        color: Color(0xFF3949AB)),
    VaultCategory(
        name: 'Guardianship Papers',
        slug: 'guardianship_papers',
        icon: Icons.gavel,
        color: Color(0xFF3949AB)),

    // Insurance
    VaultCategory(
        name: 'Insurance Card',
        slug: 'insurance_card',
        icon: Icons.shield_outlined,
        color: Color(0xFF00897B)),
    VaultCategory(
        name: 'Health Insurance',
        slug: 'health_insurance',
        icon: Icons.shield_outlined,
        color: Color(0xFF00897B)),
    VaultCategory(
        name: 'HIPAA Authorization',
        slug: 'hipaa_authorization',
        icon: Icons.shield_outlined,
        color: Color(0xFF00897B)),

    // Medical
    VaultCategory(
        name: 'Medical Records',
        slug: 'medical_records',
        icon: Icons.local_hospital_outlined,
        color: Color(0xFFE53935)),
    VaultCategory(
        name: 'Prescription Records',
        slug: 'prescription_records',
        icon: Icons.local_hospital_outlined,
        color: Color(0xFFE53935)),

    // Financial
    VaultCategory(
        name: 'Financial Records',
        slug: 'financial_records',
        icon: Icons.account_balance_outlined,
        color: Color(0xFFF57C00)),
    VaultCategory(
        name: 'Tax Documents',
        slug: 'tax_documents',
        icon: Icons.account_balance_outlined,
        color: Color(0xFFF57C00)),

    // General
    VaultCategory(
        name: 'Other',
        slug: 'other',
        icon: Icons.folder_outlined,
        color: Color(0xFF546E7A)),
  ];

  /// Lookup by name. Returns 'Other' if not found.
  static VaultCategory fromName(String name) {
    return all.firstWhere(
      (c) => c.name == name,
      orElse: () => all.last, // 'Other'
    );
  }

  /// Category names grouped for display.
  static const Map<String, List<String>> grouped = {
    'Legal': [
      'Power of Attorney',
      'Advance Directive',
      'Living Will',
      'DNR Order',
      'Guardianship Papers',
    ],
    'Insurance': [
      'Insurance Card',
      'Health Insurance',
      'HIPAA Authorization',
    ],
    'Medical': [
      'Medical Records',
      'Prescription Records',
    ],
    'Financial': [
      'Financial Records',
      'Tax Documents',
    ],
    'General': [
      'Other',
    ],
  };
}

// ── Document model ────────────────────────────────────────────────

class VaultDocument {
  final String? id;
  final String name;
  final String category;
  final String? notes;
  final String fileUrl;
  final String storagePath;
  final String? mimeType;
  final int? fileSize;
  final String uploadedBy;
  final String uploadedByName;
  final String elderId;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const VaultDocument({
    this.id,
    required this.name,
    required this.category,
    this.notes,
    required this.fileUrl,
    required this.storagePath,
    this.mimeType,
    this.fileSize,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.elderId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isImage =>
      mimeType != null && mimeType!.startsWith('image/');

  bool get isPdf =>
      mimeType == 'application/pdf';

  VaultCategory get categoryInfo => VaultCategory.fromName(category);

  factory VaultDocument.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return VaultDocument(
      id: docId,
      name: data['name'] as String? ?? 'Unnamed',
      category: data['category'] as String? ?? 'Other',
      notes: data['notes'] as String?,
      fileUrl: data['fileUrl'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      mimeType: data['mimeType'] as String?,
      fileSize: data['fileSize'] as int?,
      uploadedBy: data['uploadedBy'] as String? ?? '',
      uploadedByName: data['uploadedByName'] as String? ?? '',
      elderId: data['elderId'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'category': category,
        'notes': notes,
        'fileUrl': fileUrl,
        'storagePath': storagePath,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'uploadedBy': uploadedBy,
        'uploadedByName': uploadedByName,
        'elderId': elderId,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  VaultDocument copyWith({
    String? id,
    String? name,
    String? category,
    String? notes,
    String? fileUrl,
    String? storagePath,
    String? mimeType,
    int? fileSize,
    String? uploadedBy,
    String? uploadedByName,
    String? elderId,
  }) =>
      VaultDocument(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        notes: notes ?? this.notes,
        fileUrl: fileUrl ?? this.fileUrl,
        storagePath: storagePath ?? this.storagePath,
        mimeType: mimeType ?? this.mimeType,
        fileSize: fileSize ?? this.fileSize,
        uploadedBy: uploadedBy ?? this.uploadedBy,
        uploadedByName: uploadedByName ?? this.uploadedByName,
        elderId: elderId ?? this.elderId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  /// Human-readable file size.
  String get fileSizeLabel {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(0)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
