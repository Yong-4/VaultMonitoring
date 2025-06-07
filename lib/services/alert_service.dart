import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  
  AlertService._internal();
  
  // Queue for pending alerts
  final Queue<Map<String, dynamic>> _pendingAlerts = Queue<Map<String, dynamic>>();
  bool _isAlertShowing = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  void showAlert(BuildContext context, String title, String message, Color color) {
    // Add to queue
    _pendingAlerts.add({
      'title': title,
      'message': message,
      'color': color,
    });
    
    // If no alert is showing, show the next one
    if (!_isAlertShowing) {
      _showNextAlert(context);
    }
  }
  
  void _showNextAlert(BuildContext context) {
    if (_pendingAlerts.isEmpty) {
      _isAlertShowing = false;
      return;
    }
    
    _isAlertShowing = true;
    final alert = _pendingAlerts.removeFirst();
    _playAlertSound();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: alert['color'],
          title: Text(
            alert['title'],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            alert['message'],
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: const Text('Okay', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _audioPlayer.stop();
                Navigator.of(context).pop();
                
                // Show the count of remaining alerts if any
                if (_pendingAlerts.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${_pendingAlerts.length} more alerts pending'),
                      backgroundColor: Colors.orange[700],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                
                // Check for next alert after a short delay
                Future.delayed(const Duration(milliseconds: 300), () {
                  _showNextAlert(context);
                });
              },
            ),
          ],
        );
      },
    ).then((_) {
      // If dialog dismissed another way
      _audioPlayer.stop();
      
      // Check for next alert after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _showNextAlert(context);
      });
    });
  }
  
  Future<void> _playAlertSound() async {
    try {
      debugPrint('Attempting to play sound...');
      // Reset player state first
      await _audioPlayer.stop();
      
      // Try with explicit volume and source
      await _audioPlayer.setVolume(1.0);
      
      try {
        await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
      } catch (assetError) {
        debugPrint('Asset error: $assetError, trying UrlSource');
        await _audioPlayer.play(UrlSource('https://www2.cs.uic.edu/~i101/SoundFiles/StarWars3.wav'));
      }
      
      debugPrint('Alert sound played');
    } catch (e) {
      debugPrint('Error playing sound: $e');
      try {
        final player = AudioPlayer();
        await player.play(AssetSource('sounds/alert.mp3'));
      } catch (e2) {
        debugPrint('Fallback also failed: $e2');
      }
    }
  }
  
  void dispose() {
    _audioPlayer.dispose();
  }
}