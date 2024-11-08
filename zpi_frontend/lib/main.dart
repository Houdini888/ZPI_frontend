import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/screens/home.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if username is saved in SharedPreferences
  final username = await UserPreferences.getUserName();

  runApp(MyApp(initialRoute: username != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}