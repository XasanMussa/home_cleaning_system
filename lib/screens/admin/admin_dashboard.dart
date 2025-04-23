import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user.dart';
import '../../models/booking.dart';
import '../../services/supabase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  static const int _kTabCount = 3; // Define tab count as a constant
  late TabController _tabController;
  late Future<List<Booking>> _bookingsFuture;
  late Future<List<User>> _employeesFuture;
  late Future<Map<String, dynamic>> _adminStatsFuture;
  final SupabaseService _supabaseService = SupabaseService();
  int _totalUsers = 0;
  int _totalEmployees = 0;
  int _monthlyBookings = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabCount, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _bookingsFuture = _supabaseService.getAllBookings();
      _employeesFuture = _supabaseService.getAllEmployees();
      _adminStatsFuture = _supabaseService.getAdminStats();
    });

    try {
      final stats = await _supabaseService.getAdminStats();
      if (mounted) {
        setState(() {
          _totalUsers = stats['totalUsers'] ?? 0;
          _totalEmployees = stats['totalEmployees'] ?? 0;
          _monthlyBookings = stats['monthlyBookings'] ?? 0;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
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
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      case 'inprogress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey(
          'admin_dashboard'), // Add a key to force proper rebuild
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard_outlined),
              text: 'Overview',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.calendar_today_outlined),
              text: 'Bookings',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
            Tab(
              icon: Icon(Icons.people_outline),
              text: 'Users',
              iconMargin: EdgeInsets.only(bottom: 4),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBookingsTab(),
          _buildEmployeesTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _adminStatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard Overview',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Users',
                      _totalUsers,
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total Employees',
                      _totalEmployees,
                      Icons.work,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Monthly Bookings',
                      _monthlyBookings,
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsTab() {
    return FutureBuilder<List<Booking>>(
      future: _bookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(child: Text('No bookings found'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('ID')),
              DataColumn(label: Text('Customer')),
              DataColumn(label: Text('Date')),
              DataColumn(label: Text('Location')),
              DataColumn(label: Text('Description')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Payment')),
              DataColumn(label: Text('Actions')),
            ],
            rows: bookings.map((booking) {
              return DataRow(
                cells: [
                  DataCell(Text(booking.id?.toString() ?? '')),
                  DataCell(
                    FutureBuilder<User?>(
                      future: SupabaseService().getUserById(booking.customerId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(snapshot.data!.fullName);
                        }
                        return const Text('Loading...');
                      },
                    ),
                  ),
                  DataCell(
                    Text(DateFormat('MMM dd, yyyy')
                        .format(booking.scheduledDate)),
                  ),
                  DataCell(
                    Text(booking.location ?? 'No location provided'),
                  ),
                  DataCell(
                    Tooltip(
                      message: booking.description ?? 'No description provided',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          booking.description ?? 'No description provided',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(booking.status),
                        ),
                      ),
                      child: Text(
                        booking.status,
                        style: TextStyle(
                          color: _getStatusColor(booking.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(booking.paymentStatus)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(booking.paymentStatus),
                        ),
                      ),
                      child: Text(
                        booking.paymentStatus,
                        style: TextStyle(
                          color: _getStatusColor(booking.paymentStatus),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    PopupMenuButton<BookingStatus>(
                      onSelected: (BookingStatus status) {
                        if (booking.id != null) {
                          _updateBookingStatus(booking, status);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<BookingStatus>>[
                        const PopupMenuItem<BookingStatus>(
                          value: BookingStatus.confirmed,
                          child: Text('Confirm'),
                        ),
                        const PopupMenuItem<BookingStatus>(
                          value: BookingStatus.cancelled,
                          child: Text('Cancel'),
                        ),
                        const PopupMenuItem<BookingStatus>(
                          value: BookingStatus.completed,
                          child: Text('Complete'),
                        ),
                      ],
                      child: const Chip(
                        label: Text('Update Status'),
                        avatar: Icon(Icons.edit),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmployeesTab() {
    return FutureBuilder<List<User>>(
      future: _employeesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final employees = snapshot.data ?? [];

        if (employees.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No employees found'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    employee.fullName.isNotEmpty
                        ? employee.fullName[0].toUpperCase()
                        : employee.email[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  employee.fullName.isEmpty
                      ? employee.email
                      : employee.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(employee.email),
                    if (employee.phoneNumber != null) ...[
                      const SizedBox(height: 4),
                      Text(employee.phoneNumber!),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        // TODO: Implement employee editing
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // TODO: Implement employee deletion
                      },
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
