import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'profile_screen.dart';

import 'home.dart';
import 'authentication/login.dart';
import 'authentication/register.dart';
import 'authentication/enter_api_key_screen.dart';
// <--- Add this import!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HandicapTracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: 'login',
      routes: {
        'login': (context) => const LoginScreen(),
        'register': (context) => const RegisterScreen(),
        'home': (context) => const HomeScreen(),
        'enter_api_key': (context) => const EnterApiKeyScreen(),
        'profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// Your MyHomePage class stays the same...
