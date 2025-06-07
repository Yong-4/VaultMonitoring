import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool monitoringDoor = false;
  final supabase = Supabase.instance.client;
  
  @override
  void initState() {
    super.initState();
    _fetchSystemStatus();
  }
  
  // Fetch current system status from Supabase
  Future<void> _fetchSystemStatus() async {
    try {
      final data = await supabase
          .from('system_status')
          .select('system_state')
          .eq('id', 2)
          .single();
      
      setState(() {
        monitoringDoor = data['system_state'] == 'ON';
      });
        } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch system status: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Update the system state in Supabase
  Future<void> _updateSystemState(bool value) async {
    try {
      await supabase
          .from('system_status')
          .update({'system_state': value ? 'ON' : 'OFF'})
          .eq('id', 2);
      
      setState(() {
        monitoringDoor = value;
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update system state: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Handle logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', false);
      
      if (mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (error) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A1B),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Toggle card for system monitoring
              buildSwitchCard(
                title: 'System State Control',
                subtitle: monitoringDoor ? 'ON' : 'OFF',
                value: monitoringDoor,
                onChanged: (val) => _updateSystemState(val),
                borderColor: const Color(0xFF2DFBB2),
              ),
              const SizedBox(height: 16),
              // Logout card
              Card(
                color: const Color(0xFF242729),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(
                    color: Color(0xFF2DFBB2),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: () => _handleLogout(context),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.logout, 
                          color: Color(0xFF2DFBB2), 
                          size: 32
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Custom widget for toggle switch card
  Widget buildSwitchCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color borderColor,
  }) {
    return Card(
      color: const Color(0xFF242729),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: value ? const Color(0xFF2DFBB2) : Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF2DFBB2),
                  inactiveTrackColor: Colors.grey.shade700,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}