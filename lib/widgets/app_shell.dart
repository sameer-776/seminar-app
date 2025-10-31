// lib/widgets/app_shell.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:seminar_booking_app/providers/app_state.dart';

// 1. CONVERTED TO STATEFULWIDGET
class AppShell extends StatefulWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // 2. ADDED STATE VARIABLE TO TRACK NOTIFICATIONS
  int _previousUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    // 3. SET THE INITIAL COUNT
    _previousUnreadCount = context.read<AppState>().unreadNotificationCount;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 4. WATCH FOR CHANGES
    final newUnreadCount = context.watch<AppState>().unreadNotificationCount;

    // 5. COMPARE AND SHOW SNACKBAR IF COUNT INCREASED
    if (newUnreadCount > _previousUnreadCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("You have a new notification!"),
              action: SnackBarAction(
                label: "View",
                onPressed: () => context.go('/notifications'),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }

    // 6. UPDATE THE COUNT
    _previousUnreadCount = newUnreadCount;
  }

  @override
  Widget build(BuildContext context) {
    // All build logic is the same, just uses `widget.child`
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;
    final isAdmin = currentUser?.role == 'admin';
    final unreadCount = appState.unreadNotificationCount;

    final location = GoRouterState.of(context).matchedLocation;

    const adminSubPages = {
      '/admin/halls',
      '/admin/users',
    };

    final bool isSubPage = isAdmin && adminSubPages.contains(location);

    if (appState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: isSubPage
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () {
                  context.go('/admin/manage');
                },
              )
            : null,
        title: const Text('P.U. Booking'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: badges.Badge(
              showBadge: unreadCount > 0,
              badgeContent: Text(
                unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              context.go('/notifications');
              context.read<AppState>().markNotificationsAsRead();
            },
          ),
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: 'My Profile',
              onPressed: () {
                context.go('/profile');
              },
            ),
        ],
      ),
      body: widget.child, // Use widget.child
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context, isAdmin),
        onTap: (index) => _onItemTapped(index, context, isAdmin),
        items: _buildNavItems(isAdmin),
      ),
    );
  }
  
  // --- All helper methods below are unchanged ---

  List<BottomNavigationBarItem> _buildNavItems(bool isAdmin) {
    if (isAdmin) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month_rounded),
          label: 'Schedule',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business_center_outlined),
          activeIcon: Icon(Icons.business_center_rounded),
          label: 'Manage',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics_rounded),
          label: 'Analytics',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined), label: 'Facilities'),
        BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline), label: 'Book Hall'),
        BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined), label: 'My Bookings'),
      ];
    }
  }

  int _calculateSelectedIndex(BuildContext context, bool isAdmin) {
    final location = GoRouterState.of(context).matchedLocation;

    if (isAdmin) {
      if (location == '/admin/home') return 0;
      if (location == '/admin/bookings') return 1;
      if (location == '/admin/manage' ||
          location == '/admin/halls' ||
          location == '/admin/users') {
        return 2;
      }
      if (location == '/admin/analytics') return 3;
    } else {
      if (location == '/') return 0;
      if (location == '/facilities') return 1;
      if (location.startsWith('/booking')) return 2;
      if (location == '/my-bookings') return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isAdmin) {
    if (isAdmin) {
      switch (index) {
        case 0:
          context.go('/admin/home');
          break;
        case 1:
          context.go('/admin/bookings');
          break;
        case 2:
          context.go('/admin/manage');
          break;
        case 3:
          context.go('/admin/analytics');
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.go('/');
          break;
        case 1:
          context.go('/facilities');
          break;
        case 2:
          context.go('/booking');
          break;
        case 3:
          context.go('/my-bookings');
          break;
      }
    }
  }
}