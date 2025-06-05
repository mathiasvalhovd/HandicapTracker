import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _activationTokenController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = "";
  bool _awaitingActivation = false;
  String? _firebaseUid;

  void navigateLogin() {
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> register() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = "Passwords do not match";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final email = _emailController.text.trim();

    try {
      // 1. Register user in Firebase
      UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: _passwordController.text,
      );
      _firebaseUid = userCred.user?.uid;

      // 2. Register user in GolfCourseAPI
      final response = await http.post(
        Uri.parse('https://api.golfcourseapi.com/v1/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 201) {
        // Registered! (Activation email will be sent)
        setState(() {
          _isLoading = false;
          _awaitingActivation = true;
        });
      } else if (response.statusCode == 409) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              "Email already registered in GolfCourseAPI. Please check your email for an activation code, or login if already activated.";
          _awaitingActivation = true;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "GolfCourseAPI registration failed: ${response.body}";
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Firebase registration failed";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Registration failed: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> activateAccount() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    final token = _activationTokenController.text.trim();
    final email = _emailController.text.trim();

    try {
      final response = await http.put(
        Uri.parse('https://api.golfcourseapi.com/v1/users/activated'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        // Save token (if needed, for API use)
        final data = jsonDecode(response.body);
        final golfApiToken = data['token'];

        // Store the GolfCourseAPI token with the user in Firestore
        if (_firebaseUid != null && golfApiToken != null) {
          await FirebaseFirestore.instance.collection('users').doc(_firebaseUid).set({
            'golfCourseApiToken': golfApiToken,
          }, SetOptions(merge: true));
        }

        setState(() {
          _isLoading = false;
        });

        // Success message and move to login
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Success!'),
            content: const Text('Your GolfCourseAPI account is now activated. You can now log in and use all features.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  navigateLogin();
                },
                child: const Text('Login'),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = "Activation failed: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Activation error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _awaitingActivation
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email, size: 72, color: Colors.blue[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Activate your account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'We’ve sent you an activation code to your email.\n\nPlease paste it below and click "Activate".',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _activationTokenController,
                          decoration: InputDecoration(
                            labelText: 'Activation Code',
                            prefixIcon: const Icon(Icons.vpn_key),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : activateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Activate', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add, size: 72, color: Colors.blue[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Register',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_errorMessage.isNotEmpty)
                          Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Sign Up', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: navigateLogin,
                              child: const Text('Login'),
                            ),
                          ],
                        )
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
