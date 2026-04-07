// lib/models/care_task.dart
//
// Delegated care task: title, category, assignee, status, due date.
// Stored under elderProfiles/{elderId}/careTasks.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CareTask {
  final String? id;
  final String elderId;
  final String title;
  final String? description;
  final String category;
  final String createdBy;
  final String createdByName;
  final String? assignedTo;
  final String? assignedToName;
  final String status; // 'open' | 'accepted' | 'completed' | 'declined'
  final DateTime? dueDate;
  final Timestamp? completedAt;
  final String? completionNote;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const CareTask({
    this.id,
    required this.elderId,
    required this.title,
    this.description,
    required this.category,
    required this.createdBy,
    required this.createdByName,
    this.assignedTo,
    this.assignedToName,
    required this.status,
    this.dueDate,
    this.completedAt,
    this.completionNote,
    this.createdAt,
    this.updatedAt,
  });

  static const Map<String, String> kCategoryLabels = {
    'errand': 'Errand',
    'medical': 'Medical',
    'household': 'Household',
    'transport': 'Transportation',
    'financial': 'Financial',
    'other': 'Other',
  };

  static const Map<String, IconData> kCategoryIcons = {
    'errand': Icons.shopping_bag_outlined,
    'medical': Icons.medical_services_outlined,
    'household': Icons.home_outlined,
    'transport': Icons.directions_car_outlined,
    'financial': Icons.attach_money_outlined,
    'other': Icons.assignment_outlined,
  };

  static const Map<String, Color> kCategoryColors = {
    'errand': Color(0xFFF57C00),
    'medical': Color(0xFFD32F2F),
    'household': Color(0xFF00897B),
    'transport': Color(0xFF1E88E5),
    'financial': Color(0xFF6A1B9A),
    'other': Color(0xFF546E7A),
  };

  IconData get categoryIcon =>
      kCategoryIcons[category] ?? Icons.assignment_outlined;
  Color get categoryColor =>
      kCategoryColors[category] ?? const Color(0xFF546E7A);
  String get categoryLabel => kCategoryLabels[category] ?? 'Other';

  bool get isOverdue =>
      dueDate != null &&
      status != 'completed' &&
      status != 'declined' &&
      dueDate!.isBefore(DateTime.now());

  Color get statusColor {
    switch (status) {
      case 'completed':
        return const Color(0xFF43A047);
      case 'accepted':
        return const Color(0xFF1E88E5);
      case 'declined':
        return const Color(0xFF757575);
      default:
        return const Color(0xFFF57C00);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case 'completed':
        return Icons.check_circle_outline;
      case 'accepted':
        return Icons.thumb_up_alt_outlined;
      case 'declined':
        return Icons.do_not_disturb_alt_outlined;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      default:
        return 'Open';
    }
  }

  factory CareTask.fromFirestore(
      String elderId, String id, Map<String, dynamic> data) {
    return CareTask(
      id: id,
      elderId: elderId,
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      category: data['category'] as String? ?? 'other',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      assignedTo: data['assignedTo'] as String?,
      assignedToName: data['assignedToName'] as String?,
      status: data['status'] as String? ?? 'open',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      completedAt: data['completedAt'] as Timestamp?,
      completionNote: data['completionNote'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (description != null) 'description': description,
      'category': category,
      'createdBy': createdBy,
      'createdByName': createdByName,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (assignedToName != null) 'assignedToName': assignedToName,
      'status': status,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (completedAt != null) 'completedAt': completedAt,
      if (completionNote != null) 'completionNote': completionNote,
    };
  }
}
