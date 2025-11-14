import 'package:flutter/material.dart';
import 'package:learning_app/register/login.dart';
import 'package:learning_app/register/signup.dart';


// Define the enhanced color palette
const Color primaryBlue = Color(0xFF007AFF); // A vibrant, common blue (iOS/Web look)
const Color darkText = Color(0xFF1E1E1E);
const Color secondaryText = Color(0xFF6C6C6C);
const Color backgroundLight = Colors.white;

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
      begin: const Offset(0, 0.2), // Start slightly below
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

// Convert LandingScreen to a StatefulWidget to manage state and animations
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  // Define the gradient for the primary button/hero section
  final primaryGradient = const LinearGradient(
    colors: [Color(0xFF007AFF), Color(0xFF00C0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: const Text("ProgressFile"),
        backgroundColor: backgroundLight, // Transparent/White AppBar
        elevation: 0, 
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: darkText,
        ),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 0.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- Section 1: Hero Text (Animated) ---
            AnimatedSection(
              delay: const Duration(milliseconds: 100),
              child: Container(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: const Column(
                  children: [
                    Text(
                      "Transform Your Learning Journey",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: darkText,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Track your progress, complete modules, and showcase your learning journey with our intuitive platform.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- Section 2: CTA Buttons (Animated) ---
            AnimatedSection(
              delay: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  // Primary Button with Gradient
                  Container(
                    width: 250,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Text(
                            "Start Now",
                            style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Secondary Button (Login)
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(250, 58), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Color(0xFFE0E0E0), width: 1), 
                      backgroundColor: backgroundLight,
                      elevation: 2,
                      ),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 16, color: primaryBlue, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 50),

            // --- Section 3: Stats Grid (Animated) ---
            AnimatedSection(
              delay: const Duration(milliseconds: 500),
              child: Column(
                children: [
                  const Text(
                    "Trusted By Thousands",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, 
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.1, 
                    padding: EdgeInsets.zero,
                    children: [
                        _StatCard(
                            icon: Icons.school_outlined, value: "1000+", label: "Active Students", accentColor: primaryBlue),
                        _StatCard(
                            icon: Icons.library_books_outlined,
                            value: "50+",
                            label: "Curated Courses", accentColor: Colors.orange),
                        _StatCard(
                            icon: Icons.verified_outlined,
                            value: "99%",
                            label: "Completion Rate", accentColor: Colors.green),
                        _StatCard(
                          icon: Icons.star_rate_outlined, value: "4.9", label: "Avg. Rating", accentColor: Colors.purple),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // --- Section 4: Features (Animated) ---
            AnimatedSection(
              delay: const Duration(milliseconds: 700),
              child: Column(
                children: const [
                  Text(
                    "Why Choose ProgressFile?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  SizedBox(height: 20),
                   _FeatureCard(
                      title: "Comprehensive Learning",
                      description:
                        "Access a wide range of courses designed by industry experts to enhance your skills and knowledge.",
                        icon: Icons.menu_book,
                   ),
                   _FeatureCard(
                      title: "Track Your Progress",
                      description:
                        "Monitor your learning journey with detailed progress tracking and personalized insights.",
                        icon: Icons.analytics_outlined,
                   ),
                   _FeatureCard(
                      title: "Earn Certifications",
                      description:
                        "Get recognized for your achievements with verifiable certificates upon course completion.",
                        icon: Icons.workspace_premium,
                   ),
                   _FeatureCard(
                      title: "Join a Community",
                      description:
                        "Connect with fellow learners, share insights, and grow together in a supportive environment.",
                        icon: Icons.people_alt,
                   ),
                ],
              ),
            ),
            const SizedBox(height: 60),
            
            /// --- Section 5: How It Works (Animated) ---
            AnimatedSection(
              delay: const Duration(milliseconds: 900),
              child: Column(
                children: const [
                  Text(
                    "Getting Started is Easy",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkText),
                  ),
                  SizedBox(height: 20),
                  _StepCard(step: "1", text: "Select a Learning Path"),
                  _StepCard(step: "2", text: "Complete Modules & Quizzes"),
                  _StepCard(step: "3", text: "Download Your Certified Portfolio"),
                ],
              ),
            ),

            /// Footer
            const Divider(height: 60, thickness: 1, color: Color(0xFFE0E0E0)),
            const Text(
              "© 2025 ProgressFile. Learning made visible.",
              style: TextStyle(color: secondaryText, fontSize: 14),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}


/// Stat cards (Ultra-Modern - No Changes)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accentColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1), // Light border
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        
        padding: const EdgeInsets.all(20.0),
        child: Column(
          
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 36),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: darkText),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: secondaryText, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

/// Feature cards (Clean, Separated - No Changes)
class _FeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _FeatureCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 50), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)
            ),
            child: Icon(icon, color: primaryBlue, size: 24), 
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
                const SizedBox(height: 8),
                Text(description, style: const TextStyle(color: secondaryText, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }  
}

/// Step cards (Streamlined - No Changes)
class _StepCard extends StatelessWidget{
  final String step;
  final String text;

  const _StepCard({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(step, style: const TextStyle(color: primaryBlue, fontWeight: FontWeight.w800, fontSize: 18)),
        ),
      ),
      title: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText)),
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    );
  }
}
