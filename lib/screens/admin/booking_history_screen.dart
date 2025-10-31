import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the list with all bookings

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }


  Widget _buildStatusChip(String status) {
    return ChoiceChip(
      label: Text(status),
      selected: _statusFilter == status,
      onSelected: (selected) {
        setState(() {
          _statusFilter = selected ? status : 'All';
        });
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: _statusFilter == status ? Colors.white : null,
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    // ✅ FIX: Use context.watch() here to listen for real-time data updates.
    final allBookings = context.watch<AppState>().bookings;
    final currentUser = context.watch<AppState>().currentUser;

    // Apply filters and search query on every build.
    final filteredBookings = allBookings.where((booking) {
      final statusMatch = _statusFilter == 'All' || booking.status == _statusFilter;
      final searchMatch = _searchQuery.isEmpty ||
          booking.title.toLowerCase().contains(_searchQuery) ||
          booking.requestedBy.toLowerCase().contains(_searchQuery) ||
          booking.hall.toLowerCase().contains(_searchQuery);
      return statusMatch && searchMatch;
    }).toList()
    ..sort((a,b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date)));

    // Security check
    if (currentUser?.role != 'admin') {
      return const Scaffold(body: Center(child: Text('Access Denied.')));
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking History'),
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by title, requester, or hall',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          // --- Filter Chips ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8.0,
              children: [
                _buildStatusChip('All'),
                _buildStatusChip('Approved'),
                _buildStatusChip('Pending'),
                _buildStatusChip('Rejected'),
                _buildStatusChip('Cancelled'),
              ],
            ),
          ),
          const Divider(height: 24),
          // --- Results List ---
           Expanded(
            child: filteredBookings.isEmpty
                ? const Center(child: Text('No bookings match your criteria.'))
                : ListView.builder(
                    itemCount: filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = filteredBookings[index];
                      return Card(
                         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          title: Text(booking.title),
                          subtitle: Text('${booking.requestedBy} - ${booking.hall}'),
                          trailing: Column(
                             crossAxisAlignment: CrossAxisAlignment.end,
                             mainAxisAlignment: MainAxisAlignment.center,
                             children: [
                               Text(DateFormat.yMd().format(DateTime.parse(booking.date))),
                               Text(booking.status, style: TextStyle(color: _getStatusColor(booking.status))),
                             ],
                           ),
                          onTap: () {
                            context.go('/admin/review/${booking.id}');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}



  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Cancelled':
        return Colors.grey;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.black;
    }
  }
