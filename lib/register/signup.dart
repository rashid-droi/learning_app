import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Define the enhanced color palette
const Color primaryBlue = Color(0xFF007AFF);
const Color darkText = Color(0xFF1E1E1E);
const Color secondaryText = Color(0xFF6C6C6C);
const Color backgroundLight = Colors.white;
const Color inputBorderColor = Color(0xFFE0E0E0);

// --- ANIMATION WRAPPER WIDGET ---
// Custom Widget for managing animation sequence (Fade + Slide)
class AnimatedSection extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const AnimatedSection({super.key, required this.child, required this.delay});

  @override
  State<AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15), // Start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Start the animation after the specified delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
// --- END ANIMATION WRAPPER WIDGET ---

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreeenState createState() => _SignupScreeenState();
}

class _SignupScreeenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Define the gradient for the primary button
  final primaryGradient = const LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF00C0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/register'),
        body: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _successMessage = 'Registration successful! Redirecting to login...';
        });
        // Clear fields on success
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
          if (response.body.isNotEmpty) {
            try {
              final errorData = Map<String, dynamic>.from(json.decode(response.body));
              // Attempt to use a common Laravel error structure if available
              _errorMessage = errorData['message'] ?? errorData['error'] ?? 'Registration failed: ${response.statusCode}';
              
              // If validation errors are present (common in Laravel), list them
              if (errorData['errors'] != null) {
                final validationErrors = Map<String, dynamic>.from(errorData['errors']);
                String detailedError = validationErrors.values.map((e) => e[0]).join('\n');
                _errorMessage = 'Validation Errors:\n$detailedError';
              }
            } catch (e) {
              // If response is not JSON or doesn't contain expected format
              _errorMessage = 'Registration failed: ${response.statusCode}';
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please check your internet connection.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: darkText),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/landing');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- Header Text (Animated: 100ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 100),
                child: const Column(
                  children: [
                    Text(
                      'Get Started Free',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      textAlign: TextAlign.center,
                      'Create your profile and start tracking your progress today.',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- Full Name Input (Animated: 300ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 300),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  controller: _nameController,
                  style: const TextStyle(color: darkText),
                  decoration: _buildInputDecoration(
                    labelText: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // --- Email Input (Animated: 400ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 400),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  controller: _emailController,
                  style: const TextStyle(color: darkText),
                  decoration: _buildInputDecoration(
                    labelText: 'Email Address',
                    icon: Icons.email_outlined,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // --- Password Input (Animated: 500ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 500),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  controller: _passwordController,
                  style: const TextStyle(color: darkText),
                  decoration: _buildInputDecoration(
                    labelText: 'Password (min. 6 characters)',
                    icon: Icons.lock_outline,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // --- Confirm Password Input (Animated: 600ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 600),
                child: TextFormField(
                  textAlign: TextAlign.center,
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: darkText),
                  decoration: _buildInputDecoration(
                    labelText: 'Confirm Password',
                    icon: Icons.lock_open_outlined,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              ),

              // --- Error and Success Messages (Animated: 700ms) ---
              if (_errorMessage != null) 
                AnimatedSection(
                  delay: const Duration(milliseconds: 700),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500, fontSize: 14),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              if (_successMessage != null) 
                AnimatedSection(
                  delay: const Duration(milliseconds: 700),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500, fontSize: 14),
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // --- Sign Up Button (Gradient Primary, Animated: 800ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 800),
                child: Container(
                  width: 300,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: _isLoading ? null : primaryGradient, // Use gradient when not loading
                    color: _isLoading ? inputBorderColor : null, // Fallback color when disabled
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _isLoading ? null : [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _signup,
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Create Account',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- Login Prompt (Animated: 900ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 900),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: secondaryText, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                      child: const Text(
                        'Log in',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for clean input decoration
  InputDecoration _buildInputDecoration({
    required String labelText,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: secondaryText),
      prefixIcon: Icon(icon, color: secondaryText.withOpacity(0.7), size: 24),
      // We removed the input field's textAlign: TextAlign.center for better readability
      // of text field entries, but kept the main widget children centered.
      filled: true,
      fillColor: backgroundLight,
      contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
      // Clean border style
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: inputBorderColor, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: inputBorderColor, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryBlue, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
