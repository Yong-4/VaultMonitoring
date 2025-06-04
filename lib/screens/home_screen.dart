import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    fetchLatestDoorStatus();
    fetchLatestIntruderStatus();
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
        setState(() {
          doorStatus = latest['status'] ?? 'Unknown';
          if (doorStatus == 'Vault is open') {
            doorIcon = Icons.lock_open;
            doorIconColor = Colors.redAccent;
          } else {
            doorIcon = Icons.lock;
            doorIconColor = Color(0xFF2DFBB2);
          }
        });
      }
    } catch (e) {
      setState(() {
        doorStatus = 'Error fetching status';
      });
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
        setState(() {
          intruderStatus = latest['status'] ?? 'Unknown';
          // Icon and color logic based on notification_screen.dart
          switch (intruderStatus) {
            case 'very close':
              intruderIcon = Icons.warning_amber_rounded;
              intruderIconColor = Colors.redAccent;
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
        });
      }
    } catch (e) {
      setState(() {
        intruderStatus = 'Error fetching status';
      });
    }
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
          _buildSensorCard(
            title: 'DOOR SECURITY',
            status: "ON",
            details: doorStatus,
            icon: doorIcon,
            iconColor: doorIconColor,
            borderColor: doorIconColor, // <-- match border to icon color
          ),
          const SizedBox(height: 8),
          _buildSensorCard(
            title: 'ITEM SECURITY',
            status: 'OFF',
            details: 'Currently off\nThe Door is Close',
            icon: Icons.verified_user,
            iconColor: Color(0xFF2DFBB2),
            borderColor: Color(0xFF2DFBB2), // or match to iconColor if you want
          ),
          const SizedBox(height: 8),
          _buildSensorCard(
            title: 'INTRUDER SECURITY',
            status: "ON",
            details: intruderStatus,
            icon: intruderIcon,
            iconColor: intruderIconColor,
            borderColor: intruderIconColor, // <-- match border to icon color
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required String title,
    required String status,
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
                  const SizedBox(height: 15),
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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