import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'handicap_utils.dart'; // <-- Import your helper!

class EditRoundScreen extends StatefulWidget {
  final String roundId;
  final Map<String, dynamic> initialData;
  const EditRoundScreen({required this.roundId, required this.initialData, super.key});

  @override
  State<EditRoundScreen> createState() => _EditRoundScreenState();
}

class _EditRoundScreenState extends State<EditRoundScreen> {
  late TextEditingController _scoreController;
  late TextEditingController _commentController;
  late String _courseName;
  late DateTime _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _courseName = widget.initialData['courseName'] ?? '';
    _date = (widget.initialData['date'] as Timestamp).toDate();
    _scoreController = TextEditingController(
        text: (widget.initialData['grossScore'] ?? '').toString());
    _commentController = TextEditingController(
        text: (widget.initialData['comment'] ?? '').toString());
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() => _isSaving = true);
    try {
      final courseRating = (widget.initialData['courseRating'] as num?)?.toDouble() ?? 72.0;
      final slopeRating = (widget.initialData['slopeRating'] as num?)?.toInt() ?? 113;
      final newGrossScore = int.tryParse(_scoreController.text) ?? 0;
      final newComment = _commentController.text.trim();

      // Calculate new differential
      final newScoreDifferential = calculateScoreDifferential(
        grossScore: newGrossScore,
        courseRating: courseRating,
        slopeRating: slopeRating,
      );

      // Update the round's score and differential
      await widget.initialData['ref'].update({
        'grossScore': newGrossScore,
        'scoreDifferential': newScoreDifferential,
        'comment': newComment,
      });

      // Recalculate ALL handicapIndexAfterRound fields for this user!
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await recalculateHandicapHistoryForUser(uid);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Round updated!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Round')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Course: $_courseName'),
            const SizedBox(height: 16),
            TextField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gross Score'),
            ),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(labelText: 'Comment'),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Save Changes'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
