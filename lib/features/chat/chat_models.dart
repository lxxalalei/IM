import 'package:flutter/material.dart';

enum ConversationType { direct, group, bot, system }

class Conversation {
  const Conversation({
    required this.id,
    required this.type,
    required this.title,
    required this.avatarLabel,
    required this.avatarColor,
    required this.lastMessage,
    required this.lastMessageTime,
    this.tags = const [],
    this.unreadCount = 0,
    this.isPinned = false,
  });

  final String id;
  final ConversationType type;
  final String title;
  final String avatarLabel;
  final Color avatarColor;
  final String lastMessage;
  final String lastMessageTime;
  final List<String> tags;
  final int unreadCount;
  final bool isPinned;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      type: _conversationTypeFromJson(json['type'] as String?),
      title: json['title'] as String,
      avatarLabel: json['avatarLabel'] as String,
      avatarColor: colorFromHex(json['avatarColor'] as String?),
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: formatConversationTime(json['lastMessageAt'] as String?),
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag.toString())
          .toList(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Conversation copyWith({
    String? id,
    ConversationType? type,
    String? title,
    String? avatarLabel,
    Color? avatarColor,
    String? lastMessage,
    String? lastMessageTime,
    List<String>? tags,
    int? unreadCount,
    bool? isPinned,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      avatarLabel: avatarLabel ?? this.avatarLabel,
      avatarColor: avatarColor ?? this.avatarColor,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      tags: tags ?? this.tags,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderName,
    required this.content,
    required this.time,
    required this.isMine,
    this.isSystem = false,
  });

  final String id;
  final String senderName;
  final String content;
  final String time;
  final bool isMine;
  final bool isSystem;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderName: json['senderName'] as String? ?? '',
      content: json['content'] as String? ?? '',
      time: formatMessageTime(json['createdAt'] as String?),
      isMine: json['isMine'] as bool? ?? false,
    );
  }
}

class NavItemData {
  const NavItemData({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

ConversationType _conversationTypeFromJson(String? value) {
  return switch (value) {
    'group' => ConversationType.group,
    'bot' => ConversationType.bot,
    'system' => ConversationType.system,
    _ => ConversationType.direct,
  };
}

Color colorFromHex(String? value) {
  final normalized = value?.replaceFirst('#', '');
  if (normalized == null || normalized.length != 6) {
    return Colors.blueGrey;
  }

  return Color(int.parse('FF$normalized', radix: 16));
}

String formatConversationTime(String? isoValue) {
  final value = _parseDate(isoValue);
  if (value == null) {
    return '';
  }

  final now = DateTime.now();
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

  return '${value.month}月${value.day}日';
}

String formatMessageTime(String? isoValue) {
  final value = _parseDate(isoValue);
  if (value == null) {
    return '';
  }

  return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value)?.toLocal();
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');
