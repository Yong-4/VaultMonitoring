import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class PinAuthScreen extends StatefulWidget {
  const PinAuthScreen({super.key});

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isError = false;
  bool _obscureText = true;
  bool _isLoading = false;
  final _client = Supabase.instance.client;
  String? _databasePin;

  @override
  void initState() {
    super.initState();
    _fetchPinFromDatabase();
  }

  Future<void> _fetchPinFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch the PIN from the login_pin table
      final response = await _client
          .from('login_pin')
          .select('pin')
          .limit(1)
          .single();

      _databasePin = response['pin'].toString();
    } catch (e) {
      debugPrint('Error fetching PIN: $e');
      // Fallback to default PIN if there's an error
      _databasePin = '1234';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF181A1B),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2DFBB2),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF181A1B), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Vault Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF2DFBB2), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock,
                  size: 60,
                  color: Color(0xFF2DFBB2),
                ),
              ),
              const SizedBox(height: 20),

              // Vault Monitoring Text
              const Text(
                'Vault Monitoring',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              
              // Tagline
              const Text(
                'We track, we watch, we secure',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              
              const SizedBox(height: 60),
              
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 12,
                obscureText: _obscureText,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                cursorColor: const Color(0xFF2DFBB2),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: 'Enter PIN',
                  labelStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF2DFBB2), width: 2),
                  ),
                  errorText: _isError ? 'Wrong PIN' : null,
                  errorStyle: const TextStyle(color: Colors.redAccent),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Log in button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _verifyPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2DFBB2),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _verifyPin() async {
    if (_databasePin == null) {
      // If we couldn't fetch the PIN, fetch it again
      await _fetchPinFromDatabase();
      // ignore: prefer_conditional_assignment
      if (_databasePin == null) {
        // If still null, use a fallback PIN
        _databasePin = '1234';
      }
    }
    
    if (_pinController.text == _databasePin) {
      // Store authentication status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_authenticated', true);
      
      setState(() {
        _isError = false;
      });
      
      // Navigate to HomePage
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      setState(() {
        _isError = true;
      });
    }
  }
}