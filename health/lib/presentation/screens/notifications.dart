import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:health/presentation/screens/start.dart';
import '../controller/notification_controller.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationController _notificationController = NotificationController();

  void navigateToScreen(Widget screen) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            navigateToScreen(Start());
          },
        ),
        title: Text(localizations.notification),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_remove_sharp),
            onPressed: () {
              _notificationController.clearNotifications();
              setState(() {});
            },
          )
        ],
      ),
      body: _notificationController.notifications.isEmpty
          ? Center(
        child: Text(
          localizations.no_notification,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      )
          : ListView.builder(
        itemCount: _notificationController.notifications.length,
        itemBuilder: (context, index) {
          final notification = _notificationController.notifications[index];
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
              _notificationController.markNotificationAsRead(notification.id);
              setState(() {});
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}
