import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learning_app/screens/modules.dart'; 

// --- Design Constants ---
const Color primaryBlue = Color(0xFF007AFF);
const Color darkText = Color(0xFF1E1E1E);
const Color secondaryText = Color(0xFF6C6C6C);
const Color backgroundLight = Color(0xFFF7F7F7); // Slightly off-white background
const Color cardShadowColor = Color(0xFFE0E0E0);


// --- Course Model (No Change) ---
class Course {
  final int id;
  final String name;
  final String details;
  final String startDate;
  final String clientName;

  Course({
    required this.id,
    required this.name,
    required this.details,
    required this.startDate,
    required this.clientName,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Untitled Course',
      details: json['details'] ?? 'No details provided.',
      startDate: json['start_date'] ?? 'N/A',
      clientName: json['client_name'] ?? 'Client',
    );
  }
}

// --- ANIMATION WRAPPER WIDGET ---
class AnimatedCourseCard extends StatefulWidget {
  final Widget child;
  final int index; // Used to calculate stagger delay
  const AnimatedCourseCard({super.key, required this.child, required this.index});

  @override
  State<AnimatedCourseCard> createState() => _AnimatedCourseCardState();
}

class _AnimatedCourseCardState extends State<AnimatedCourseCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Stagger the animation: index * 100ms delay
    Future.delayed(Duration(milliseconds: 100 + widget.index * 100), () {
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

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  _CoursesScreenState createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  // NOTE: Token usage is for demonstration.
  final String _token = '165|Gs50Y9r5gS21xCyHCtA3yiyFXPdM1nFJY2Fq9B0y264ea167';
  List<Course> _courses = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/api/api/learner/courses'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _courses = data.map((json) => Course.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load courses. Status code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching courses. Check connection or token: $e';
        _isLoading = false;
      });
    }
  }

  // Helper function to get a color based on course ID for visual distinction
  Color _getCourseColor(int id, {bool isLight = false}) {
    final colors = [

      primaryBlue, 

    ];
    Color baseColor = colors[id % colors.length];
    return isLight ? baseColor.withOpacity(0.1) : baseColor;
  }

  // --- REVISED COURSE CARD DESIGN ---
  Widget _buildCard(BuildContext context, Course course) {
    final Color accentColor = _getCourseColor(course.id);
    final Color lightBgColor = _getCourseColor(course.id, isLight: true);
    final String formattedDate = course.startDate.split(' ')[0];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1.5), // Subtle border accent
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2), // Color-matched shadow for depth
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => ModulesScreen(courseId: course.id.toString())
            )
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Section: Title & Details ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Name / Status Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: lightBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      course.clientName.toUpperCase(),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Course Name (Main Title)
                  Text(
                    course.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: darkText,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Course Details (Description)
                  Text(
                    course.details,
                    style: const TextStyle(
                      fontSize: 15, 
                      color: secondaryText, 
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // --- Footer Section: Progress & Date ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: backgroundLight, // Keep background light for contrast
                border: Border(top: BorderSide(color: cardShadowColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Start Date
                  Row(
                    children: [
                      Icon(Icons.schedule_outlined, size: 18, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'Start Date: $formattedDate',
                        style: const TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  // Simple Progress Indicator (Placeholder)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'View Modules',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: secondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/landing',
          (route) => false, 
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight,
        elevation: 0,
        title: const Text(
          'My Courses',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.w900,
            fontSize: 28,
          ),
        ),
        centerTitle: false,
        actions: [
          // Small logout button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)!),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 20, color: Colors.red),
              onPressed: _signOut,
              tooltip: 'Sign Out',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryBlue))
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
              : _courses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.school_outlined, size: 60, color: secondaryText),
                          const SizedBox(height: 16),
                          const Text('No courses available yet.', 
                                style: TextStyle(fontSize: 18, color: secondaryText)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _fetchCourses,
                            child: const Text('Try Reloading', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        return AnimatedCourseCard(
                          index: index,
                          child: _buildCard(context, course),
                        );
                      },
                    ),
    );
  }
}
