// lib/screens/admin/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart'; // For groupBy, mapIndexed

// --- ADD THESE PACKAGES TO YOUR PUBSPEC.YAML ---
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

import 'package:seminar_booking_app/widgets/stat_card.dart';
import 'package:seminar_booking_app/providers/app_state.dart';


class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  // --- Export Dialog Function ---
  void _showExportDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Export Data'),
          content: const Text('Which format would you like to export?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Export CSV'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _exportBookingsToCSV(context, appState.bookings);
              },
            ),
          ],
        );
      },
    );
  }

  // --- CSV Export Logic ---
  Future<void> _exportBookingsToCSV(BuildContext context, List<dynamic> bookings) async {
    if (bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export.')),
      );
      return;
    }

    try {
      // Define CSV headers
      List<String> headers = [
        'ID', 'Title', 'Hall', 'Date', 'Start Time', 'End Time',
        'Status', 'Requested By', 'Department', 'Attendees'
      ];
      
      // Map bookings data to list of lists
      List<List<dynamic>> rows = [];
      rows.add(headers); // Add headers as the first row
      
      for (var booking in bookings) {
        rows.add([
          booking.id,
          booking.title,
          booking.hall,
          booking.date,
          booking.startTime,
          booking.endTime,
          booking.status,
          booking.requestedBy,
          booking.department,
          booking.expectedAttendees,
        ]);
      }

      // Convert to CSV string
      final String csv = const ListToCsvConverter().convert(rows);

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/all_bookings_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.csv';

      // Write file
      final File file = File(path);
      await file.writeAsString(csv);

      // Share file
      await Share.shareXFiles(
        [XFile(path, name: 'all_bookings.csv')],
        subject: 'Seminar Hall Bookings Export',
      );

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting CSV: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);

    // Security check
    if (appState.currentUser?.role != 'admin') {
      return const Scaffold(
        body: Center(child: Text('Access Denied.')),
      );
    }
    
    final allBookings = appState.bookings;
    final approvedBookings = allBookings.where((b) => b.status == 'Approved').toList();
    final halls = appState.halls;

    if (allBookings.isEmpty) {
       return Scaffold(
        appBar: AppBar(title: const Text('Analytics Dashboard')),
        body: const Center(child: Text('No booking data available to generate analytics.'))
       );
    }

    // --- Chart 1 Data: Bookings per Hall ---
    final bookingsByHall = groupBy(approvedBookings, (b) => b.hall);
    final hallChartData = halls.mapIndexed((index, hall) {
      final count = bookingsByHall[hall.name]?.length ?? 0;
      return BarChartGroupData(x: index, barRods: [
        BarChartRodData(toY: count.toDouble(), color: theme.colorScheme.primary, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))
      ]);
    }).toList();

    // --- Chart 2 Data: Booking Trends by Month ---
    final bookingsByMonth = groupBy(allBookings, (booking) {
      return DateFormat('MMM').format(DateTime.parse(booking.date));
    });
    final monthOrder = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final lineChartSpots = monthOrder.mapIndexed((index, month) {
      final count = bookingsByMonth[month]?.length ?? 0;
      return FlSpot(index.toDouble(), count.toDouble());
    }).toList();

    // --- Chart 3 Data: Requests by Department ---
    final bookingsByDept = groupBy(allBookings, (b) => b.department);
    final deptChartData = bookingsByDept.entries.map((entry) {
      return {'name': entry.key, 'count': entry.value.length};
    }).toList();
    // ✅ FIX 1: Replaced sortedBy with standard sort
    deptChartData.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // --- Data for Key Metrics ---
    final totalPending = allBookings.where((b) => b.status == 'Pending').length;
    
    // ✅ FIX 1: Replaced sortedBy with standard sort
    final sortedHalls = bookingsByHall.entries.toList()
      ..sort((a, b) => a.value.length.compareTo(b.value.length));
    final mostBookedHall = sortedHalls.isEmpty ? null : sortedHalls.last;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          // --- Export Button ---
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export Data',
            onPressed: () {
              _showExportDialog(context, appState);
            },
          ),
        ],
      ),
      body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // --- Key Metrics Section ---
                Text(
                  'Key Metrics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: (1.8 / 1),
                  children: [
                    StatCard(
                      icon: Icons.list_alt_rounded,
                      title: 'Total Requests',
                      value: allBookings.length.toString(),
                    ),
                    StatCard(
                      icon: Icons.check_circle_outline,
                      title: 'Total Approved',
                      value: approvedBookings.length.toString(),
                    ),
                    StatCard(
                      icon: Icons.pending_actions_rounded,
                      title: 'Pending Review',
                      value: totalPending.toString(),
                    ),
                    StatCard(
                      icon: Icons.business_rounded,
                      title: 'Busiest Hall',
                      // ✅ FIX 1: Use .key on the MapEntry
                      value: mostBookedHall?.key ?? 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildChartCard(
                  title: "Approved Bookings per Hall",
                  chart: BarChart(
                    BarChartData(
                      barGroups: hallChartData,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= halls.length) return const SizedBox.shrink();
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(halls[index].name.length > 3 ? halls[index].name.substring(0, 3) : halls[index].name),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => SideTitleWidget(axisSide: meta.axisSide, child: Text(value.toInt().toString())))),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      alignment: BarChartAlignment.spaceAround,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildChartCard(
                  title: "Booking Trends by Month",
                  chart: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                               final index = value.toInt();
                               if (index >= monthOrder.length) return const SizedBox.shrink();
                               return SideTitleWidget(axisSide: meta.axisSide, child: Text(monthOrder[index]));
                            },
                            reservedSize: 30,
                            interval: 1,
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => SideTitleWidget(axisSide: meta.axisSide, child: Text(value.toInt().toString())))),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                      lineBarsData: [
                        LineChartBarData(
                          spots: lineChartSpots,
                          isCurved: true,
                          color: Colors.amber,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          
                          // ✅ FIX 2: 'withOpacity' replaced with 'withAlpha'
                          // (0.3 * 255 = 76.5, so we use 77)
                          belowBarData: BarAreaData(show: true, color: Colors.amber.withAlpha(77)), 
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildChartCard(
                  title: "All Requests by Department",
                  chart: BarChart(
                    BarChartData(
                       barGroups: deptChartData.mapIndexed((index, data) => BarChartGroupData(x: index, barRods: [
                         BarChartRodData(toY: (data['count'] as int).toDouble(), color: Colors.teal, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))
                       ])).toList(),
                       titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                             sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                   final index = value.toInt();
                                   if (index >= deptChartData.length) return const SizedBox.shrink();
                                   return SideTitleWidget(
                                      angle: -0.5,
                                      axisSide: meta.axisSide,
                                      child: Text(deptChartData[index]['name'] as String, style: const TextStyle(fontSize: 10)),
                                   );
                                },
                                reservedSize: 40,
                             ),
                          ),
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) => SideTitleWidget(axisSide: meta.axisSide, child: Text(value.toInt().toString())))),
                          
                          // ✅ FIX 3: Typo 'showTItles' corrected to 'showTitles'
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                       ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChartCard({required String title, required Widget chart}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(height: 250, child: chart),
          ],
        ),
      ),
    );
  }
}