import 'package:flutter/material.dart';

class HomeScreenContent extends StatelessWidget {
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
            status: 'ON',
            details: 'No Unusual Activity\nThe Door is Close',
          ),
          const SizedBox(height: 8),
          _buildSensorCard(
            title: 'ITEM SECURITY',
            status: 'OFF',
            details: 'Currently off\nThe Door is Close',
          ),
          const SizedBox(height: 8),
          _buildSensorCard(
            title: 'INTRUDER SECURITY',
            status: 'ON',
            details: 'No Unusual Activity\nNo one is near',
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
  }) {
    return Card(
      color: const Color(0xFF181A1B),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF2DFBB2),
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
              Icons.verified_user,
              size: 60,
              color: const Color(0xFF2DFBB2),
            ),
          ],
        ),
      ),
    );
  }
}