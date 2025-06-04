import 'package:flutter/material.dart';

class SwitchScreen extends StatefulWidget {
  @override
  State<SwitchScreen> createState() => _SwitchScreenState();
}

class _SwitchScreenState extends State<SwitchScreen> {
  bool monitoringDoor = true;
  bool itemSecurity = false;
  bool intruderSecurity = true;

  Widget buildSwitchCard({
    required String title,
    required String subtitle,
    required String sensorLabel, // <-- add this
    required bool value,
    required ValueChanged<bool> onChanged,
    Color borderColor = Colors.transparent,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181A1B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: const Color.fromARGB(221, 255, 255, 255), size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: const Color.fromARGB(255, 255, 255, 255),
                      ),
                    ),
                    Spacer(),
                    Text(
                      sensorLabel, // <-- display sensor label
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: value ? const Color.fromARGB(255, 170, 170, 170) : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF2DFBB2),
            inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
            inactiveTrackColor: const Color(0xFF181A1B),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A1B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildSwitchCard(
                title: 'Monitoring Door',
                subtitle: monitoringDoor ? 'On' : 'OFF',
                sensorLabel: 'IR1', // <-- add this
                value: monitoringDoor,
                onChanged: (val) => setState(() => monitoringDoor = val),
                borderColor: Color(0xFF2DFBB2),
              ),
              buildSwitchCard(
                title: 'Item Security',
                subtitle: itemSecurity ? 'On' : 'OFF',
                sensorLabel: 'IR2', // <-- add this
                value: itemSecurity,
                onChanged: (val) => setState(() => itemSecurity = val),
                borderColor: Color(0xFF2DFBB2),
              ),
              buildSwitchCard(
                title: 'Intruder Security',
                subtitle: intruderSecurity ? 'On' : 'OFF',
                sensorLabel: 'ULS', // <-- add this
                value: intruderSecurity,
                onChanged: (val) => setState(() => intruderSecurity = val),
                borderColor: Color(0xFF2DFBB2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}