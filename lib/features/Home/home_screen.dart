import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Pill {
  final String id;
  final String name;
  final TimeOfDay time;
  final String specification;
  final bool taken;

  Pill({
    required this.id,
    required this.name,
    required this.time,
    required this.specification,
    required this.taken,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Pill>> _getPillsStream() {
    final User? user = _auth.currentUser;
    if (user != null) {
      return _firestore
          .collection('users')
          .doc(user.uid)
          .collection('pills')
          .snapshots()
          .asyncMap((pillsSnapshot) async {
            List<Pill> pillList = [];
            for (var doc in pillsSnapshot.docs) {
              final pillData = doc.data();
              final time = _getTimeOfDayFromData(pillData['time']);

              final today = DateTime.now();
              final dateKey = "${today.year}-${today.month}-${today.day}";

              final trackingSnapshot = await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('tracking')
                  .doc(dateKey)
                  .collection('pills')
                  .doc(pillData['name']) 
                  .get();

              final taken = trackingSnapshot.exists && trackingSnapshot.data() != null
                  ? trackingSnapshot.data()!['taken'] as bool
                  : false;

              pillList.add(Pill(
                id: doc.id,
                name: pillData['name'] ?? 'Unknown',
                time: time,
                specification: pillData['specification'] ?? 'No specification',
                taken: taken,
              ));
            }
            return pillList; 
          });
    } else {
      throw Exception('No logged-in user found.');
    }
  }

  TimeOfDay _getTimeOfDayFromData(dynamic timeData) {
    try {
      if (timeData is Timestamp) {
        final DateTime dateTime = timeData.toDate();
        return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
      } else if (timeData is String) {
        final parts = timeData.split(':');
        if (parts.length == 2) {
          int hour = int.parse(parts[0]);
          int minute = int.parse(parts[1]);
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      throw Exception('Invalid time format: $timeData');
    } catch (e) {
      print('Error parsing time data: $e');
      throw Exception('Invalid time format for data: $timeData');
    }
  }

  Future<void> _initializePillTracking(String pillName) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final today = DateTime.now();
      final dateKey = "${today.year}-${today.month}-${today.day}";

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracking')
          .doc(dateKey)
          .set({
            'totalPills': FieldValue.increment(1), 
            'takenPills': FieldValue.increment(0), 
          }, SetOptions(merge: true)); 

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracking')
          .doc(dateKey)
          .collection('pills')
          .doc(pillName) 
          .set({'taken': false}); 
    }
  }

  Future<void> _updatePillStatus(String pillName, bool taken) async {
    final User? user = _auth.currentUser;
    if (user != null) {
      final today = DateTime.now();
      final dateKey = "${today.year}-${today.month}-${today.day}";

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracking')
          .doc(dateKey)
          .collection('pills')
          .doc(pillName) 
          .set({'taken': taken}); 

      final trackingDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracking')
          .doc(dateKey)
          .get();

      int totalPills = trackingDoc.data()?['totalPills'] ?? 0;
      int takenPills = trackingDoc.data()?['takenPills'] ?? 0;

      if (taken) {
        if (!trackingDoc.data()!['pills'][pillName]?['taken']) {
          takenPills += 1; 
        }
      } else {
        if (trackingDoc.data()!['pills'][pillName]?['taken']) {
          takenPills -= 1;
        }
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tracking')
          .doc(dateKey)
          .update({
            'takenPills': takenPills, 
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('My Pills'),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Pill>>(
        stream: _getPillsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading pills: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pills = snapshot.data!;

          return ListView.builder(
            itemCount: pills.length,
            itemBuilder: (context, index) {
              final pill = pills[index];
              return _buildPillCard(pill);
            },
          );
        },
      ),
    );
  }

  Widget _buildPillCard(Pill pill) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Checkbox(
              value: pill.taken,
              onChanged: (bool? newValue) {
                if (newValue != null) {
                  _updatePillStatus(pill.name, newValue); 
                  setState(() {}); 
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pill.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: pill.taken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatTime(pill.time)} - ${pill.specification}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
