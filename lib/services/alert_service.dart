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
  // Global navigator key to get valid context
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  void showAlert(BuildContext context, String title, String message, Color color) {
    // Add to queue
    _pendingAlerts.add({
      'title': title,
      'message': message,
      'color': color,
      'context': context,  // Store the context with the alert
    });
    
    // If no alert is showing, show the next one
    if (!_isAlertShowing) {
      _showNextAlert();
    }
  }
  
  void _showNextAlert() {
    if (_pendingAlerts.isEmpty) {
      _isAlertShowing = false;
      return;
    }
    
    _isAlertShowing = true;
    final alert = _pendingAlerts.removeFirst();
    _playAlertSound();
    
    // Get the context from the alert or use navigator key's context
    final BuildContext context = alert['context'] ?? navigatorKey.currentContext!;
    
    // Check if context is valid
    if ((navigatorKey.currentContext != null || context.mounted)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
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
                  Navigator.of(dialogContext).pop();
                  
                  // Show the count of remaining alerts if any
                  if (_pendingAlerts.isNotEmpty) {
                    try {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('${_pendingAlerts.length} more alerts pending'),
                          backgroundColor: Colors.orange[700],
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      debugPrint('Error showing snackbar: $e');
                    }
                  }
                  
                  // Check for next alert after a short delay
                  Future.delayed(const Duration(milliseconds: 300), () {
                    _showNextAlert();
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
          _showNextAlert();
        });
      });
    } else {
      // Context is not valid, move to next alert
      debugPrint('Alert skipped due to invalid context');
      _isAlertShowing = false;
      if (_pendingAlerts.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _showNextAlert();
        });
      }
    }
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