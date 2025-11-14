import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'module_screen.dart';
import '../models/assessment_model.dart'; // Ensure this path is correct

// --- Design Constants ---
const Color primaryBlue = Color(0xFF007AFF);
const Color darkText = Color(0xFF1E1E1E);
const Color secondaryText = Color(0xFF6C6C6C);
const Color backgroundLight = Color(0xFFF0F2F5); // Lighter, modern background
const Color cardColor = Colors.white;
const Color dividerColor = Color(0xFFDDDDDD);
const Color accentRed = Color(0xFFE74C3C);

// --- Module Model (No Change) ---
class Module {
  final int id;
  final String courseId;
  final String order;
  final String name;
  final String details;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final List<Assessment> assessments;

  Module({
    required this.id,
    required this.courseId,
    required this.order,
    required this.name,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.assessments = const [],
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    return Module(
      id: json['id'] ?? 0,
      courseId: json['course_id']?.toString() ?? '',
      order: json['order']?.toString() ?? 'N/A',
      name: json['name'] ?? 'Untitled Module',
      details: json['details'] ?? 'No details available.',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      assessments: json['assessments'] != null 
          ? (json['assessments'] as List).map((a) => Assessment.fromJson(a)).toList()
          : [],
    );
  }
}

// --- ANIMATION WRAPPER WIDGET (Slightly refined for smoother entrance) ---
class AnimatedModuleCard extends StatefulWidget {
  final Widget child;
  final int index;
  const AnimatedModuleCard({super.key, required this.child, required this.index});

  @override
  State<AnimatedModuleCard> createState() => _AnimatedModuleCardState();
}

class _AnimatedModuleCardState extends State<AnimatedModuleCard> with SingleTickerProviderStateMixin {
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
      begin: const Offset(0.0, 0.1), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate, // Smoother deceleration curve
    ));

    Future.delayed(Duration(milliseconds: 150 + widget.index * 120), () {
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

class ModulesScreen extends StatefulWidget {
  final String courseId;
  
  const ModulesScreen({super.key, required this.courseId});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  late Future<List<Module>> _modulesFuture;
  late String _baseUrl;
  final String _token = '165|Gs50Y9r5gS21xCyHCtA3yiyFXPdM1nFJY2Fq9B0y264ea167';

  @override
  void initState() {
    super.initState();
    _baseUrl = 'https://teambuilding-selecttraining.com/progressfile/api/api/learner/courses/${widget.courseId}/modules';
    _modulesFuture = _fetchModules(); 
  }

  Future<List<Module>> _fetchModules() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Module.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load modules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching modules: $e');
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // --- REVISED MODULE CARD DESIGN ---
  Widget _buildModuleCard(BuildContext context, Module module, bool isLast) {
    final int assessmentCount = module.assessments.length;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline/Order Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                // Order Number Circle
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: primaryBlue.withOpacity(0.5), blurRadius: 8),
                    ]
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    module.order,
                    style: const TextStyle(
                      color: cardColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Vertical Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: dividerColor,
                    ),
                  ),
              ],
            ),
          ),
          
          // Module Card Content
          Expanded(
            child: AnimatedModuleCard(
              index: int.tryParse(module.order) ?? 0,
              child: Container(
                margin: EdgeInsets.only(right: 20, top: 10, bottom: isLast ? 10 : 25),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: dividerColor, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ModuleScreen(moduleId: module.id.toString()),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Module Name (Title)
                        Text(
                          module.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: darkText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
        
                        // Details
                        Text(
                          module.details,
                          style: const TextStyle(
                            fontSize: 14,
                            color: secondaryText,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
        
                        // Footer Meta Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Assessments Count
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.assignment_turned_in_outlined, size: 16, color: primaryBlue),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$assessmentCount Assessments',
                                    style: const TextStyle(
                                      color: primaryBlue,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Creation Date
                            Text(
                              'Added ${_formatDate(module.createdAt)}',
                              style: const TextStyle(
                                color: secondaryText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
    ) ?? false;

    if (shouldSignOut && mounted) {
      // Navigate back to login screen and remove all previous routes
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
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
        backgroundColor: cardColor,
        elevation: 0,
        title: const Text(
          'Course Modules',
          style: TextStyle(
            color: darkText,
            fontWeight: FontWeight.w900,
            fontSize: 26,
          ),
        ),
        iconTheme: const IconThemeData(color: darkText),
        actions: [
          // Small logout button
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
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
      body: FutureBuilder<List<Module>>(
        future: _modulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          } 
          
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sentiment_dissatisfied_outlined, color: accentRed, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load modules.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _modulesFuture = _fetchModules()),
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text('Try Again', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                    ),
                  ],
                ),
              ),
            );
          }
          
          final modules = snapshot.data ?? [];
          if (modules.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers_clear_outlined, size: 60, color: secondaryText),
                  SizedBox(height: 16),
                  Text('No modules available for this course.', 
                        style: TextStyle(fontSize: 18, color: secondaryText)),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.only(top: 20),
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              final isLast = index == modules.length - 1;
              
              // Each module card is built within the Row containing the timeline indicator
              return _buildModuleCard(context, module, isLast);
            },
          );
        },
      ),
    );
  }
}
