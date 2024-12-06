import 'package:flutter/material.dart';
import 'package:health/presentation/screens/start.dart';
import '../controller/notification_controller.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../widgets/language.widgets.dart';

class NotificationScreen extends StatefulWidget {
  final UserRole userRole;

  const NotificationScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController _notificationController = NotificationController();
  late List<NotificationModel> _notifications;
  late ValueNotifier<int> _unreadCountNotifier;

  @override
  void initState() {
    super.initState();
    _notifications = _notificationController.getNotificationsForRole(widget.userRole);


    switch (widget.userRole) {
      case UserRole.patient:
        _unreadCountNotifier = _notificationController.patientUnreadCount;
        break;
      case UserRole.doctor:
        _unreadCountNotifier = _notificationController.doctorUnreadCount;
        break;
      case UserRole.admin:
        _unreadCountNotifier = _notificationController.adminUnreadCount;
        break;
    }
  }
  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text('${_getRoleName(widget.userRole)} ${localizations?.notification}'),
        actions: [
          const LanguageToggle(),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              _notificationController.clearNotifications(widget.userRole);
              setState(() {});
            },
          )
        ],
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: _unreadCountNotifier,
        builder: (context, unreadCount, child) {
          final localizations = AppLocalizations.of(context);
          return _notifications.isEmpty
              ? Center(
            child: Text(localizations!.no_notification,
              style: const TextStyle(fontSize: 18),
            ),
          )
              : ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final notification = _notifications[index];
              return ListTile(
                title: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  notification.body,
                  style: TextStyle(
                    color: notification.isRead ? Colors.grey : Colors.black,
                  ),
                ),
                trailing: Text(
                  _formatTimestamp(notification.timestamp),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  _notificationController.markNotificationAsRead(
                      notification.id,
                      widget.userRole
                  );
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }

  // Helper method to get role name
  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  // Format timestamp method
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}