import 'package:inspecao/models/user.dart';

enum NotificationType {
  inspection_assigned,
  inspection_updated,
  inspection_completed,
  inspection_status_update,
  system_alert,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final User? sender;
  final String? relatedId; // ID da inspeção, mensagem, etc.
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.sender,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    User? sender,
    String? relatedId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      sender: sender ?? this.sender,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.name,
    'priority': priority.name,
    'sender': sender?.toJson(),
    'relatedId': relatedId,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'],
    title: json['title'],
    message: json['message'],
    type: NotificationType.values.byName(json['type']),
    priority: NotificationPriority.values.byName(json['priority']),
    sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
    relatedId: json['relatedId'],
    createdAt: DateTime.parse(json['createdAt']),
    isRead: json['isRead'] ?? false,
    data: json['data'],
  );

  String get timeText {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }

  String get typeText {
    switch (type) {
      case NotificationType.inspection_assigned:
        return 'Inspeção Atribuída';
      case NotificationType.inspection_updated:
        return 'Inspeção Atualizada';
      case NotificationType.inspection_completed:
        return 'Inspeção Concluída';
      case NotificationType.inspection_status_update:
        return 'Status Atualizado';
      case NotificationType.system_alert:
        return 'Alerta do Sistema';
    }
  }

  String get priorityText {
    switch (priority) {
      case NotificationPriority.low:
        return 'Baixa';
      case NotificationPriority.medium:
        return 'Média';
      case NotificationPriority.high:
        return 'Alta';
      case NotificationPriority.urgent:
        return 'Urgente';
    }
  }
}
