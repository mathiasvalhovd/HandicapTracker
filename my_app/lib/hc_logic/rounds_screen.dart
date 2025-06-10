import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'handicap_utils.dart'; // <-- Import the helper!

class RoundsScreen extends StatelessWidget {
  const RoundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final roundsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('rounds')
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Rounds'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: roundsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading rounds'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No rounds added yet.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp).toDate();
              final courseName = data['courseName'] ?? '';
              final score = data['grossScore'] ?? '';

              return ListTile(
                title: Text(courseName),
                subtitle: Text('${date.toLocal().toString().split(' ')[0]}  •  Score: $score'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          'edit_round',
                          arguments: {
                            'roundId': doc.id,
                            'initialData': {
                              ...data,
                              'ref': doc.reference,
                            },
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Round?'),
                            content: const Text('Are you sure you want to delete this round?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel')),
                              TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete')),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await doc.reference.delete();
                          // <<< THIS IS THE KEY CHANGE:
                          await recalculateHandicapHistoryForUser(uid);

                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Round deleted')));
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
