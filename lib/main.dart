import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'services/supabase_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/admin_login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/packages/package_list_screen.dart';
import 'screens/booking/my_bookings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  if (dotenv.env['SUPABASE_URL'] == null ||
      dotenv.env['SUPABASE_ANON_KEY'] == null) {
    throw Exception('Missing Supabase environment variables');
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await SupabaseService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  bool get isDesktopPlatform {
    if (kIsWeb) {
      return false; // Web is not considered desktop for admin access
    }
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Cleaning Service',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4FB6D0), // Light blue as primary color
          primary: const Color(0xFF4FB6D0),
          secondary: const Color(0xFF81C784), // Soft green
          background: Colors.white,
          surface: Colors.white,
        ),
        useMaterial3: true,
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      home: isDesktopPlatform ? const AdminLoginScreen() : const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const UserDashboard(),
        '/packages': (context) => const PackageListScreen(),
        '/bookings': (context) => const MyBookingsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SupabaseService().getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const UserDashboard();
        }

        return const LoginScreen();
      },
    );
  }
}

class UserDashboard extends StatelessWidget {
  const UserDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Cleaning Service'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await SupabaseService().signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _DashboardCard(
                  icon: Icons.cleaning_services,
                  title: 'Book Service',
                  onTap: () {
                    Navigator.of(context).pushNamed('/packages');
                  },
                ),
                _DashboardCard(
                  icon: Icons.calendar_today,
                  title: 'My Bookings',
                  onTap: () {
                    Navigator.of(context).pushNamed('/bookings');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
