import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app;
import '../models/cleaning_package.dart';
import '../models/booking.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;

  final _client = supabase.Supabase.instance.client;
  static const String _authKey = 'is_authenticated';

  SupabaseService._internal();

  Future<void> initialize() async {
    // Initialize any service-specific setup here
    // No need to initialize Supabase again as it's done in main.dart
  }

  // Auth methods
  // Future<User?> signUp(String email, String password, String firstName,
  //     String lastName, String phoneNumber, String address) async {
  //   try {
  //     final authResponse = await _client.auth.signUp(
  //       email: email,
  //       password: password,
  //     );

  //     if (authResponse.user != null) {
  //       final now = DateTime.now().toIso8601String();
  //       final userData = {
  //         'id': authResponse.user!.id,
  //         'email': email,
  //         'role': 'customer',
  //         'first_name': firstName,
  //         'last_name': lastName,
  //         'phone_number': phoneNumber,
  //         'address': address,
  //         'created_at': now,
  //         'updated_at': now,
  //       };

  //       // Insert the user data into the users table
  //       final response =
  //           await _client.from('users').insert(userData).select().single();

  //       // Sign out the user so they can log in properly
  //       await _client.auth.signOut();
  //       print("userdata: ${User.fromJson(response)}");

  //       return User.fromJson(response);
  //     }
  //     return null;
  //   } catch (e) {
  //     // If user creation in users table fails, try to delete the auth user
  //     try {
  //       final currentUser = _client.auth.currentUser;
  //       if (currentUser != null) {
  //         await _client.auth.admin.deleteUser(currentUser.id);
  //       }
  //     } catch (_) {
  //       // Ignore cleanup errors
  //     }
  //     throw Exception('Failed to sign up: $e');
  //   }
  // }

  Future<void> signUp(String email, String password, String firstName,
      String lastName, String phoneNumber, String address) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      // Check if user exists and has an ID
      final user = authResponse.user;
      if (user == null || user.id.isEmpty) {
        throw Exception('Auth user creation failed - no ID returned');
      }

      // Proceed with database insert
      final now = DateTime.now().toIso8601String();
      final userData = {
        'id': user.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
        'address': address,
        'role': 'customer',
        'created_at': now,
        'updated_at': now,
      };

      // Insert the user data into the users table
      await _client.from('users').insert(userData);

      // Sign out the user so they can log in properly
      await _client.auth.signOut();
    } catch (e) {
      // If user creation in users table fails, try to delete the auth user
      try {
        final currentUser = _client.auth.currentUser;
        if (currentUser != null) {
          await _client.auth.admin.deleteUser(currentUser.id);
        }
      } catch (cleanupError) {
        // Ignore cleanup errors
      }
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<app.User?> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Authentication failed');
      }

      // Store authentication state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authKey, true);

      try {
        final userData = await _client
            .from('users')
            .select()
            .eq('id', response.user!.id)
            .single();

        if (userData == null) {
          throw Exception('User data not found');
        }

        return app.User.fromJson(userData as Map<String, dynamic>);
      } catch (e) {
        // If we can't get user data, sign out and clear auth state
        await signOut();
        throw Exception('Failed to get user data: $e');
      }
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await _client.auth.signOut();
  }

  // User methods
  Future<app.User?> getCurrentUser() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) return null;

    final response =
        await _client.from('users').select().eq('id', currentUser.id).single();

    if (response == null) return null;
    return app.User.fromJson(response as Map<String, dynamic>);
  }

  Future<app.User?> getUserById(String userId) async {
    try {
      final response =
          await _client.from('users').select().eq('id', userId).single();
      if (response == null) return null;
      return app.User.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Package methods
  Future<List<CleaningPackage>> getCleaningPackages() async {
    try {
      final response =
          await _client.from('cleaning_packages').select().order('price');

      return (response as List).map((json) {
        // Ensure services is a List<String>
        List<String> services = [];
        if (json['services'] != null) {
          services = List<String>.from(json['services'] as List);
        }

        // Create a new map with the correct services type
        final Map<String, dynamic> cleanJson = {
          ...json,
          'services': services,
        };

        return CleaningPackage.fromJson(cleanJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch cleaning packages: $e');
    }
  }

  // Booking methods
  Future<int> createBooking(Booking booking) async {
    try {
      // Convert the booking to JSON and ensure dates are in ISO8601 format
      final bookingJson = booking.toJson();
      // Remove the id field as it should be auto-generated
      bookingJson.remove('id');

      // Convert package_id to integer if it's a string
      if (bookingJson['package_id'] is String) {
        bookingJson['package_id'] = int.parse(bookingJson['package_id']);
      }

      bookingJson['created_at'] = booking.createdAt.toIso8601String();
      bookingJson['updated_at'] = booking.updatedAt.toIso8601String();
      bookingJson['scheduled_date'] = booking.scheduledDate.toIso8601String();

      final response =
          await _client.from('bookings').insert(bookingJson).select().single();

      return (response as Map<String, dynamic>)['id'] as int;
    } catch (e) {
      throw Exception('Error creating booking: $e');
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('customer_id', userId)
        .order('scheduled_date', ascending: false);

    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<List<Booking>> getEmployeeBookings(String employeeId) async {
    final response = await _client
        .from('bookings')
        .select()
        .eq('employee_id', employeeId)
        .inFilter(
            'status', ['confirmed', 'inProgress']).order('scheduled_date');

    return (response as List).map((json) => Booking.fromJson(json)).toList();
  }

  Future<void> updateBookingStatus(
      String bookingId, BookingStatus status) async {
    try {
      await _client
          .from('bookings')
          .update({'status': status.toString().split('.').last}).eq(
              'id', int.parse(bookingId));
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  Future<List<Booking>> getAllBookings() async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .order('scheduled_date', ascending: false);

      return (response as List).map((json) {
        // Ensure id is handled as an integer
        final Map<String, dynamic> bookingJson =
            Map<String, dynamic>.from(json);
        if (bookingJson['id'] != null) {
          bookingJson['id'] = (bookingJson['id'] as num).toInt();
        }
        return Booking.fromJson(bookingJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  Future<List<CleaningPackage>> getAllPackages() async {
    try {
      final response =
          await _client.from('cleaning_packages').select().order('price');
      return (response as List)
          .map((json) => CleaningPackage.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch packages: $e');
    }
  }

  Future<List<app.User>> getAllEmployees() async {
    try {
      final response =
          await _client.from('users').select().eq('role', 'employee');
      return (response as List).map((json) => app.User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch employees: $e');
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    // Get start and end of current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      // Get total customers (excluding admins and employees)
      final totalUsers =
          await _client.from('users').select().eq('role', 'customer');

      // Get total employees
      final totalEmployees =
          await _client.from('users').select().eq('role', 'employee');

      // Get bookings for current month
      final monthlyBookings = await _client
          .from('bookings')
          .select()
          .gte('created_at', startOfMonth.toIso8601String())
          .lte('created_at', endOfMonth.toIso8601String());

      return {
        'totalUsers': (totalUsers as List).length,
        'totalEmployees': (totalEmployees as List).length,
        'monthlyBookings': (monthlyBookings as List).length,
      };
    } catch (e) {
      print('Error getting admin stats: $e');
      return {
        'totalUsers': 0,
        'totalEmployees': 0,
        'monthlyBookings': 0,
      };
    }
  }
}
