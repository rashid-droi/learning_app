import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/assessment_model.dart';

class AssessmentScreen extends StatefulWidget {
  final String authToken;
  final String moduleId;
  final String assessmentType;

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

  @override
  void initState() {
    super.initState();
    // Use _fetchQuizData for quiz type, otherwise use _fetchAssessmentData
    _assessmentData = widget.assessmentType == 'quiz' 
        ? _fetchQuizData() 
        : _fetchAssessmentData();
  }

  Future<Map<String, dynamic>> _fetchAssessmentData() async {
    try {
      // Fetch assessment questions
      final assessmentResponse = await http.get(
        Uri.parse(
          'https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/${widget.moduleId}/${widget.assessmentType}',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Accept': 'application/json',
        },
      );

      if (assessmentResponse.statusCode != 200) {
        throw Exception('Failed to load assessment');
      }

      // Fetch previous answers if any
      final answersResponse = await http.post(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/api/api/learner/pre-assessment-answers'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'module_id': widget.moduleId.toString(),
          'learner_id': 78, // You might want to get this from user data
        }),
      );

      final assessmentData = jsonDecode(assessmentResponse.body);
      final answersData = jsonDecode(answersResponse.body);
      
      // Parse previous answers if they exist
      if (answersData['sections'] != null && answersData['sections'].isNotEmpty) {
        _hasPreviousAnswers = true;
        for (final section in answersData['sections']) {
          if (section['mcqs'] != null) {
            for (final mcq in section['mcqs']) {
              if (mcq['selected_option_id'] != null) {
                _selectedAnswers[mcq['id']] = mcq['selected_option_id'];
              }
            }
          }
        }
      }

      return {
        'assessment': Assessment.fromJson(assessmentData),
        'previousAnswers': answersData,
      };
    } catch (e) {
      throw Exception('Failed to load assessment data: $e');
    }
  }

  Future<void> _submitAssessment() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Calculate score
      int correctAnswers = 0;
      int totalQuestions = 0;
      final assessment = (await _assessmentData)['assessment'] as Assessment;

      for (final section in assessment.sections) {
        for (final mcq in section.mcqs) {
          totalQuestions++;
          final selectedOptionId = _selectedAnswers[mcq.id];
          if (selectedOptionId != null) {
            final selectedOption = mcq.options.firstWhere(
              (option) => option.id == selectedOptionId,
              orElse: () => throw Exception('Option not found'),
            );
            if (selectedOption.isCorrect) {
              correctAnswers++;
            }
          }
        }
      }

      final score = (correctAnswers / totalQuestions * 100).toInt();

      // Submit the score to the API
      final response = await http.post(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/submit'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'module_id': widget.moduleId,
          'type': widget.assessmentType,
          'score': score,
          'answers': _selectedAnswers.entries.map((e) => {
                'question_id': e.key,
                'selected_option_id': e.value,
              }).toList(),
        }),
      );

      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Assessment Submitted'),
            content: Text(
              'You scored $score% on your ${widget.assessmentType.toUpperCase()} assessment.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit assessment')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchQuizData() async {
    try {
      // Fetch quiz questions
      final assessmentResponse = await http.get(
        Uri.parse(
          'https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/${widget.moduleId}/${widget.assessmentType}',
        ),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Accept': 'application/json',
        },
      );

      if (assessmentResponse.statusCode != 200) {
        throw Exception('Failed to load assessment');
      }

      // Fetch previous answers if any
      final answersResponse = await http.post(
        Uri.parse('https://teambuilding-selecttraining.com/progressfile/api/api/learner/quiz-assessment-answers'),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'module_id': widget.moduleId.toString(),
          'learner_id': 78, // You might want to get this from user data
        }),
      );

      final assessmentData = jsonDecode(assessmentResponse.body);
      final answersData = jsonDecode(answersResponse.body);
      
      // Parse previous answers if they exist
      if (answersData['sections'] != null && answersData['sections'].isNotEmpty) {
        _hasPreviousAnswers = true;
        for (final section in answersData['sections']) {
          if (section['mcqs'] != null) {
            for (final mcq in section['mcqs']) {
              if (mcq['selected_option_id'] != null) {
                _selectedAnswers[mcq['id']] = mcq['selected_option_id'];
              }
            }
          }
        }
      }

      return {
        'assessment': Assessment.fromJson(assessmentData),
        'previousAnswers': answersData,
      };
    } catch (e) {
      throw Exception('Failed to load assessment data: $e');
    }
  }


  Widget _buildQuestionCard(MCQ mcq) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mcq.question,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            ...mcq.options.map((option) {
              return RadioListTile<int>(
                title: Text(option.optionText),
                value: option.id,
                groupValue: _selectedAnswers[mcq.id],
                onChanged: (value) {
                  setState(() {
                    _selectedAnswers[mcq.id] = value;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16.0),
          Text('Loading assessment...'),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48.0),
          const SizedBox(height: 16.0),
          Text('Error: $error'),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _assessmentData = _fetchAssessmentData();
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousAnswersBanner() {
    if (!_hasPreviousAnswers) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 8.0),
          const Text('Previous answers loaded', style: TextStyle(color: Colors.blue)),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedAnswers.clear();
                _hasPreviousAnswers = false;
              });
            },
            child: const Text('Clear answers'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.assessmentType.toUpperCase()} Assessment'),
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
          final isLastSection = _currentSectionIndex == assessment.sections.length - 1;
          final allQuestionsAnswered = currentSection.mcqs.every((mcq) => _selectedAnswers.containsKey(mcq.id));

          return Column(
            children: [
              _buildPreviousAnswersBanner(),
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentSectionIndex + 1) / assessment.sections.length,
                minHeight: 4.0,
              ),
              
              // Section title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Section ${_currentSectionIndex + 1} of ${assessment.sections.length}: ${currentSection.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              
              // Questions list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  itemCount: currentSection.mcqs.length,
                  itemBuilder: (context, index) {
                    return _buildQuestionCard(currentSection.mcqs[index]);
                  },
                ),
              ),
              
              // Navigation buttons
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous button
                    if (_currentSectionIndex > 0)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentSectionIndex--;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, size: 16.0),
                        label: const Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                        ),
                      )
                    else
                      const SizedBox(),
                    
                    // Next/Submit button
                    ElevatedButton.icon(
                      onPressed: !allQuestionsAnswered
                          ? null
                          : _isSubmitting
                              ? null
                              : isLastSection
                                  ? _submitAssessment
                                  : () {
                                      setState(() {
                                        _currentSectionIndex++;
                                      });
                                    },
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              isLastSection ? Icons.check : Icons.arrow_forward,
                              size: 16.0,
                            ),
                      label: Text(
                        _isSubmitting
                            ? 'Submitting...'
                            : isLastSection
                                ? 'Submit Assessment'
                                : 'Next Section',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
