import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum NotificationType {
  appointment,
  consultation,
  reminder,
  general
}

class NotificationController {
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  List<NotificationModel> notifications = [];
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  void addNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
  }) {
    final notification = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
    );
    notifications.insert(0, notification);
    unreadCount.value++;
  }

  void markNotificationAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      if (!notifications[index].isRead) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        unreadCount.value--;
      }
    }
  }

  void clearNotifications() {
    notifications.clear();
    unreadCount.value = 0;
  }
}
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });

  // Add copyWith method
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is NotificationModel &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              title == other.title &&
              body == other.body &&
              timestamp == other.timestamp &&
              type == other.type &&
              isRead == other.isRead;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      body.hashCode ^
      timestamp.hashCode ^
      type.hashCode ^
      isRead.hashCode;
}
