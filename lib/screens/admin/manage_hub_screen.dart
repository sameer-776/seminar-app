// lib/screens/admin/manage_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManageHubScreen extends StatelessWidget {
  const ManageHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar is handled by the AppShell, so we don't need one here.
      // But if your other admin screens have one, add it back like this:
      // appBar: AppBar(
      //   title: const Text('Manage'),
      //   centerTitle: false,
      // ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // This title will appear below the main app bar
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Management Hub',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          _buildMenuCard(
            context,
            icon: Icons.business_outlined,
            title: 'Hall Management',
            subtitle: 'Add, edit, remove, or disable halls.',
            onTap: () => context.go('/admin/halls'),
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            context,
            icon: Icons.people_outline_rounded,
            title: 'User Management',
            subtitle: 'Add, delete, or change user roles.',
            onTap: () => context.go('/admin/users'),
          ),
        ],
      ),
    );
  }

  /// A helper widget to create the tappable cards
  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 14)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}