import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ✅ WRAP WITH PopScope
    return PopScope(
      canPop: false, // This disables the system back button
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 100,
                  color: Colors.green.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  'Request Submitted!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your booking request has been sent to the administration for review. You will be notified of its status.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // This is now the ONLY way to leave this screen
                    context.go('/my-bookings');
                  },
                  child: const Text('View My Bookings'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}