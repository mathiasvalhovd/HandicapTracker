import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:my_app/hc_logic/edit_round_screen.dart';
import 'firebase_options.dart';

import 'home.dart';
import 'authentication/login.dart';
import 'authentication/register.dart';
import 'authentication/enter_api_key_screen.dart'; // <--- Add this import!
import 'hc_logic/rounds_screen.dart';

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
        'rounds': (context) => const RoundsScreen(),
        // Don't put edit_round here!
      },
      onGenerateRoute: (settings) {
        if (settings.name == 'edit_round') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EditRoundScreen(
              roundId: args['roundId'],
              initialData: args['initialData'],
            ),
          );
        }
        return null; // fallback
      },
    );
  }
}
