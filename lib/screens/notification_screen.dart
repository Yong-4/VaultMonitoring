import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/alert_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];  
  bool isLoading = true;
  Timer? _timer;
  
  // Track alert states
  String? lastUltrasonicStatus;
  String? lastIR1Status;
  String? lastIR2Status;
  bool isAuthorizedAccess = false; // Set to true when access is authorized
  
  // Alert service instance
  final AlertService _alertService = AlertService();

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
  
  void _checkForAlerts(List<Map<String, dynamic>> allNotifications) {
    if (allNotifications.isEmpty) return;
    
    // Get latest notification for each sensor type
    final Map<String, Map<String, dynamic>> latestBySensor = {};
    
    for (final notification in allNotifications) {
      final sensorType = notification['sensor_type'] as String;
      if (!latestBySensor.containsKey(sensorType)) {
        latestBySensor[sensorType] = notification;
      }
    }
    
    // Check for critical alerts
    latestBySensor.forEach((sensorType, notification) {
      final status = notification['status'] as String;
      
      // 1. Check for very close proximity
      if (sensorType == 'Ultrasonic Sensor' && status == 'very close') {
        if (lastUltrasonicStatus != 'very close') {
          _alertService.showAlert(
            context,
            'INTRUDER ALERT', 
            'Someone is very close to the vault!', 
            Colors.red[800]!
          );
        }
      }
      
      // 2. Check if vault is open
      if (sensorType == 'IR Sensor 1' && status == 'Vault is open') {
        if (lastIR1Status != 'Vault is open') {
          _alertService.showAlert(
            context,
            'SECURITY ALERT', 
            'The vault has been opened!', 
            Colors.red[900]!
          );
        }
      }
      
      // 3. Check for unauthorized removals
      if (sensorType == 'IR Sensor 2' && status.contains('removed from')) {
        if (lastIR2Status != status && !isAuthorizedAccess) {
          _alertService.showAlert(
            context,
            'UNAUTHORIZED REMOVAL', 
            'An item has been removed without authorization!', 
            Colors.orange[900]!
          );
        }
      }
      
      // Update status tracking
      if (sensorType == 'Ultrasonic Sensor') lastUltrasonicStatus = status;
      if (sensorType == 'IR Sensor 1') lastIR1Status = status;
      if (sensorType == 'IR Sensor 2') lastIR2Status = status;
    });
  }

  Future<void> fetchNotifications() async {
    try {
      final irResponse = await Supabase.instance.client
          .from('irsensor1_logs')
          .select()
          .order('created_at', ascending: false);

      final irSensor2Response = await Supabase.instance.client
          .from('irsensor2_logs')
          .select()
          .order('created_at', ascending: false);

      final ultrasonicResponse = await Supabase.instance.client
          .from('ultrasonic_logs')
          .select()
          .order('created_at', ascending: false);

      // Combine all notifications
      final allNotifications = [
        ...List<Map<String, dynamic>>.from(irResponse as List),
        ...List<Map<String, dynamic>>.from(irSensor2Response as List),
        ...List<Map<String, dynamic>>.from(ultrasonicResponse as List),
      ];

      // Sort by created_at descending
      allNotifications.sort((a, b) =>
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));
          
      // Check for alerts before filtering
      _checkForAlerts(allNotifications);

      // Filter out consecutive notifications with the same status for the same sensor
      final filteredNotifications = <Map<String, dynamic>>[];
      final processedStatuses = <String, String>{};  // Map of sensor_type to last status

      for (final notification in allNotifications) {
        final sensorType = notification['sensor_type'] as String;
        final status = notification['status'] as String;
        
        // If this sensor type hasn't been seen yet or status has changed, include the notification
        if (!processedStatuses.containsKey(sensorType) || processedStatuses[sensorType] != status) {
          filteredNotifications.add(notification);
          processedStatuses[sensorType] = status;
        }
      }

      if (!mounted) return;

      setState(() {
        notifications = filteredNotifications;
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
                } else if (notification['sensor_type'] == 'IR Sensor 2') {
                  // Check placement/removal status
                  final status = notification['status'] as String;
                  if (status.contains('placed inside')) {
                    iconData = Icons.add_box;
                    iconColor = Colors.green;
                  } else if (status.contains('removed from')) {
                    iconData = Icons.remove_circle;
                    iconColor = Colors.orange;
                  } else {
                    iconData = Icons.info;
                    iconColor = const Color(0xFF2DFBB2);
                  }
                } else {
                  // Default for IR sensor 1
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