import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'authentication/login.dart';
import 'hc_logic/add_round_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const Color kPurple = Colors.deepPurple;
  static const Color kPurpleLight = Color(0xFFF3E5F5);
  static const String kEmptyStateImg =
      'https://i.pinimg.com/736x/bf/63/d9/bf63d91e871f03ffcf37614460530056.jpg';

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, 'login');
  }

  Future<void> _showProfileMenu(BuildContext context, Offset position) async {
    final choice = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: const [
        PopupMenuItem<String>(value: 'manage', child: Text('Manage Profile')),
        PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
      ],
    );

    switch (choice) {
      case 'manage':
        Navigator.pushNamed(context, 'profile');
        break;
      case 'logout':
        _logout(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (!authSnap.hasData) return const LoginScreen();
        final uid = authSnap.data!.uid;

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final Map<String, dynamic> userData =
                userSnap.data!.data() as Map<String, dynamic>? ?? {};
            final String username = userData['name'] ?? 'User';
            final String? photoUrl = userData['photoUrl'];
            final hc = userData['handicapIndex'];
            final String hcText = (hc is num)
                ? 'Handicap Index: ${hc.toStringAsFixed(1)}'
                : 'Handicap Index: N/A';

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.deepPurple,
                elevation: 0,
                centerTitle: true,
                title: const Text(
                  'Handicap Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              extendBodyBehindAppBar: true,
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kPurpleLight, kPurpleLight], // Purple to blue
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Greeting text
                            Text(
                              'Hello, $username!',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Profile picture
                            GestureDetector(
                              onTapDown: (details) =>
                                  _showProfileMenu(context, details.globalPosition),
                              child: CircleAvatar(
                                radius: 28,
                                backgroundColor: kPurpleLight,
                                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: (photoUrl == null || photoUrl.isEmpty)
                                    ? const Icon(Icons.person, color: kPurple)
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          hcText,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 24),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('rounds')
                              .orderBy('date')
                              .snapshots(),
                          builder: (context, roundSnap) {
                            if (!roundSnap.hasData || roundSnap.data!.docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  children: const [
                                    Image(
                                      image: NetworkImage(kEmptyStateImg),
                                      height: 250,
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(height: 28),
                                    Text(
                                      'Play more rounds to see progress!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final chartData = roundSnap.data!.docs
                                .map((doc) {
                              final d = doc.data() as Map<String, dynamic>;
                              if (d['handicapIndexAfterRound'] == null) return null;
                              return {
                                'date': (d['date'] as Timestamp).toDate(),
                                'hc': (d['handicapIndexAfterRound'] as num).toDouble(),
                              };
                            })
                                .whereType<Map<String, dynamic>>()
                                .toList();

                            if (chartData.length < 2) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  children: const [
                                    Image(
                                      image: NetworkImage(kEmptyStateImg),
                                      height: 250,
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(height: 28),
                                    Text(
                                      'Play more rounds to see progress!',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final minY = chartData
                                .map((e) => e['hc'] as double)
                                .reduce((a, b) => a < b ? a : b) -
                                2;
                            final maxY = chartData
                                .map((e) => e['hc'] as double)
                                .reduce((a, b) => a > b ? a : b) +
                                2;

                            return SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: chartData.length > 7
                                            ? (chartData.length / 7).ceilToDouble()
                                            : 1,
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= chartData.length) {
                                            return Container();
                                          }
                                          final date = chartData[idx]['date'] as DateTime;
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              '${date.month}/${date.day}',
                                              style: const TextStyle(fontSize: 11, color: Colors.white),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  minY: minY,
                                  maxY: maxY,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: chartData
                                          .asMap()
                                          .entries
                                          .map((entry) => FlSpot(
                                        entry.key.toDouble(),
                                        entry.value['hc'] as double,
                                      ))
                                          .toList(),
                                      isCurved: true,
                                      color: Colors.white,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Round'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () async {
                            final userDoc = await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .get();
                            final golfApiToken = userDoc.data()?['golfCourseApiToken'];
                            if (golfApiToken == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('GolfCourseAPI token missing.')),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddRoundPage(golfApiToken: golfApiToken),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.golf_course),
                          label: const Text('View Rounds'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple.withOpacity(0.85),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, 'rounds');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
