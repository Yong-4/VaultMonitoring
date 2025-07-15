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
      backgroundColor: const Color(0xFF133052),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDDA853)))
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final sensorType = notification['sensor_type'] as String;
                    final status = notification['status'] as String;
                    
                    // Set default colors - white background for all cards
                    Color cardColor = const Color(0xFFFFFFFF);
                    Color textColor = const Color(0xFF133052);
                    Color borderColor = const Color(0xFF4B79A6);
                    IconData notificationIcon = Icons.notifications;
                    Color iconColor = const Color(0xFF4B79A6);
                    
                    // Change only border color and icon based on notification type
                    if (sensorType == 'Ultrasonic Sensor') {
                      notificationIcon = Icons.radar;
                      
                      if (status == 'very close') {
                        borderColor = Colors.red;
                        iconColor = Colors.red;
                      } else if (status == 'nearby') {
                        borderColor = const Color(0xFFDDA853); // Golden yellow
                        iconColor = const Color(0xFFDDA853);
                      }
                    } 
                    else if (sensorType == 'IR Sensor 1') {
                      notificationIcon = Icons.door_front_door;
                      
                      if (status == 'Vault is open') {
                        borderColor = Colors.red;
                        iconColor = Colors.red;
                      }
                    } 
                    else if (sensorType == 'IR Sensor 2') {
                      notificationIcon = Icons.inventory;
                      
                      if (status.contains('removed from')) {
                        borderColor = Colors.red;
                        iconColor = Colors.red;
                      } else if (status.contains('placed inside')) {
                        borderColor = const Color(0xFF4B79A6);
                        iconColor = const Color(0xFF4B79A6);
                      }
                    }
                    
                    // Format the timestamp
                    String formattedTime = '';
                    if (notification['created_at'] != null) {
                      try {
                        final dateTime = DateTime.parse(notification['created_at']);
                        formattedTime = DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
                      } catch (e) {
                        formattedTime = notification['created_at'];
                      }
                    }
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: borderColor, width: 2),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Icon(
                          notificationIcon,
                          color: iconColor,
                          size: 36,
                        ),
                        title: Text(
                          sensorType,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
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