// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fyp2022/screens/auto_add_screen.dart';
import 'package:fyp2022/screens/home_screen.dart';
import 'package:fyp2022/screens/login_screen.dart';
import 'package:fyp2022/firebase_options.dart';
import 'package:fyp2022/screens/registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize a new Firebase App instance
  await Firebase.initializeApp(
      name: "expiry notifier", options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      title: 'SMART CV BASED INVENTORY MANAGEMENT',
      theme: ThemeData(
          backgroundColor: Colors.blueGrey,
          primaryColor: Colors.cyan,
          secondaryHeaderColor: Colors.cyanAccent),
      routes: {
        'auto_add_screen': (context) => AutoAddScreen(),
        //'manual_add_screen': (context) => ManualAddScreen(),
        'registration_screen': (context) => RegistrationScreen(),
        'login_screen': (context) => LoginScreen(),
        'home_screen': (context) => HomeScreen()
      },
      home: const LoginScreen(),
    );
  }
}
