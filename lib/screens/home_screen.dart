import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/alert_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String doorStatus = 'Loading...';
  IconData doorIcon = Icons.lock;
  Color doorIconColor = Color(0xFF2DFBB2);

  String intruderStatus = 'Loading...';
  IconData intruderIcon = Icons.notifications;
  Color intruderIconColor = Color(0xFF2DFBB2);

  String itemStatus = 'Loading...';
  IconData itemIcon = Icons.verified_user;
  Color itemIconColor = Color(0xFF2DFBB2);

  String systemState = 'Loading...';

  Timer? _refreshTimer;
  
  // Track last status to detect changes
  String? lastUltrasonicStatus;
  String? lastIR1Status;
  String? lastIR2Status;
  bool isAuthorizedAccess = false;
  
  // Alert service instance
  final AlertService _alertService = AlertService();

  @override
  void initState() {
    super.initState();
    fetchAll();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      fetchAll();
    });
  }

  void fetchAll() {
    fetchSystemState();
    fetchLatestDoorStatus();
    fetchLatestIntruderStatus();
    fetchLatestItemStatus();
  }

  Future<void> fetchLatestDoorStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('irsensor1_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final latest = response.first;
        if (mounted) {
          setState(() {
            doorStatus = latest['status'] ?? 'Unknown';
            if (doorStatus == 'Vault is open') {
              doorIcon = Icons.lock_open;
              doorIconColor = Colors.redAccent;
              
              // Check for alert - only when status changes
              if (lastIR1Status != 'Vault is open') {
                _alertService.showAlert(
                  context,
                  'SECURITY ALERT', 
                  'The vault has been opened!', 
                  Colors.red[900]!
                );
              }
            } else {
              doorIcon = Icons.lock;
              doorIconColor = Color(0xFF2DFBB2);
            }
            
            // Update last status
            lastIR1Status = doorStatus;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          doorStatus = 'Error fetching status';
        });
      }
    }
  }

  Future<void> fetchLatestItemStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('irsensor2_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final latest = response.first;
        if (mounted) {
          setState(() {
            itemStatus = latest['status'] ?? 'Unknown';
            if (itemStatus == 'Item has been removed from the vault') {
              itemIcon = Icons.remove_circle_outline;
              itemIconColor = Colors.redAccent;
              
              // Check if status changed and access is not authorized
              if (lastIR2Status != itemStatus && !isAuthorizedAccess) {
                _alertService.showAlert(
                  context,
                  'UNAUTHORIZED REMOVAL', 
                  'An item has been removed without authorization!', 
                  Colors.orange[900]!
                );
              }
            } else if (itemStatus == 'Item has been placed inside the vault') {
              itemIcon = Icons.check_circle_outline;
              itemIconColor = Color(0xFF2DFBB2);
            } else {
              itemIcon = Icons.verified_user;
              itemIconColor = Color(0xFF2DFBB2);
            }
            
            // Update last status
            lastIR2Status = itemStatus;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          itemStatus = 'Error fetching status';
          itemIcon = Icons.error;
          itemIconColor = Colors.redAccent;
        });
      }
    }
  }

  Future<void> fetchLatestIntruderStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('ultrasonic_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final latest = response.first;
        if (mounted) {
          setState(() {
            intruderStatus = latest['status'] ?? 'Unknown';
            switch (intruderStatus) {
              case 'very close':
                intruderIcon = Icons.warning_amber_rounded;
                intruderIconColor = Colors.redAccent;
                
                // Check for alert - only when status changes
                if (lastUltrasonicStatus != 'very close') {
                  _alertService.showAlert(
                    context,
                    'INTRUDER ALERT', 
                    'Someone is very close to the vault!', 
                    Colors.red[800]!
                  );
                }
                break;
              case 'nearby':
                intruderIcon = Icons.warning_amber_rounded;
                intruderIconColor = Colors.amber;
                break;
              case 'approaching area':
                intruderIcon = Icons.warning_amber_rounded;
                intruderIconColor = const Color(0xFF2DFBB2);
                break;
              case 'detected far':
              case 'area clear':
                intruderIcon = Icons.verified_user;
                intruderIconColor = const Color(0xFF2DFBB2);
                break;
              default:
                intruderIcon = Icons.verified_user;
                intruderIconColor = const Color(0xFF2DFBB2);
            }
            
            // Update last status
            lastUltrasonicStatus = intruderStatus;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          intruderStatus = 'Error fetching status';
        });
      }
    }
  }

  Future<void> fetchSystemState() async {
    try {
      final response = await Supabase.instance.client
          .from('system_status')
          .select()
          .order('updated_at', ascending: false)
          .limit(1);

      print('System state response: $response'); 

      if (response.isNotEmpty) {
        final latest = response.first;
        if (mounted) {
          setState(() {
            systemState = latest['system_state'] ?? 'Unknown';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          systemState = 'Error';
        });
      }
      print('System state error: $e'); 
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'SENSORS STATUS',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSystemStateCard(),
          const SizedBox(height: 8),
          _buildSensorCard(
            title: 'DOOR STATUS',
            details: doorStatus,
            icon: doorIcon,
            iconColor: doorIconColor,
            borderColor: doorIconColor,
          ),
          const SizedBox(height: 8),
          _buildSensorCard(
            title: 'ITEM PRECENCE',
            details: itemStatus,
            icon: itemIcon,
            iconColor: itemIconColor,
            borderColor: itemIconColor,
          ),
          const SizedBox(height: 8),
          _buildSensorCard(
            title: 'NEARBY ACTIVITY',
            details: intruderStatus,
            icon: intruderIcon,
            iconColor: intruderIconColor,
            borderColor: intruderIconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStateCard() {
    // Show ON/OFF icon and color based on systemState
    final bool isOn = systemState.toUpperCase() == 'ON';
    final IconData stateIcon = isOn ? Icons.power_settings_new : Icons.power_off;
    final Color stateIconColor = isOn ? Color(0xFF2DFBB2) : Colors.redAccent;

    return Card(
      color: const Color(0xFF181A1B),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: stateIconColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SYSTEM STATE',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [  
                      const SizedBox(),
                      Text(
                        systemState,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: stateIconColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              stateIcon,
              size: 60,
              color: stateIconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String details,
    required IconData icon,
    required Color iconColor,
    Color borderColor = const Color(0xFF2DFBB2),
  }) {
    return Card(
      color: const Color(0xFF181A1B),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              icon,
              size: 60,
              color: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}