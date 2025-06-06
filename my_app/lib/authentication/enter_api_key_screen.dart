import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EnterApiKeyScreen extends StatefulWidget {
  const EnterApiKeyScreen({super.key});

  @override
  State<EnterApiKeyScreen> createState() => _EnterApiKeyScreenState();
}

class _EnterApiKeyScreenState extends State<EnterApiKeyScreen> {
  final _apiKeyController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isLoading = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    // Automatically focus the text field for convenience
    Future.delayed(Duration(milliseconds: 250), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> saveApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      setState(() => _errorMessage = "API key cannot be empty");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "You are not logged in. Please login first.";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'golfCourseApiToken': apiKey}, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Optional: show a snackbar confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key saved!')),
      );
      Navigator.pushReplacementNamed(context, 'home');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not save API key: $e";
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key, size: 72, color: Colors.blue[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Enter GolfCourseAPI Key',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900]
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Paste your API key from your registration email below.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _apiKeyController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      labelText: 'GolfCourseAPI Key',
                      prefixIcon: const Icon(Icons.key),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage.isNotEmpty)
                    Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : saveApiKey,
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
                          : const Text('Save', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
