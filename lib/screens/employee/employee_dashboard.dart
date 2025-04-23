import 'package:flutter/material.dart';
import 'package:hcs_booking_system/models/booking.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final user = await SupabaseService().getCurrentUser();
    if (user != null) {
      setState(() {
        _bookingsFuture = SupabaseService().getEmployeeBookings(user.id);
      });
    }
  }

  Future<void> _updateBookingStatus(
      Booking booking, BookingStatus newStatus) async {
    try {
      await SupabaseService()
          .updateBookingStatus(booking.id.toString(), newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully')),
        );
        _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
          ),
        ],
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final bookings = snapshot.data ?? [];

          if (bookings.isEmpty) {
            return const Center(
              child: Text('No assigned bookings'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text(
                    'Booking #${booking.id.toString().substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('MMM dd, yyyy hh:mm a')
                        .format(booking.scheduledDate),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Status',
                              booking.status.toString().split('.').last),
                          const SizedBox(height: 8),
                          _buildInfoRow('Address', booking.address),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (booking.status == BookingStatus.confirmed)
                                ElevatedButton(
                                  onPressed: () => _updateBookingStatus(
                                    booking,
                                    BookingStatus.inProgress,
                                  ),
                                  child: const Text('Start Job'),
                                ),
                              if (booking.status == BookingStatus.inProgress)
                                ElevatedButton(
                                  onPressed: () => _updateBookingStatus(
                                    booking,
                                    BookingStatus.completed,
                                  ),
                                  child: const Text('Complete Job'),
                                ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
