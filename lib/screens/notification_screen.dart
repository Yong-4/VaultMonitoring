import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      fetchNotifications();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchNotifications() async {
    try {
      final irResponse = await Supabase.instance.client
          .from('irsensor1_logs')
          .select()
          .order('created_at', ascending: false);

      final ultrasonicResponse = await Supabase.instance.client
          .from('ultrasonic_logs')
          .select()
          .order('created_at', ascending: false);

      // Combine and sort all notifications by created_at descending
      final allNotifications = [
        ...List<Map<String, dynamic>>.from(irResponse as List),
        ...List<Map<String, dynamic>>.from(ultrasonicResponse as List),
      ];

      allNotifications.sort((a, b) =>
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

      if (!mounted) return;

      setState(() {
        notifications = allNotifications;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMMM d, y').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  String formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return dateTimeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A1B),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];

                IconData iconData = Icons.notifications;
                Color iconColor = const Color(0xFF2DFBB2);

                if (notification['sensor_type'] == 'Ultrasonic Sensor') {
                  switch (notification['status']) {
                    case 'very close':
                      iconData = Icons.warning_amber_rounded;
                      iconColor = Colors.redAccent;
                      break;
                    case 'nearby':
                      iconData = Icons.warning_amber_rounded;
                      iconColor = Colors.amber;
                      break;
                    case 'approaching area':
                      iconData = Icons.warning_amber_rounded;
                      iconColor = const Color(0xFF2DFBB2);
                      break;
                    case 'detected far':
                    case 'area clear':
                      iconData = Icons.notifications;
                      iconColor = const Color(0xFF2DFBB2);
                      break;
                    default:
                      iconData = Icons.notifications;
                      iconColor = const Color(0xFF2DFBB2);
                  }
                } else {
                  // Default for IR sensor
                  iconData = notification['status'] == 'Vault is open'
                      ? Icons.lock_open
                      : Icons.lock;
                  iconColor = notification['status'] == 'Vault is open'
                      ? Colors.redAccent
                      : const Color(0xFF2DFBB2);
                }

                return Card(
                  color: Colors.grey[850],
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: Icon(
                      iconData,
                      color: iconColor,
                    ),
                    title: Text(
                      notification['sensor_type'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      notification['status'] ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatDate(notification['created_at']?.toString()),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        Text(
                          formatTime(notification['created_at']?.toString()),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}