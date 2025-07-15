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
  // ignore: unused_field
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
    return Scaffold(
      backgroundColor: const Color(0xFF133052),
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Color(0xFFFFFFFF),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF133052),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: const Color(0xFF4B79A6),
            height: 2.0,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95, // 95% of screen width
            child: Card(
              margin: const EdgeInsets.all(20),
              color: const Color(0xFFFFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Color(0xFF4B79A6), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Vault Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF4B79A6), width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.lock,
                        size: 50,
                        color: Color(0xFF4B79A6),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // VaulTech Text
                    const Text(
                      'VaulTech',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF133052),
                      ),
                    ),
                    
                    // Tagline
                    const Text(
                      'Secure Beyond the Lock',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4B79A6),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // PIN TextField - WIDER
                    SizedBox(
                      width: double.infinity, // Full width within container
                      child: TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        obscureText: _obscureText,
                        style: const TextStyle(color: Color(0xFF133052), fontSize: 18),
                        cursorColor: const Color(0xFF4B79A6),
                        decoration: InputDecoration(
                          counterText: '',
                          labelText: 'Enter PIN',
                          labelStyle: const TextStyle(
                            color: Color(0xFF4B79A6),
                            fontSize: 16,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF4B79A6)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFDDA853), width: 2),
                          ),
                          errorText: _isError ? 'Wrong PIN' : null,
                          errorStyle: const TextStyle(color: Colors.redAccent),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off : Icons.visibility,
                              color: Color(0xFF4B79A6),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Log in button - WIDER
                    SizedBox(
                      width: double.infinity, // Full width within container
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B79A6),
                          foregroundColor: const Color(0xFFFFFFFF),
                        ),
                        onPressed: _verifyPin,
                        child: const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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