import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

void showNotificationsDialog(
    BuildContext context, List<Map<String, dynamic>> notifications) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (notifications.isEmpty)
              const Text('No notifications')
            else
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return ListTile(
                      title: Text(notification['message']),
                      subtitle: Text(
                        DateTime.parse(
                          notification['timestamp'],
                        ).toString(),
                      ),
                      trailing: notification['read']
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                await NotificationService.markAsRead(
                                  notification['id'],
                                );
                                // Need to use setState in parent widget
                              },
                            ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}

void showSettingsDialog(
    BuildContext context,
    bool notificationsEnabled,
    bool isDarkMode,
    Function(bool) toggleNotifications,
    Function(bool) toggleTheme) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: Switch(
                value: notificationsEnabled,
                onChanged: toggleNotifications,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: isDarkMode,
                onChanged: toggleTheme,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}
