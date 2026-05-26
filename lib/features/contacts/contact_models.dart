import 'package:flutter/material.dart';

import '../chat/chat_models.dart';

class Contact {
  const Contact({
    required this.id,
    required this.name,
    required this.avatarLabel,
    required this.avatarColor,
    required this.department,
    required this.title,
    required this.email,
    required this.status,
    required this.isExternal,
    required this.isFavorite,
  });

  final String id;
  final String name;
  final String avatarLabel;
  final Color avatarColor;
  final String department;
  final String title;
  final String email;
  final String status;
  final bool isExternal;
  final bool isFavorite;

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarLabel: json['avatarLabel'] as String,
      avatarColor: colorFromHex(json['avatarColor'] as String?),
      department: json['department'] as String? ?? '',
      title: json['title'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      isExternal: json['isExternal'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
