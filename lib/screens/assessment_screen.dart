import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/assessment_model.dart';

// --- Design Constants ---
const Color primaryBlue = Color(0xFF007AFF);
const Color darkText = Color(0xFF1E1E1E);
const Color secondaryText = Color(0xFF6C6C6C);
const Color backgroundLight = Color(0xFFF7F7F7);
const Color cardColor = Colors.white;
const Color cardShadowColor = Color(0xFFE0E0E0);
const Color accentGreen = Color(0xFF2ECC71);
const Color accentRed = Color(0xFFE74C3C);

// --- ANIMATION WRAPPER WIDGET ---
// Reusable slide-fade for list items (questions)
class AnimatedQuestionCard extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const AnimatedQuestionCard({super.key, required this.child, required this.delay});

  @override
  State<AnimatedQuestionCard> createState() => _AnimatedQuestionCardState();
}

class _AnimatedQuestionCardState extends State<AnimatedQuestionCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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

// Custom widget for section transitions
class AnimatedSectionTransition extends StatelessWidget {
  final Widget child;
  final int index; // key to trigger transition

  const AnimatedSectionTransition({super.key, required this.child, required this.index});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        // Slide the new content in from the right/left depending on navigation direction
        final slideAnimation = Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Start off-screen right
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(index), // Key changes on section switch
        child: child,
      ),
    );
  }
}
// --- END ANIMATION WIDGETS ---


class AssessmentScreen extends StatefulWidget {
  final String authToken;
  final String moduleId;
  final String assessmentType; // 'pre', 'post', or 'quiz'

  const AssessmentScreen({
    Key? key,
    required this.authToken,
    required this.moduleId,
    this.assessmentType = 'post',
  }) : super(key: key);

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  late Future<Map<String, dynamic>> _assessmentData;
  final Map<int, int?> _selectedAnswers = {};

  int _currentSectionIndex = 0;
  bool _isSubmitting = false;
  bool _hasPreviousAnswers = false;

  final primaryGradient = const LinearGradient(
    colors: [primaryBlue, Color(0xFF00C0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _assessmentData = _fetchAssessmentData();
  }

  // ---------------- Fetch Assessment / Quiz (No Change) ----------------
  Future<Map<String, dynamic>> _fetchAssessmentData() async {
    try {
      final assessmentUrl =
          'https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/${widget.moduleId}/${widget.assessmentType}';
      final answersUrl = widget.assessmentType == 'quiz'
          ? 'https://teambuilding-selecttraining.com/progressfile/api/api/learner/quiz-assessment-answers'
          : 'https://teambuilding-selecttraining.com/progressfile/api/api/learner/pre-assessment-answers';

      final assessmentResponse = await http.get(
        Uri.parse(assessmentUrl),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Accept': 'application/json',
        },
      );

      if (assessmentResponse.statusCode != 200) {
        throw Exception('Failed to load assessment');
      }

      final answersResponse = await http.post(
        Uri.parse(answersUrl),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'module_id': widget.moduleId,
          'learner_id': 78, 
        }),
      );

      final assessmentData = jsonDecode(assessmentResponse.body);
      final answersData = jsonDecode(answersResponse.body);

      _parsePreviousAnswers(answersData);

      return {
        'assessment': Assessment.fromJson(assessmentData),
        'previousAnswers': answersData,
      };
    } catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  // ---------------- Parse Previous Answers (No Change) ----------------
  void _parsePreviousAnswers(Map<String, dynamic> answersData) {
    if (answersData['sections'] == null) return;

    final sections = answersData['sections'];
    if (sections.isEmpty) return;

    _hasPreviousAnswers = true;
    for (final section in sections) {
      for (final mcq in section['mcqs'] ?? []) {
        final selectedId = mcq['selected_option_id'];
        if (selectedId != null) _selectedAnswers[mcq['id']] = selectedId;
      }
    }
  }

  // ---------------- Submit Assessment (No Change) ----------------
  Future<void> _submitAssessment() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final assessment = (await _assessmentData)['assessment'] as Assessment;

      int correctAnswers = 0;
      int totalQuestions = 0;

      for (final section in assessment.sections) {
        for (final mcq in section.mcqs) {
          totalQuestions++;
          final selectedId = _selectedAnswers[mcq.id];
          if (selectedId != null) {
            final option = mcq.options.firstWhere(
              (o) => o.id == selectedId,
              orElse: () => throw Exception('Option not found'),
            );
            if (option.isCorrect) correctAnswers++;
          }
        }
      }

      final score = (correctAnswers / totalQuestions * 100).toInt();

      final submitUrl =
          'https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/submit';

      final submitResponse = await http.post(
        Uri.parse(submitUrl),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'module_id': widget.moduleId,
          'type': widget.assessmentType,
          'score': score,
          'answers': _selectedAnswers.entries
              .map((e) => {
                    'question_id': e.key,
                    'selected_option_id': e.value,
                  })
              .toList(),
        }),
      );
      
      // Check if submission was successful (assuming 200 or 201 is success)
      if (submitResponse.statusCode != 200 && submitResponse.statusCode != 201) {
        throw Exception('Server rejected submission: ${submitResponse.statusCode}');
      }


      if (mounted) {
        Navigator.of(context).pop(); // Pop the AssessmentScreen
        _showResultDialog(score);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit assessment: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ---------------- UI Helpers ----------------
  void _showResultDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.star_border, color: primaryBlue, size: 30),
            const SizedBox(width: 10),
            const Text('Assessment Complete', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'You scored **$score%** on your ${widget.assessmentType.toUpperCase()} assessment.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('FINISH', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(MCQ mcq, int index) => AnimatedQuestionCard(
        delay: Duration(milliseconds: index * 50), // Subtle stagger per question
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(fontSize: 14, color: secondaryText, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  mcq.question,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: darkText),
                ),
                const SizedBox(height: 16),
                ...mcq.options.map(
                  (option) => RadioListTile<int>(
                    dense: true,
                    title: Text(option.optionText, style: const TextStyle(fontSize: 15, color: darkText)),
                    value: option.id,
                    groupValue: _selectedAnswers[mcq.id],
                    activeColor: primaryBlue,
                    onChanged: (value) =>
                        setState(() => _selectedAnswers[mcq.id] = value),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: primaryBlue),
            const SizedBox(height: 16),
            Text('Loading ${widget.assessmentType.toUpperCase()} assessment...', style: const TextStyle(color: darkText)),
          ],
        ),
      );

  Widget _buildError(String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sentiment_dissatisfied_outlined, color: accentRed, size: 48),
              const SizedBox(height: 16),
              const Text('An error occurred.', style: TextStyle(color: darkText, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(error.contains('Failed to load assessment') ? 'The requested assessment could not be loaded.' : error,
                  textAlign: TextAlign.center, style: const TextStyle(color: secondaryText)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _assessmentData = _fetchAssessmentData()),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Retry Loading', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
              ),
            ],
          ),
        ),
      );

  Widget _buildPreviousAnswersBanner() {
    if (!_hasPreviousAnswers) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      color: primaryBlue.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(Icons.history, color: primaryBlue),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Previous answers have been loaded.',
                style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => setState(() {
              _selectedAnswers.clear();
              _hasPreviousAnswers = false;
            }),
            child: const Text('Clear', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isLast, bool allAnswered) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(top: BorderSide(color: cardShadowColor, width: 1)),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor.withOpacity(0.5),
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            ElevatedButton.icon(
              onPressed: _currentSectionIndex > 0
                  ? () => setState(() => _currentSectionIndex--)
                  : null,
              icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: darkText),
              label: const Text('Previous', style: TextStyle(color: darkText)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: secondaryText, width: 1),
                ),
              ),
            ),
            
            // Next / Submit Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: allAnswered ? primaryGradient : null,
                  color: allAnswered ? null : secondaryText.withOpacity(0.3),
                ),
                child: ElevatedButton.icon(
                  onPressed: allAnswered && !_isSubmitting
                      ? isLast
                          ? _submitAssessment
                          : () => setState(() => _currentSectionIndex++)
                      : null,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(isLast ? Icons.send : Icons.arrow_forward_ios, size: 16, color: Colors.white),
                  label: Text(
                    _isSubmitting
                        ? 'Submitting...'
                        : isLast
                            ? 'Submit Assessment'
                            : 'Next Section',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 1,
        title: Text(
          '${widget.assessmentType.toUpperCase()} Assessment',
          style: const TextStyle(color: darkText, fontWeight: FontWeight.w800),
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _assessmentData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          } else if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          } else if (!snapshot.hasData) {
            return _buildError('No assessment data available');
          }

          final assessment = snapshot.data!['assessment'] as Assessment;
          final currentSection = assessment.sections[_currentSectionIndex];
          final isLast = _currentSectionIndex == assessment.sections.length - 1;
          final allAnswered = currentSection.mcqs.every((mcq) => _selectedAnswers.containsKey(mcq.id));

          return Column(
            children: [
              _buildPreviousAnswersBanner(),
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentSectionIndex + 1) / assessment.sections.length,
                minHeight: 6,
                backgroundColor: cardShadowColor,
                valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
              ),
              // Section Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Section ${_currentSectionIndex + 1} of ${assessment.sections.length}',
                      style: const TextStyle(fontSize: 16, color: primaryBlue, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentSection.title,
                      style: const TextStyle(fontSize: 22, color: darkText, fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Animated Section Content
              Expanded(
                child: AnimatedSectionTransition(
                  index: _currentSectionIndex,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: currentSection.mcqs.length,
                    itemBuilder: (context, i) => _buildQuestionCard(currentSection.mcqs[i], i),
                  ),
                ),
              ),
              // Navigation Bar
              _buildNavigationButtons(isLast, allAnswered),
            ],
          );
        },
      ),
    );
  }
}
