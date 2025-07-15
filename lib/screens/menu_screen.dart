import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/pin_auth_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    // Clear authentication state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_authenticated', false);

    // Navigate back to login screen
    // Using pushReplacement to prevent going back
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PinAuthScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF133052),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Removed System Status card
          // Removed Contact Support card
          
          _buildMenuCard(
            title: 'About',
            icon: Icons.info_outline,
            iconColor: const Color(0xFF4B79A6),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('About VaulTech'),
                    backgroundColor: const Color(0xFFFFFFFF),
                    content: const Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Version: 1.0.0'),
                        SizedBox(height: 8),
                        Text('Developed by: DSD GROUP'),
                        SizedBox(height: 16),
                        Text('VaulTech is a vault security system using an ESP32 microcontroller. It detects unauthorized access, door status, item movement, and nearby presence, sending instant alerts to your mobile app with remote control features.'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Close', style: TextStyle(color: Color(0xFF4B79A6))),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          _buildMenuCard(
            title: 'Log Out',
            icon: Icons.logout,
            iconColor: const Color(0xFF4B79A6),
            onTap: () => _signOut(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: const Color(0xFFFFFFFF),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFF4B79A6), width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 30,
                color: iconColor,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF133052),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF4B79A6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}