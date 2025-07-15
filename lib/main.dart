import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth/pin_auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/menu_screen.dart';
import 'services/alert_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qoyaylzobtgwmkecoddt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFveWF5bHpvYnRnd21rZWNvZGR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg2NjI2NjIsImV4cCI6MjA2NDIzODY2Mn0.bo-PbdLa6F3A-9pb5fc1TQ3pw55RbmedoJBiu47pWck',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Remove const constructor
  MyApp({super.key});

  // Keep the AlertService instance
  final AlertService _alertService = AlertService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VaulTech',
      navigatorKey: _alertService.navigatorKey,
      theme: ThemeData(
        primaryColor: const Color(0xFFFFFFFF),
        scaffoldBackgroundColor: const Color(0xFF133052),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFFFFFFF),
          secondary: const Color(0xFF4B79A6),
          tertiary: const Color(0xFF133052),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF133052),
          titleTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
    
    setState(() {
      _isAuthenticated = isAuthenticated;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_isAuthenticated) {
      return const HomePage();
    } else {
      return const PinAuthScreen();
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),          
    NotificationScreen(),  
    MenuScreen(),        
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'VaulTech',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
          ),
        ),
        backgroundColor: const Color(0xFF133052),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2.0),
          child: Container(
            color: const Color(0xFF4B79A6),
            height: 2,
            width: double.infinity,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF133052),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF133052),
        selectedItemColor: const Color(0xFFDDA853),
        unselectedItemColor: const Color(0xFFFFFFFF),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Color(0xFF4B79A6)),
            activeIcon: Icon(Icons.home, color: Color(0xFFDDA853)),
            label: 'HOME',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Color(0xFF4B79A6)),
            activeIcon: Icon(Icons.notifications, color: Color(0xFFDDA853)),
            label: 'NOTIFICATION',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu, color: Color(0xFF4B79A6)),
            activeIcon: Icon(Icons.menu, color: Color(0xFFDDA853)),
            label: 'MENU',
          ),
        ],
      ),
    );
  }
}
