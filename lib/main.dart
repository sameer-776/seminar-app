// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:seminar_booking_app/services/auth_service.dart';
import 'package:seminar_booking_app/services/firestore_service.dart';
import 'package:seminar_booking_app/services/push_notification_service.dart';
import 'firebase_options.dart'; // Make sure this file exists
import 'package:seminar_booking_app/config/theme.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/widgets/app_shell.dart';
import 'package:seminar_booking_app/screens/auth/login_screen.dart';
import 'package:seminar_booking_app/screens/shared/facilities_screen.dart';
import 'package:seminar_booking_app/screens/shared/profile_screen.dart';
import 'package:seminar_booking_app/screens/shared/notifications_screen.dart';
import 'package:seminar_booking_app/screens/faculty/home_screen_faculty.dart';
import 'package:seminar_booking_app/screens/faculty/booking_screen.dart';
import 'package:seminar_booking_app/screens/faculty/availability_checker_screen.dart';
import 'package:seminar_booking_app/screens/faculty/booking_form_screen.dart';
import 'package:seminar_booking_app/screens/faculty/my_bookings_screen.dart';
import 'package:seminar_booking_app/screens/faculty/booking_details_screen.dart';
import 'package:seminar_booking_app/screens/admin/home_screen_admin.dart';
import 'package:seminar_booking_app/screens/admin/booked_halls_screen.dart';
import 'package:seminar_booking_app/screens/admin/hall_management_screen.dart';
import 'package:seminar_booking_app/screens/admin/user_management_screen.dart';
import 'package:seminar_booking_app/screens/admin/analytics_screen.dart';
import 'package:seminar_booking_app/screens/admin/booking_history_screen.dart';
import 'package:seminar_booking_app/screens/admin/review_booking_screen.dart';
import 'package:seminar_booking_app/screens/admin/manage_hub_screen.dart';
import 'package:collection/collection.dart'; // Used for .firstWhereOrNull
import 'package:seminar_booking_app/screens/faculty/booking_confirmation_screen.dart';
import 'package:seminar_booking_app/screens/shared/about_us_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PushNotificationService().initialize();
  final authService = AuthService();
  final firestoreService = FirestoreService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: authService),
        Provider.value(value: firestoreService),
        ChangeNotifierProvider(
          create: (context) => AppState(
            authService: authService,
            firestoreService: firestoreService,
          ),
        ),
      ],
      child: const SeminarApp(),
    ),
  );
}

class SeminarApp extends StatefulWidget {
  const SeminarApp({super.key});

  @override
  State<SeminarApp> createState() => _SeminarAppState();
}

class _SeminarAppState extends State<SeminarApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _router = createRouter(appState);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select((AppState state) =>
        state.isDarkMode ? ThemeMode.dark : ThemeMode.light);

    return MaterialApp.router(
      title: 'Seminar Hall Booking',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

GoRouter createRouter(AppState appState) {
  return GoRouter(
    initialLocation: '/login', 
    refreshListenable: appState,
    debugLogDiagnostics: true,
    routes: [
      // Standalone routes (no shell)
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      
      // ✅ DELETED THE /register ROUTE
      // GoRoute(
      //     path: '/register',
      //     builder: (context, state) => const RegisterScreen()),

      GoRoute(
        path: '/booking/form',
        builder: (context, state) {
          // ... (rest of the route is unchanged)
          final hallId = state.uri.queryParameters['hallId'];
          final dateStr = state.uri.queryParameters['date'];
          final startTimeStr = state.uri.queryParameters['startTime'];
          final endTimeStr = state.uri.queryParameters['endTime'];

          if (hallId == null ||
              dateStr == null ||
              startTimeStr == null ||
              endTimeStr == null) {
            return const Scaffold(
              body: Center(
                child: Text('Error: Missing booking information.'),
              ),
            );
          }
          try {
            final hall = context
                .read<AppState>()
                .halls
                .firstWhereOrNull((h) => h.id == hallId);
            if (hall == null) {
              return Scaffold(
                  body:
                      Center(child: Text('Error: Hall $hallId not found.')));
            }
            final date = DateTime.parse(dateStr);
            final startTime = TimeOfDay(
              hour: int.parse(startTimeStr.split(':')[0]),
              minute: int.parse(startTimeStr.split(':')[1]),
            );
            final endTime = TimeOfDay(
              hour: int.parse(endTimeStr.split(':')[0]),
              minute: int.parse(endTimeStr.split(':')[1]),
            );
            return BookingFormScreen(
              hall: hall,
              date: date,
              startTime: startTime,
              endTime: endTime,
            );
          } catch (e) {
            return Scaffold(
              body: Center(
                child: Text('Error: Invalid booking data. $e'),
              ),
            );
          }
        },
      ),

      GoRoute(
        path: '/booking/confirmation',
        builder: (context, state) => const BookingConfirmationScreen(),
      ),

      GoRoute(
        path: '/about-us',
        builder: (context, state) => const AboutUsScreen(),
      ),

      // Main routes wrapped in the AppShell
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // ... (all other ShellRoute routes are unchanged)
          // Shared Routes
          GoRoute(
              path: '/facilities',
              builder: (context, state) => const FacilitiesScreen()),
          GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen()),
          GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen()),

          // Faculty Routes
          GoRoute(
              path: '/',
              builder: (context, state) => const FacultyHomeScreen()),
          GoRoute(
              path: '/my-bookings',
              builder: (context, state) => const MyBookingsScreen()),
          GoRoute(
            path: '/booking/details/:bookingId',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId'];
              if (bookingId == null) {
                return const Scaffold(
                    body: Center(child: Text('Error: Booking ID missing.')));
              }
              final booking = context
                  .read<AppState>()
                  .bookings
                  .firstWhereOrNull((b) => b.id == bookingId);
              if (booking == null) {
                return Scaffold(
                    body: Center(
                        child: Text(
                            'Error: Booking with ID $bookingId not found.')));
              }
              return BookingDetailsScreen(booking: booking);
            },
          ),
          GoRoute(
              path: '/booking',
              builder: (context, state) => const BookingScreen()),
          GoRoute(
            path: '/booking/availability/:hallId',
            builder: (context, state) {
              final hallId = state.pathParameters['hallId'];
              if (hallId == null) {
                return const Scaffold(
                    body: Center(child: Text('Error: Hall ID missing.')));
              }
              final hall = context
                .read<AppState>()
                .halls
                .firstWhereOrNull((h) => h.id == hallId);
              if (hall == null) {
                return Scaffold(
                    body: Center(
                        child:
                            Text('Error: Hall with ID $hallId not found.')));
              }
              return AvailabilityCheckerScreen(hall: hall);
            },
          ),

          // Admin Routes
          GoRoute(
              path: '/admin/home',
              builder: (context, state) => const AdminHomeScreen()),
          GoRoute(
            path: '/admin/review/:bookingId',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId'];
              if (bookingId == null) {
                return const Scaffold(
                    body: Center(child: Text('Error: Booking ID missing.')));
              }
              final booking = context
                  .read<AppState>()
                  .bookings
                  .firstWhereOrNull((b) => b.id == bookingId);
              if (booking == null) {
                return Scaffold(
                    body: Center(
                        child: Text(
                            'Error: Booking with ID $bookingId not found.')));
              }
              return ReviewBookingScreen(booking: booking);
            },
          ),
          GoRoute(
              path: '/admin/bookings',
              builder: (context, state) => const BookedHallsScreen()),
          GoRoute(
              path: '/admin/halls',
              builder: (context, state) => const HallManagementScreen()),
          GoRoute(
              path: '/admin/history',
              builder: (context, state) => const BookingHistoryScreen()),
          GoRoute(
              path: '/admin/manage',
              builder: (context, state) => const ManageHubScreen()),
          GoRoute(
              path: '/admin/users',
              builder: (context, state) => const UserManagementScreen()),
          GoRoute(
              path: '/admin/analytics',
              builder: (context, state) => const AnalyticsScreen()),
        ],
      ),
    ],
    // --- Redirection Logic ---
    redirect: (context, state) {
      final isLoggedIn = appState.isLoggedIn;
      final currentUser = appState.currentUser;
      final role = currentUser?.role;
      final location = state.matchedLocation;
      
      // ✅ REMOVED /register FROM THE CHECK
      final isAuthPage = location == '/login' ||
          location == '/splash';

      // 1. If user is not logged in and not on an auth page, redirect to login
      if (!isLoggedIn && !isAuthPage) {
        return '/login';
      }

      // 2. If user is logged in and tries to go to an auth page, redirect to home
      if (isLoggedIn && isAuthPage) {
        return role == 'admin' ? '/admin/home' : '/';
      }

      // 3. Check for new Google Sign-In users with incomplete data
      if (isLoggedIn &&
          (currentUser?.department == 'Unknown' ||
           currentUser?.employeeId == '0000')) {
        
        if (location != '/profile') {
          return '/profile';
        }
      }

      // 4. Secure admin routes
      final bool isFaculty = role == 'Faculty';
      final bool isAdminPage = location.startsWith('/admin');

      if (isLoggedIn && isFaculty && isAdminPage) {
        return '/';
      }

      return null;
    },
  );
}