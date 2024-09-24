import 'package:flutter/material.dart';
import 'package:rentalappadmin/DashboardScreen.dart';
import 'package:rentalappadmin/logingpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: CircularProgressIndicator(), // Show a loading spinner while checking status
        ),
      ),
    );
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    // Navigate to the appropriate screen based on the login status
    if (isLoggedIn) {
      // Navigate to the home screen if logged in
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminDashboard(),));
    } else {
      // Navigate to the login screen if not logged in
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginScreen(),));
    }
  }
}
