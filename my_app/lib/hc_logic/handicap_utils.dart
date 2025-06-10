import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

double calculateScoreDifferential({
  required int grossScore,
  required double courseRating,
  required int slopeRating,
}) {
  return double.parse(
    ((113 / slopeRating) * (grossScore - courseRating)).toStringAsFixed(2),
  );
}

double? calculateHandicapIndex(List<double> differentials) {
  final n = differentials.length;
  if (n < 3) return null;

  int bestCount;
  if (n < 5) {
    bestCount = 1;
  } else if (n < 7) {
    bestCount = 2;
  } else if (n < 9) {
    bestCount = 2;
  } else if (n < 11) {
    bestCount = 3;
  } else if (n < 13) {
    bestCount = 4;
  } else if (n < 15) {
    bestCount = 5;
  } else if (n < 17) {
    bestCount = 6;
  } else if (n == 17) {
    bestCount = 7;
  } else if (n == 18) {
    bestCount = 8;
  } else if (n == 19) {
    bestCount = 9;
  } else {
    bestCount = 8;
  }

  final sorted = [...differentials]..sort();
  final best = sorted.take(bestCount).toList();
  final avg = best.reduce((a, b) => a + b) / best.length;
  return (avg * 10).truncateToDouble() / 10;
}

/// Recalculates **all** rounds' handicapIndexAfterRound (for chart/history) and updates user's current handicapIndex
Future<void> recalculateHandicapHistoryForUser([String? forUid]) async {
  final uid = forUid ?? FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  // Get all rounds, sorted by date ASCENDING!
  final roundsSnap = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('rounds')
      .orderBy('date')
      .get();

  // List of rounds with Firestore reference
  List<Map<String, dynamic>> rounds = [];
  for (final doc in roundsSnap.docs) {
    rounds.add({...doc.data(), 'ref': doc.reference});
  }

  double? latestHandicapIndex;

  // Update each round's index
  for (int i = 0; i < rounds.length; i++) {
    final diffs = rounds
        .sublist(0, i + 1)
        .map((r) => (r['scoreDifferential'] as num?)?.toDouble())
        .where((d) => d != null)
        .cast<double>()
        .toList();

    final hcIndex = calculateHandicapIndex(diffs);
    await rounds[i]['ref'].update({
      'handicapIndexAfterRound': hcIndex,
    });
    if (i == rounds.length - 1) latestHandicapIndex = hcIndex;
  }

  // Update the user's profile with the latest handicapIndex
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'handicapIndex': latestHandicapIndex,
  }, SetOptions(merge: true));
}
