import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'authentication/login.dart';
import 'hc_logic/add_round_page.dart'; // Note: file renamed!

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void logout(context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Account Information'),
              centerTitle: true,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Logged in as ${snapshot.data?.email}'),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => logout(context),
                    child: const Text('Logout'),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Round'),
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                      final golfApiToken = userDoc.data()?['golfCourseApiToken'];
                      if (golfApiToken == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('GolfCourseAPI token missing. Please activate your account.')),
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddRoundPage(golfApiToken: golfApiToken),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
