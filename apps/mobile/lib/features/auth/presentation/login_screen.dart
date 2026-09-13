import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/supabase_constants.dart';

class LoginScreen extends StatefulWidget {
  final Function(String role, {bool isSignUp}) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  String _selectedRole = 'customer'; // 'customer' or 'chef'
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  void _submitAuth() async {
    if (SupabaseConstants.supabaseUrl.contains('YOUR_SUPABASE_PROJECT_ID') ||
        SupabaseConstants.supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY')) {
      _showOfflineDialog();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final supabaseService = SupabaseService();

    try {
      if (_isSignUp) {
        await supabaseService.signUp(
          email: email,
          password: password,
          fullName: fullName,
          role: _selectedRole,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: AppColors.accentEmerald,
            ),
          );
        }
      } else {
        await supabaseService.signIn(
          email: email,
          password: password,
        );
      }

      String userRole = _selectedRole;
      try {
        final profile = await supabaseService.getProfile(supabaseService.currentUser?.id ?? '');
        if (profile != null && profile['role'] != null) {
          userRole = profile['role'];
        }
      } catch (_) {}

      if (mounted) {
        widget.onLoginSuccess(userRole, isSignUp: _isSignUp);
      }
    } on AuthException catch (e) {
      if (mounted) {
        final msg = e.message.toLowerCase();
        if (msg.contains('socket') || msg.contains('host lookup') || msg.contains('clientexception') || msg.contains('network')) {
          _showOfflineDialog();
          setState(() {
            _isLoading = false;
          });
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('socket') || msg.contains('host lookup') || msg.contains('clientexception') || msg.contains('network')) {
          _showOfflineDialog();
          setState(() {
            _isLoading = false;
          });
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showOfflineDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Offline Demo Mode',
          style: GoogleFonts.libreCaslonText(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Could not connect to Supabase. Would you like to enter Demo Mode directly?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.onLoginSuccess(_selectedRole, isSignUp: _isSignUp);
            },
            child: const Text('Enter Demo Mode'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand Title
                Center(
                  child: Column(
                    children: [
                      Text(
                        'GastroHost',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1C1C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in or create an account',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          color: const Color(0xFF747878),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Customer / Chef Role Tabs
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'customer'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedRole == 'customer'
                                    ? const Color(0xFF7B5800)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Customer',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: _selectedRole == 'customer' ? FontWeight.bold : FontWeight.normal,
                                color: _selectedRole == 'customer' ? const Color(0xFF1B1C1C) : const Color(0xFF747878),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = 'chef'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedRole == 'chef'
                                    ? const Color(0xFF7B5800)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Chef',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: _selectedRole == 'chef' ? FontWeight.bold : FontWeight.normal,
                                color: _selectedRole == 'chef' ? const Color(0xFF1B1C1C) : const Color(0xFF747878),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Card Container
                Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE4E2E2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSignUp) ...[
                            Text(
                              'FULL NAME',
                              style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF747878),
                              ),
                            ),
                            TextFormField(
                              controller: _fullNameController,
                              style: GoogleFonts.manrope(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'Enter your full name',
                                border: UnderlineInputBorder(),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Please enter full name' : null,
                            ),
                            const SizedBox(height: 20),
                          ],

                          Text(
                            'EMAIL OR PHONE NUMBER',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF747878),
                            ),
                          ),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.manrope(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'name@example.com',
                              border: UnderlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Please enter email' : null,
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'PASSWORD',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF747878),
                            ),
                          ),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: GoogleFonts.manrope(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: '••••••••',
                              border: UnderlineInputBorder(),
                            ),
                            validator: (v) => v == null || v.length < 6 ? 'Password must be 6+ chars' : null,
                          ),
                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Account' : 'Continue',
                                      style: GoogleFonts.manrope(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle Sign Up / Sign In
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => _isSignUp = !_isSignUp),
                              child: Text(
                                _isSignUp
                                    ? 'Already have an account? Sign In'
                                    : "Don't have an account? Sign Up",
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  color: const Color(0xFF7B5800),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Instant Demo Mode Bypass Button
                          Center(
                            child: TextButton(
                              onPressed: () => widget.onLoginSuccess(_selectedRole),
                              child: Text(
                                'Direct Offline Demo Access →',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  color: const Color(0xFF747878),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
