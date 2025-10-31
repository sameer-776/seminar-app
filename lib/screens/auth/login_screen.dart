import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seminar_booking_app/providers/app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// We no longer need to import AuthService directly here

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _obscurePassword = true;

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _errorText = null;
      });
      final success = await context.read<AppState>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (!success && mounted) {
        setState(() {
          _errorText = 'Invalid email or password.';
          _emailController.clear();
          _passwordController.clear();
        });
      }
    }
  }

  // ✅ UPDATED GOOGLE SIGN-IN HANDLER
  Future<void> _handleGoogleSignIn() async {
    final appState = context.read<AppState>();
    if (appState.isLoading) return;

    setState(() {
      _errorText = null;
    });

    try {
      // Call the new method in AppState
      await appState.googleLogin();
      
      // On success, the _onAuthStateChanged listener in AppState
      // will handle navigation automatically.

    } on auth.FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          if (e.code == 'invalid-email-domain') {
            _errorText = 'Only @poornima.edu.in accounts are allowed.';
          } else if (e.code == 'account-exists-with-different-credential') {
             _errorText = 'An account already exists with this email.';
          } else {
             _errorText = 'Google Sign-In Error. Please try again.';
             print('Google Sign-In Error: ${e.message}');
          }
        });
      }
    } catch (e) {
       if (mounted) {
         setState(() {
           _errorText = 'An unexpected error occurred.';
           print('Unexpected Google Sign-In Error: $e');
         });
       }
    }
    // No 'finally' block needed, as AppState's login methods
    // now correctly set isLoading = false on success or error.
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    const adminEmail = '2024bcamafsmohit19405@poornima.edu.in'; // Replace as needed
    final subject = Uri.encodeComponent('Request for Password Reset');
    final body = Uri.encodeComponent(
        'Hello Admin,\n\nI am requesting a password reset for my account.\n\nRegistered Email: $email\n\nPlease send the password reset link to my registered email address.\n\nThank you.');

    final mailtoLink =
        Uri.parse('mailto:$adminEmail?subject=$subject&body=$body');
    if (await canLaunchUrl(mailtoLink)) {
      await launchUrl(mailtoLink);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open email client.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset('assets/logo.png', height: 100),
                        const SizedBox(height: 24),
                        Text('Welcome Back',
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                              labelText: 'Email', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? 'Required' : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: appState.isLoading ? null : _handleForgotPassword,
                              child: const Text("Forgot Password?")),
                        ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 8),
                          Text(_errorText!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: appState.isLoading ? null : _performLogin,
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: appState.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 3.0),
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 16),
                        
                        OutlinedButton.icon(
                          icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                          label: const Text('Sign in with Google'),
                          onPressed: appState.isLoading ? null : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                        ),
                        
                        // "Register" button is removed
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const Text('Developed by TECH ŚŪNYA',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}