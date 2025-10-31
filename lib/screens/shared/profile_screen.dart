// lib/screens/shared/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/providers/app_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _departmentController;
  late TextEditingController _employeeIdController;
  
  // --- ✅ "NEW USER UI" VARIABLE ---
  bool _isNewUser = false; // To show the welcome message
  bool _isLoading = false; 

  String getInitials(String name) {
    if (name.isEmpty) return '...';
    final names = name.trim().split(' ');
    if (names.length > 1 && names.last.isNotEmpty) {
      return names[0][0].toUpperCase() + names.last[0].toUpperCase();
    } else if (names.isNotEmpty && names[0].isNotEmpty) {
      return names[0].substring(0, 1).toUpperCase();
    }
    return '?';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentUser = context.watch<AppState>().currentUser; 
    
    if (!_isLoading) {
      _nameController = TextEditingController(text: currentUser?.name ?? '');
      _departmentController =
          TextEditingController(text: currentUser?.department ?? '');
      _employeeIdController = 
          TextEditingController(text: currentUser?.employeeId ?? '');

      // --- ✅ "NEW USER UI" LOGIC ---
      // Checks for incomplete data from Google Sign-In
      if (currentUser?.department == 'Unknown' || currentUser?.employeeId == '0000') {
        _isNewUser = true; // Set flag to show a message
        if (currentUser?.department == 'Unknown') _departmentController.clear();
        if (currentUser?.employeeId == '0000') _employeeIdController.clear();
      } else {
        _isNewUser = false;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final appState = context.read<AppState>();
      
      try {
        await appState.updateUserProfile(
          name: _nameController.text.trim(),
          department: _departmentController.text.trim(),
          employeeId: _employeeIdController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: Colors.green),
          );
          // --- ✅ "NEW USER UI" UPDATE ---
          // After saving, they are no longer a "new user"
          setState(() {
            _isNewUser = false;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error updating profile: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }
    
    final String? photoUrl = currentUser.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        // --- ✅ "NEW USER UI" ---
        // Hides the back button if they are a new user
        leading: _isNewUser ? const SizedBox() : null,
        actions: [
          IconButton(
            icon: Icon(appState.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            tooltip: 'Toggle Theme',
            onPressed: () {
              context.read<AppState>().toggleTheme();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      getInitials(currentUser.name),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currentUser.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            currentUser.email,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // --- ✅ "NEW USER UI" MESSAGE ---
          // This container only appears if they are a new user
          if (_isNewUser)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300)
              ),
              child: const Text(
                'Welcome! Please complete your profile to continue using the app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
          if (_isNewUser) const SizedBox(height: 20),
          // --- END "NEW USER UI" MESSAGE ---

          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Name cannot be empty' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business_center_outlined),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Department cannot be empty' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Employee ID',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Employee ID cannot be empty' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSaveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 24, width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                      )
                    : const Text('Save Profile'),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Divider(),
          ),

          ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('About TECH ŚŪNYA'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/about-us');
            },
          ),
          
          // --- ✅ ERROR FIX ---
          // Replaced the incorrect `TextStyle` with the correct one.
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade700),
            title: Text('Logout', style: TextStyle(color: Colors.red.shade700)),
            onTap: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Logout'),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(); 
                        context.read<AppState>().logout();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          // --- END ERROR FIX ---
        ],
      ),
    );
  }
}