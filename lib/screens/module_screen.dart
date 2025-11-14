import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;

import '../models/assessment_model.dart';
import '../models/module_game_model.dart';
import 'assessment_screen.dart';

// --- Design Constants ---
const Color primaryBlue = Color(0xFF007AFF);
const Color darkText = Color(0xFF1E1E1E);
const Color secondaryText = Color(0xFF6C6C6C);
const Color backgroundLight = Color(0xFFF7F7F7);
const Color cardColor = Colors.white;
const Color cardShadowColor = Color(0xFFE0E0E0);

// --- ANIMATION WRAPPER WIDGET ---
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
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), // Subtle slide up
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

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

class ModuleScreen extends StatefulWidget {
  final String moduleId;
  final String authToken;

  const ModuleScreen({
    Key? key,
    required this.moduleId,
    this.authToken = '165|Gs50Y9r5gS21xCyHCtA3yiyFXPdM1nFJY2Fq9B0y264ea167',
  }) : super(key: key);

  @override
  _ModuleScreenState createState() => _ModuleScreenState();
}

class _ModuleScreenState extends State<ModuleScreen> {
  late Future<Map<String, dynamic>> _moduleData;
  late Future<ModuleGame?> _moduleGame;
  bool _isReflectionComplete = false;

  @override
  void initState() {
    super.initState();
    _moduleData = _fetchModuleData();
    _moduleGame = _fetchModuleGame();
    _checkReflectionStatus();
  }

  // --- Data Fetching Methods (No Change) ---

  Future<Map<String, dynamic>> _fetchModuleData() async {
    final response = await http.get(
      Uri.parse('https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/${widget.moduleId}'),
      headers: {
        'Authorization': 'Bearer ${widget.authToken}',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load module data');
    }
  }

  Future<ModuleGame?> _fetchModuleGame() async {
    try {
      final response = await http.get(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/api/api/learner/module-games/${widget.moduleId}'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ModuleGame.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _checkReflectionStatus() async {
    try {
      final response = await http.get(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/api/api/learner/reflection-questions/did/77/${widget.moduleId}'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _isReflectionComplete = data['did_reflect'] ?? false;
          });
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  String _parseHtmlString(String htmlString) {
    final document = html_parser.parse(htmlString);
    return document.body?.text ?? '';
  }

  // --- REVISED ASSESSMENT CARD DESIGN ---
  Widget _buildAssessmentCard(Assessment assessment, int index) {
    final String type = assessment.type.toUpperCase();
    final Color typeColor = type == 'PRE' ? Colors.orange : (type == 'POST' ? primaryBlue : Colors.green);
    
    return AnimatedSection(
      delay: Duration(milliseconds: 300 + index * 100),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          leading: Icon(
            type == 'PRE' ? Icons.timer_outlined : (type == 'POST' ? Icons.check_circle_outline : Icons.quiz_outlined),
            color: typeColor,
          ),
          title: Text(
            assessment.title,
            style: const TextStyle(fontWeight: FontWeight.w600, color: darkText),
          ),
          subtitle: Text(
            'Assessment Type: $type',
            style: TextStyle(color: typeColor, fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16.0, color: secondaryText),
          onTap: () async {
            if (assessment.type == 'pre' || assessment.type == 'post' || assessment.type == 'quiz') {
              final shouldProceed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text('Start $type Assessment', style: const TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('This will start the assessment. Are you ready to begin?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('CANCEL', style: TextStyle(color: secondaryText)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('START'),
                    ),
                  ],
                ),
              ) ?? false;

              if (shouldProceed && mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AssessmentScreen(
                      authToken: widget.authToken,
                      moduleId: assessment.moduleId,
                      assessmentType: assessment.type,
                    ),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  // --- REVISED GAME CARD DESIGN ---
  Widget _buildGameCard(ModuleGame? game) {
    if (game == null) return const SizedBox.shrink();

    return AnimatedSection(
      delay: const Duration(milliseconds: 700),
      child: Container(
        margin: const EdgeInsets.all(20.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: primaryBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.videogame_asset_outlined, color: primaryBlue, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    game.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const Divider(color: primaryBlue, height: 25),
            Text(
              _parseHtmlString(game.details),
              style: const TextStyle(color: darkText, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 10.0),
            // Example Button to launch the game
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  // TODO: Implement game launch logic
                },
                icon: const Icon(Icons.play_circle_fill, color: primaryBlue),
                label: const Text(
                  'Launch Game',
                  style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
                ),
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
    ) ?? false;

    if (shouldSignOut && mounted) {
      // Clear any stored authentication data or state
      // For example, if using shared_preferences:
      // final prefs = await SharedPreferences.getInstance();
      // await prefs.remove('auth_token');
      
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
        backgroundColor: backgroundLight,
        elevation: 0,
        title: const Text(
          'Module Content',
          style: TextStyle(color: darkText, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: darkText),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _moduleData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryBlue));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No module data available'));
          }

          final moduleData = snapshot.data!;
          final assessments = (moduleData['assessments'] as List)
              .map((a) => Assessment.fromJson(a))
              .toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Module Header (Animated: 100ms) ---
                AnimatedSection(
                  delay: const Duration(milliseconds: 100),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Module ${moduleData['order']}: ${moduleData['name']}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 10.0),
                        Text(
                          moduleData['details'],
                          style: const TextStyle(fontSize: 16, color: secondaryText, height: 1.4),
                        ),
                        const SizedBox(height: 20.0),
                        if (!_isReflectionComplete)
                          ElevatedButton.icon(
                            onPressed: () {
                              // TODO: Implement navigate to Reflection Screen
                            },
                            icon: const Icon(Icons.rate_review, color: Colors.white),
                            label: const Text('Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        if (_isReflectionComplete)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Reflection Completed!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 40, thickness: 1, indent: 20, endIndent: 20, color: cardShadowColor),
                
                // --- Assessments Title (Animated: 200ms) ---
                AnimatedSection(
                  delay: const Duration(milliseconds: 200),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: Text(
                      'Module Assessments',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: darkText),
                    ),
                  ),
                ),
                
                // --- Assessment Cards (Staggered Animation) ---
                ...assessments.asMap().entries.map((entry) {
                  return _buildAssessmentCard(entry.value, entry.key);
                }).toList(),
                
                const SizedBox(height: 20.0),

                // --- Game Card (Animated: 700ms) ---
                FutureBuilder<ModuleGame?>(
                  future: _moduleGame,
                  builder: (context, gameSnapshot) {
                    if (gameSnapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink(); // Hide loader if assessments are loaded
                    }
                    return _buildGameCard(gameSnapshot.data);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}