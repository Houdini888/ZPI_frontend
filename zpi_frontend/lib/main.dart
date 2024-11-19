import 'package:flutter/material.dart';
import 'package:zpi_frontend/src/screens/home.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'package:zpi_frontend/src/services/websocketservice.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if username is saved in SharedPreferences
  final username = await UserPreferences.getUserName();

  runApp(MyApp(initialRoute: username != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
