
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime _currentMonth = DateTime.now();

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                  });
                },
              ),
              Text(
                '${_currentMonth.month}/${_currentMonth.year}',
                style: const TextStyle(
                  fontSize: 28,  
                  fontWeight: FontWeight.normal,  
                  color: Colors.black54,
                  fontFamily: 'Roboto', 
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.blue),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          FutureBuilder<Map<String, dynamic>>(
  future: _getPillStatusData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    } else if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    } else {
      final pillStatus = snapshot.data!['pillStatus'] as Map<int, String>;
      final totalPills = snapshot.data!['totalPills'] as int;
      final pillsTaken = snapshot.data!['pillsTaken'] as int;
      final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Pill Intake Heatmap'),
          const SizedBox(height: 8),
          _buildHeatmap(pillStatus),
          const SizedBox(height: 16),

            // // Bar chart section
            //         _buildSectionTitle('Pills Taken vs. Missed'),
            //         const SizedBox(height: 8),
            //         Container(
            //           height: 250,
            //           decoration: BoxDecoration(
            //             color: Colors.white,
            //             borderRadius: BorderRadius.circular(12),
            //             boxShadow: [
            //               BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            //             ],
            //           ),
            //           child: _buildBarChart(pillStatus, daysInMonth),
            //         ),
            //         const SizedBox(height: 16),

                    // Pie chart section
                    _buildSectionTitle('Pills Distribution'),
                    const SizedBox(height: 8),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: _buildPieChart(pillStatus, daysInMonth),
                    ),


          _buildSectionTitle('Cumulative Pills Taken'),
          const SizedBox(height: 8),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: _buildCumulativeChart(pillStatus, daysInMonth),
          ),


          // // Add success rate gauge
          // _buildSectionTitle('Success Rate'),
          // const SizedBox(height: 8),
          // _buildSuccessGauge(totalPills, pillsTaken),
          // const SizedBox(height: 16),
        ],
      );
    }
  },
),

        ],
      ),
    ),
  );
}


Widget _buildSuccessGauge(int totalPills, int pillsTaken) {
  if (totalPills == 0) {
    return Center(child: Text('No pills scheduled for this month'));
  }

  double successRate = (pillsTaken / totalPills) * 100;

  return Column(
    children: [
      SizedBox(
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: pillsTaken / totalPills,
              strokeWidth: 10,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            Text(
              '${successRate.toStringAsFixed(1)}%', // Display the success rate as a percentage
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'You have taken $pillsTaken out of $totalPills pills',
        style: TextStyle(fontSize: 16),
      ),
    ],
  );
}


  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.normal, color: Colors.black),
    );
  }
Future<Map<String, dynamic>> _getPillStatusData() async {
  final User? user = _auth.currentUser;
  if (user == null) {
    throw Exception('No logged-in user found.');
  }

  final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
  Map<int, String> pillStatus = {};
  int totalPills = 0;
  int pillsTaken = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    final dateKey = '${_currentMonth.year}-${_currentMonth.month}-$day';
    final trackingDocs = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tracking')
        .doc(dateKey)
        .collection('pills')
        .get();

    totalPills += trackingDocs.size;
    int dailyPillsTaken = 0;

    for (var doc in trackingDocs.docs) {
      final bool? taken = doc.data()['taken'] as bool?;
      if (taken == true) {
        dailyPillsTaken++;
      }
    }

    pillsTaken += dailyPillsTaken; 

    if (trackingDocs.size == 0) {
      pillStatus[day] = 'none'; 
    } else if (dailyPillsTaken == trackingDocs.size) {
      pillStatus[day] = 'all';
    } else {
      pillStatus[day] = 'some'; 
    }
  }

  return {
    'pillStatus': pillStatus,
    'totalPills': totalPills,
    'pillsTaken': pillsTaken,
  };
}

  Widget _buildHeatmap(Map<int, String> pillStatus) {
  final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
    ),
    itemCount: daysInMonth,
    itemBuilder: (context, index) {
      final day = index + 1;
      final String status = pillStatus[day] ?? 'none'; 

      Color dayColor;
      switch (status) {
        case 'all':
          dayColor = Colors.green; 
          break;
        case 'some':
          dayColor = Colors.yellow; 
          break;
        case 'none':
        default:
          dayColor = const Color.fromARGB(255, 215, 224, 228); 
          break;
      }

      return Container(
        decoration: BoxDecoration(
          color: dayColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Center(
          child: Text(
            '$day',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.normal,
              fontSize: 16, 
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildCumulativeChart(Map<int, String> pillStatus, int daysInMonth) {
  List<FlSpot> cumulativeSpots = [];
  int cumulativeTaken = 0;

  for (int day = 1; day <= daysInMonth; day++) {
    if (pillStatus[day] == 'all') {
      cumulativeTaken += 1;
    }
    cumulativeSpots.add(FlSpot(day.toDouble(), cumulativeTaken.toDouble()));
  }

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ));
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: cumulativeSpots,
            isCurved: true,
            color: const Color(0xFF2196F3),
            barWidth: 3,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2196F3).withOpacity(0.2),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    ),
  );
}

Widget _buildLineChart(Map<int, String> pillStatus, int daysInMonth) {
  List<FlSpot> spots = [];
  for (int day = 1; day <= daysInMonth; day++) {
    double value = pillStatus[day] == 'all' ? 1.0 : 0.0;
    spots.add(FlSpot(day.toDouble(), value));
  }

  return Padding(
    padding: const EdgeInsets.all(16.0), 
    child: LineChart(
      LineChartData(
        gridData: FlGridData(show: false), 
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt() == 0 ? '' : value.toInt().toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.5), width: 1),
        ),
        minX: 0,
        maxX: daysInMonth.toDouble(),
        minY: 0,
        maxY: 1,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF2196F3), 
            barWidth: 3, 
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2196F3).withOpacity(0.2), 
            ),
            dotData: FlDotData(show: false), 
          ),
        ],
      ),
    ),
  );
}


Widget _buildBarChart(Map<int, String> pillStatus, int daysInMonth) {
  int totalPills = pillStatus.length;
  int pillsTaken = pillStatus.values.where((status) => status == 'all').length;
  int pillsMissed = totalPills - pillsTaken;

  return Padding(
    padding: const EdgeInsets.all(16.0), 
    child: BarChart(
      BarChartData(
        gridData: FlGridData(show: false), 
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), 
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt() == 0 ? '' : ['', ''][value.toInt() - 1],
                  style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false, 
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
              toY: pillsTaken.toDouble(),
              color: const Color(0xFF4CAF50), 
              width: 16, 
              borderRadius: BorderRadius.circular(8), 
            ),
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
              toY: pillsMissed.toDouble(),
              color: const Color(0xFFE57373), 
              width: 16,
              borderRadius: BorderRadius.circular(8), 
            ),
          ]),
        ],
      ),
    ),
  );
}

Widget _buildPieChart(Map<int, String> pillStatus, int daysInMonth) {
  int totalPills = pillStatus.length;
  int pillsTaken = pillStatus.values.where((status) => status == 'all').length;
  int pillsMissed = totalPills - pillsTaken;

  return PieChart(
    PieChartData(
      sections: [
        PieChartSectionData(
          value: pillsTaken.toDouble(),
          color: const Color(0xFF4CAF50), 
          title: '$pillsTaken',
          radius: 40, 
          titleStyle: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.white, 
          ),
          badgeWidget: _buildBadge('$pillsTaken', Color(0xFF4CAF50)), 
          badgePositionPercentageOffset: 1.3, 
        ),
        PieChartSectionData(
          value: pillsMissed.toDouble(),
          color: const Color(0xFFE57373), 
          title: '$pillsMissed',
          radius: 40, 
          titleStyle: const TextStyle(
            fontSize: 16, 
            fontWeight: FontWeight.bold,
            color: Colors.white, 
          ),
          badgeWidget: _buildBadge('$pillsMissed', Color(0xFFE57373)), 
          badgePositionPercentageOffset: 1.3, 
        ),
      ],
      centerSpaceRadius: 50, 
      sectionsSpace: 4, 
      startDegreeOffset: 180, 
    ),
  );
}


Widget _buildBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 4,
          offset: const Offset(0, 2), 
        ),
      ],
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

}
