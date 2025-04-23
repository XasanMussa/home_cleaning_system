import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class AdminStatsDashboard extends StatefulWidget {
  const AdminStatsDashboard({super.key});

  @override
  State<AdminStatsDashboard> createState() => _AdminStatsDashboardState();
}

class _AdminStatsDashboardState extends State<AdminStatsDashboard> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await SupabaseService().getAdminStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
            tooltip: 'Refresh Stats',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService().signOut();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/admin-login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    children: [
                      _buildStatCard(
                        'Total Users',
                        _stats['totalUsers']?.toString() ?? '0',
                        Icons.people,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Total Bookings',
                        _stats['totalBookings']?.toString() ?? '0',
                        Icons.calendar_today,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Active Bookings',
                        _stats['activeBookings']?.toString() ?? '0',
                        Icons.pending_actions,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Total Revenue',
                        '\$${_stats['totalRevenue']?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.attach_money,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Completed Bookings',
                        _stats['completedBookings']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.teal,
                      ),
                      _buildStatCard(
                        'Cancelled Bookings',
                        _stats['cancelledBookings']?.toString() ?? '0',
                        Icons.cancel,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TODO: Add a table or list of recent bookings/activities
                ],
              ),
            ),
    );
  }
}
