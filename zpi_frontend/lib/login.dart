import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zpi_frontend/src/services/user_data.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();

  // Method to handle login
  void _login() async {
    final username = _usernameController.text.trim();
    if (username.isNotEmpty) {
      // Save the username in SharedPreferences
      await UserPreferences.saveUserName(username);
      // Navigate to the home screen
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Show an error if the username is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a username")),
      );
    }
  }

  void _loginGoogle() async {
    String _url = "http://192.168.224.177:8081/auth/oauth";
    if (!await launchUrl(Uri.parse(_url))) {
      throw Exception('Could not launch $_url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _login,
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: _loginGoogle,
              child: Text('Google'),
            ),
          ],
        ),
      ),
    );
  }
}
