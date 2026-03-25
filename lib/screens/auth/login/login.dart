import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/dashoard.dart';
import '../signup/signup.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        'https://system.zmx.co.zw/ZMX-API/Subscriber/authuser'
            '?idNumber=${Uri.encodeComponent(email)}'
            '&pass=${Uri.encodeComponent(password)}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = response.body.trim();

        // API returns plain "0" for wrong credentials (status is still 200)
        if (body == '0') {
          setState(() => _errorMessage = 'Invalid email or password. Please try again.');
          return;
        }

        // Parse the JSON array response
        final List<dynamic> data = jsonDecode(body);

        if (data.isEmpty) {
          setState(() => _errorMessage = 'No account found. Please try again.');
          return;
        }

        final user = data[0] as Map<String, dynamic>;

        // Save all user fields to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id',           user['id']?.toString() ?? '');
        await prefs.setString('user_brokerName',   user['brokerName']?.toString() ?? '');
        await prefs.setString('user_broker',       user['broker']?.toString() ?? '');
        await prefs.setString('user_cds',          user['cds']?.toString() ?? '');
        await prefs.setString('user_email',        user['email']?.toString() ?? '');
        await prefs.setString('user_name',         user['name']?.toString() ?? '');
        await prefs.setString('user_phone',        user['phone']?.toString() ?? '');
        await prefs.setString('user_pin',          user['pin']?.toString() ?? '');
        await prefs.setString('user_has_company',  user['has_company']?.toString() ?? '');
        await prefs.setString('user_account_type', user['account_type']?.toString() ?? '');
        await prefs.setBool('is_logged_in', true);

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Server error (${response.statusCode}). Please try again.';
        });
      }
    } on http.ClientException {
      setState(() => _errorMessage = 'Network error. Check your connection.');
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen background image
          Image.asset('assets/images/splash.png', fit: BoxFit.cover),

          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.55),
                  Colors.black.withOpacity(0.45),
                  Colors.black.withOpacity(0.55),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    height: 110,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 48),

                  // LOG IN title
                  const Text(
                    'LOG IN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Email field
                  _buildTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Password field
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.white70,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      child: const Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // LOGIN & SIGN UP buttons
                  Row(
                    children: [
                      // LOGIN button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4A017),
                            disabledBackgroundColor:
                            const Color(0xFFD4A017).withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Text(
                            'LOGIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // SIGN UP button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignUpScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2DB144),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                          ),
                          child: const Text(
                            'SIGN UP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFD4A017), width: 1.8),
        color: Colors.black.withOpacity(0.25),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
          TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}