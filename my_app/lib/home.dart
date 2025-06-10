import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'authentication/login.dart';
import 'hc_logic/add_round_page.dart';

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
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        final uid = snapshot.data!.uid;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Account Information'),
            centerTitle: true,
          ),
          body: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
            builder: (context, userSnapshot) {
              String hcText = 'Calculating...';
              if (userSnapshot.hasData && userSnapshot.data!.data() != null) {
                final data = userSnapshot.data!.data() as Map<String, dynamic>;
                final hc = data['handicapIndex'];
                hcText = hc != null
                    ? 'Handicap Index: ${hc.toStringAsFixed(1)}'
                    : 'Handicap Index: N/A';
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- TOP: Handicap Index + CHART + Buttons ---
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          hcText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ---------------- Handicap Chart Section -----------------
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('rounds')
                              .orderBy('date')
                              .snapshots(),
                          builder: (context, roundSnap) {
                            if (!roundSnap.hasData || roundSnap.data!.docs.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('No rounds to chart yet.'),
                              );
                            }
                            final chartData = roundSnap.data!.docs
                                .where((doc) => doc['handicapIndexAfterRound'] != null)
                                .map((doc) => {
                                      'date': (doc['date'] as Timestamp).toDate(),
                                      'hc': (doc['handicapIndexAfterRound'] as num).toDouble(),
                                    })
                                .toList();

                            if (chartData.length < 2) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text('Play more rounds to see progress!'),
                              );
                            }
                            return SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: chartData
                                          .asMap()
                                          .entries
                                          .map((entry) => FlSpot(
                                                entry.key.toDouble(),
                                                (entry.value['hc'] as num).toDouble(),
                                              ))
                                          .toList(),
                                      isCurved: true,
                                      color: Colors.deepPurple,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(show: false),
                                    ),
                                  ],
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: (chartData.length > 7)
                                            ? (chartData.length / 7).ceilToDouble()
                                            : 1,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= chartData.length) return Container();
                                          final date = chartData[idx]['date'] as DateTime;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '${date.month}/${date.day}',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  minY: chartData.map((e) => (e['hc'] as num).toDouble()).reduce((a, b) => a < b ? a : b) - 2,
                                  maxY: chartData.map((e) => (e['hc'] as num).toDouble()).reduce((a, b) => a > b ? a : b) + 2,
                                ),
                              ),
                            );
                          },
                        ),
                        // ---------------- End Handicap Chart Section -----------------
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Round'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          onPressed: () async {
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
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.golf_course),
                          label: const Text('View Rounds'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                          onPressed: () {
                            Navigator.pushNamed(context, 'rounds');
                          },
                        ),
                      ],
                    ),
                    // --- BOTTOM: Logout and email ---
                    Column(
                      children: [
                        Text(
                          'Logged in as ${snapshot.data?.email}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () => logout(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
