import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/models/user.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:seminar_booking_app/services/auth_service.dart';
import 'package:seminar_booking_app/widgets/admin/add_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmationDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to permanently delete the user ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete User'),
            onPressed: () async {
              final authService = context.read<AuthService>();
              String? error;

              try {
                error = await authService.deleteUserByAdmin(uid: user.uid);

                if (dialogContext.mounted) Navigator.of(dialogContext).pop();

                if (context.mounted) {
                  if(error == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User ${user.name} deleted successfully.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting user: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting user: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _sendPasswordReset(BuildContext context, User user) async {
    final authService = context.read<AuthService>();
    String? error;

    try {
      error = await authService.sendPasswordResetEmail(user.email);
      if (context.mounted) {
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset email sent to ${user.email}.'),
              backgroundColor: Colors.blue,
            ),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send reset email: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reset email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- ✅ THIS DIALOG IS NOW FIXED ---
  void _showChangeRoleDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        String selectedRole = user.role;

        return StatefulBuilder(
          builder: (stfContext, setState) {
            return AlertDialog(
              title: Text('Change Role for ${user.name}'),
              content: DropdownButton<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'Faculty', child: Text('Faculty')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedRole = value;
                    });
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    final appState = context.read<AppState>();
                    String? error; // Variable to hold potential error message

                    try {
                      // ✅ Check the return value
                      error = await appState.updateUserRole(user.uid, selectedRole);

                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }

                      if (context.mounted) {
                        // ✅ Check if error is null
                        if (error == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Role for ${user.name} updated to $selectedRole.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          // ✅ Show the error message returned from the function
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error updating role: $error'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // This catches unexpected exceptions (e.g., network error)
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('An unexpected error occurred: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentUser = appState.currentUser;

    if (currentUser == null || currentUser.role != 'admin') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }
    
    final currentAdminUid = currentUser.uid;

    final filteredUsers = appState.allUsers.where((user) {
      if (_searchQuery.isEmpty) return true;
      final nameMatch = user.name.toLowerCase().contains(_searchQuery);
      final emailMatch = user.email.toLowerCase().contains(_searchQuery);
      return nameMatch || emailMatch;
    }).toList();

    final adminUsers =
    filteredUsers.where((user) => user.role == 'admin').toList();
    final facultyUsers =
    filteredUsers.where((user) => user.role == 'Faculty').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add New User',
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => const AddUserDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
              ),
            ),
          ),

          Expanded(
            child: (adminUsers.isEmpty && facultyUsers.isEmpty)
                ? const Center(
              child: Text(
                'No users found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                _buildSectionTitle(context, 'Admins'),
                if (adminUsers.isEmpty && _searchQuery.isNotEmpty)
                  _buildEmptySection('No admins match your search.')
                else if (adminUsers.isEmpty)
                  _buildEmptySection('No admins found.')
                else
                  ...adminUsers.map((user) =>
                  _buildUserCard(context, user, currentAdminUid))
                      ,
                _buildSectionTitle(context, 'Faculty'),
                if (facultyUsers.isEmpty && _searchQuery.isNotEmpty)
                  _buildEmptySection('No faculty match your search.')
                else if (facultyUsers.isEmpty)
                  _buildEmptySection('No faculty found.')
                else
                  ...facultyUsers.map((user) =>
                  _buildUserCard(context, user, currentAdminUid))
                      ,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, User user, String currentAdminUid) {
    final bool isSelf = user.uid == currentAdminUid;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
        ),
        title: Text(
          user.name + (isSelf ? ' (You)' : ''),
          style: TextStyle(
            fontWeight: isSelf ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(user.email),
        trailing: isSelf
            ? null
            : PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'reset_password':
                _sendPasswordReset(context, user);
                break;
              case 'delete_user':
                _showDeleteConfirmationDialog(context, user);
                break;
              case 'change_role':
                _showChangeRoleDialog(context, user);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reset_password',
              child: Text('Send Password Reset'),
            ),
            PopupMenuItem(
              value: 'change_role',
              child: Text(
                user.role == 'admin'
                    ? 'Demote to Faculty'
                    : 'Promote to Admin',
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete_user',
              child: Text(
                'Delete User',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptySection(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
    );
  }
}