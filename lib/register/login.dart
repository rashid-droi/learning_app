import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Define the enhanced color palette
const Color primaryBlue = Color(0xFF007AFF);
const Color darkText = Color(0xFF1E1E1E);
const Color secondaryText = Color(0xFF6C6C6C);
const Color backgroundLight = Colors.white;
const Color inputBorderColor = Color(0xFFE0E0E0);

// Custom Widget for managing animation sequence
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Define the gradient for the primary button
  final primaryGradient = const LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF00C0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/login'),
        body: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        // Handle successful login
        if (mounted) {
          // Assuming '/courses' is your home route
          Navigator.pushReplacementNamed(context, '/courses');
        }
      } else {
        // Handle error (assuming backend sends a specific error message)
        setState(() {
          _errorMessage = 'Login failed. Please check your credentials.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please check your internet.';
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
    _emailController.dispose();
    _passwordController.dispose();
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
            // Using pushReplacementNamed to go back to landing screen
            Navigator.pushReplacementNamed(context, '/landing');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // --- Header Text (Animated: 100ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 100),
                child: const Column(
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      textAlign: TextAlign.center,
                      'Enter your details to continue your learning journey.',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // --- Email Input (Animated: 300ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 300),
                child: TextFormField(
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

              // --- Password Input (Animated: 400ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 400),
                child: TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: darkText),
                  decoration: _buildInputDecoration(
                    labelText: 'Password',
                    icon: Icons.lock_outline,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
              ),

              // --- Error Message (Animated: 500ms) ---
              if (_errorMessage != null) 
                AnimatedSection(
                  delay: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // --- Login Button (Animated: 600ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 600),
                child: Container(
                  width: 250,
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
                      onTap: _isLoading ? null : _login,
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
                                'Login',
                                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),

              // --- Forgot Password Link (Animated: 700ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 700),
                child: Center(
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password functionality
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Sign Up Prompt (Animated: 800ms) ---
              AnimatedSection(
                delay: const Duration(milliseconds: 800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Don\'t have an account?',
                      style: TextStyle(color: secondaryText, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        'Sign up',
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
