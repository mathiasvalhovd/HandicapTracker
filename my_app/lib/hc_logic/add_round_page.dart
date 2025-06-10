import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'search_course_page.dart';
import 'handicap_utils.dart'; // <-- Import your helper!

class AddRoundPage extends StatefulWidget {
  final String golfApiToken;

  const AddRoundPage({required this.golfApiToken, super.key});

  @override
  State<AddRoundPage> createState() => _AddRoundPageState();
}

class _AddRoundPageState extends State<AddRoundPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _date;
  Map<String, dynamic>? _selectedCourse;
  int? _score;
  bool _submitting = false;

  Future<void> _pickCourse() async {
    final course = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SearchCoursePage(golfApiToken: widget.golfApiToken),
      ),
    );
    if (course != null) setState(() => _selectedCourse = course);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCourseName = _selectedCourse?['course_name'] ?? _selectedCourse?['club_name'];
    final selectedAddress = _selectedCourse?['location']?['address'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Add Golf Round')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ListTile(
              title: Text(_date == null
                  ? 'Select date'
                  : _date!.toLocal().toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null && mounted) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(selectedCourseName ?? 'Select Course'),
              subtitle: selectedAddress.isNotEmpty ? Text(selectedAddress) : null,
              trailing: const Icon(Icons.golf_course),
              onTap: _pickCourse,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Gross Score'),
              keyboardType: TextInputType.number,
              validator: (val) =>
                  val == null || int.tryParse(val) == null ? 'Enter score' : null,
              onChanged: (val) => _score = int.tryParse(val),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              child: _submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit'),
              onPressed: _submitting
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate() ||
                          _date == null ||
                          _selectedCourse == null ||
                          _score == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Fill all fields')),
                        );
                        return;
                      }
                      setState(() => _submitting = true);

                      final courseId = _selectedCourse!['id'].toString();
                      final courseName = _selectedCourse!['course_name'] ?? _selectedCourse!['club_name'];

                      // Fetch course detail for handicap calculation
                      final courseDetail = await _fetchCourseDetail(courseId);
                      if (courseDetail == null) {
                        if (mounted) setState(() => _submitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Failed to fetch course info')));
                        }
                        return;
                      }

                      Map<String, dynamic>? tee;
                      if (courseDetail['tees']?['male'] != null &&
                          (courseDetail['tees']['male'] as List).isNotEmpty) {
                        tee = (courseDetail['tees']['male'] as List).first;
                      } else if (courseDetail['tees']?['female'] != null &&
                          (courseDetail['tees']['female'] as List).isNotEmpty) {
                        tee = (courseDetail['tees']['female'] as List).first;
                      }

                      final double courseRating = tee != null && tee['course_rating'] != null
                          ? (tee['course_rating'] as num).toDouble()
                          : 72.0;
                      final int slopeRating = tee != null && tee['slope_rating'] != null
                          ? (tee['slope_rating'] as num).toInt()
                          : 113;

                      // --- USE UTILS TO CALCULATE SCORE DIFFERENTIAL ---
                      final double scoreDifferential = calculateScoreDifferential(
                        grossScore: _score!,
                        courseRating: courseRating,
                        slopeRating: slopeRating,
                      );

                      final uid = FirebaseAuth.instance.currentUser!.uid;

                      // --- ADD ROUND DATA ---
                      final roundRef = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('rounds')
                          .add({
                        'date': Timestamp.fromDate(_date!),
                        'courseId': courseId,
                        'courseName': courseName,
                        'grossScore': _score,
                        'courseRating': courseRating,
                        'slopeRating': slopeRating,
                        'scoreDifferential': scoreDifferential,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      // --- IMPORTANT: Recalculate the full handicap history for all rounds! ---
                      // This will update every round's handicapIndexAfterRound (needed for charts/history).
                      await recalculateHandicapHistoryForUser(uid);

                      if (mounted) setState(() => _submitting = false);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Round added')));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchCourseDetail(String id) async {
    try {
      final url = 'https://api.golfcourseapi.com/v1/courses/$id';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Key ${widget.golfApiToken}'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }
}
