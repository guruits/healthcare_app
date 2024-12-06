import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Enum for different notification types and roles
enum NotificationType {
  appointment,
  consultation,
  reminder,
  general
}

enum UserRole {
  patient,
  doctor,
  admin
}

// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  final UserRole recipient;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    required this.recipient,
    this.isRead = false,
  });

  // Copy with method for immutable updates
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? timestamp,
    NotificationType? type,
    UserRole? recipient,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      recipient: recipient ?? this.recipient,
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
              recipient == other.recipient &&
              isRead == other.isRead;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      body.hashCode ^
      timestamp.hashCode ^
      type.hashCode ^
      recipient.hashCode ^
      isRead.hashCode;
}

// Notification Controller
class NotificationController {
  // Singleton pattern
  static final NotificationController _instance = NotificationController._internal();
  factory NotificationController() => _instance;
  NotificationController._internal();

  // Separate notification lists for different roles
  List<NotificationModel> patientNotifications = [];
  List<NotificationModel> doctorNotifications = [];
  List<NotificationModel> adminNotifications = [];

  final ValueNotifier<int> patientUnreadCount = ValueNotifier(0);
  final ValueNotifier<int> doctorUnreadCount = ValueNotifier(0);
  final ValueNotifier<int> adminUnreadCount = ValueNotifier(0);

  // Alternative unique ID generation without UUID
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000000);
    return '$timestamp-$random';
  }

  // Method to add appointment notification for multiple roles
  void addAppointmentNotification({
    required String patientName,
    required String doctorName,
    required DateTime appointmentDate,
    required String appointmentDetails,
  }) {
    // Notification for Patient
    final patientNotification = NotificationModel(

      id: _generateUniqueId(),
      title: 'Appointment Confirmed',
      body: 'Your appointment with Dr. $doctorName is scheduled for '
          '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}. '
          'Details: $appointmentDetails',
      timestamp: DateTime.now(),
      type: NotificationType.appointment,
      recipient: UserRole.patient,
    );

    // Notification for Doctor
    final doctorNotification = NotificationModel(
      id: _generateUniqueId(),
      title: 'New Appointment',
      body: 'New appointment scheduled with $patientName for '
          '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}. '
          'Details: $appointmentDetails',
      timestamp: DateTime.now(),
      type: NotificationType.appointment,
      recipient: UserRole.doctor,
    );
    // Notification for Patient

    final adminNotification = NotificationModel(
      id: _generateUniqueId(),
      title: 'New Appointment Scheduled',
      body: 'Appointment scheduled between $patientName and Dr. $doctorName '
          'on ${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}. '
          'Details: $appointmentDetails',
      timestamp: DateTime.now(),
      type: NotificationType.appointment,
      recipient: UserRole.admin,
    );

    // Insert notifications at the beginning of respective lists
    patientNotifications.insert(0, patientNotification);
    doctorNotifications.insert(0, doctorNotification);
    adminNotifications.insert(0, adminNotification);

    // Increment unread counts
    patientUnreadCount.value++;
    doctorUnreadCount.value++;
    adminUnreadCount.value++;
  }

  // Method to get notifications for a specific role
  List<NotificationModel> getNotificationsForRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return patientNotifications;
      case UserRole.doctor:
        return doctorNotifications;
      case UserRole.admin:
        return adminNotifications;
    }
  }

  // Method to mark notification as read
  void markNotificationAsRead(String id, UserRole role) {
    List<NotificationModel> notificationList;
    ValueNotifier<int> unreadCountNotifier;

    switch (role) {
      case UserRole.patient:
        notificationList = patientNotifications;
        unreadCountNotifier = patientUnreadCount;
        break;
      case UserRole.doctor:
        notificationList = doctorNotifications;
        unreadCountNotifier = doctorUnreadCount;
        break;
      case UserRole.admin:
        notificationList = adminNotifications;
        unreadCountNotifier = adminUnreadCount;
        break;
    }

    final index = notificationList.indexWhere((n) => n.id == id);
    if (index != -1) {
      if (!notificationList[index].isRead) {
        notificationList[index] = notificationList[index].copyWith(isRead: true);
        unreadCountNotifier.value--;
      }
    }
  }

  // Method to clear notifications for a specific role
  void clearNotifications(UserRole role) {
    switch (role) {
      case UserRole.patient:
        patientNotifications.clear();
        patientUnreadCount.value = 0;
        break;
      case UserRole.doctor:
        doctorNotifications.clear();
        doctorUnreadCount.value = 0;
        break;
      case UserRole.admin:
        adminNotifications.clear();
        adminUnreadCount.value = 0;
        break;
    }
  }
}