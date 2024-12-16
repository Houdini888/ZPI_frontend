import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zpi_frontend/src/screens/home.dart';
import 'package:zpi_frontend/src/services/user_data.dart';
import 'login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Check if username is saved in SharedPreferences
  final username = await UserPreferences.getUserName();
  final sessionCode = await UserPreferences.getSessionCode();

  print("Kod urządzenia: $sessionCode");
  if(sessionCode == null)
  {
      await UserPreferences.createSessionCode();
  }

  runApp(MyApp(initialRoute: username != null ? '/home' : '/login'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: initialRoute,
      debugShowCheckedModeBanner: false,
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
