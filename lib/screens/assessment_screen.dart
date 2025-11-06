import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/assessment_model.dart';

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

  @override
  void initState() {
    super.initState();
    _assessmentData = _fetchAssessmentData();
  }

  // ---------------- Fetch Assessment / Quiz ----------------
  Future<Map<String, dynamic>> _fetchAssessmentData() async {
    try {
      // Common URLs for all types
      final assessmentUrl =
          'https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/${widget.moduleId}/${widget.assessmentType}';

      // Change answers endpoint based on type
      final answersUrl = widget.assessmentType == 'quiz'
          ? 'https://teambuilding-selecttraining.com/progressfile/api/api/learner/quiz-assessment-answers'
          : 'https://teambuilding-selecttraining.com/progressfile/api/api/learner/pre-assessment-answers';

      // Fetch assessment questions
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

      // Fetch previous answers
      final answersResponse = await http.post(
        Uri.parse(answersUrl),
        headers: {
          'Authorization': 'Bearer ${widget.authToken}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'module_id': widget.moduleId,
          'learner_id': 78, // TODO: Replace with actual learner ID
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

  // ---------------- Parse Previous Answers ----------------
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

  // ---------------- Submit Assessment ----------------
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

      // Submit to API
      final submitUrl =
          'https://teambuilding-selecttraining.com/progressfile/api/api/learner/assessments/submit';

      await http.post(
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

      if (mounted) {
        Navigator.of(context).pop();
        _showResultDialog(score);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit assessment')),
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

  Widget _buildQuestionCard(MCQ mcq) => Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mcq.question,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...mcq.options.map(
                (option) => RadioListTile<int>(
                  title: Text(option.optionText),
                  value: option.id,
                  groupValue: _selectedAnswers[mcq.id],
                  onChanged: (value) =>
                      setState(() => _selectedAnswers[mcq.id] = value),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLoading() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading assessment...'),
          ],
        ),
      );

  Widget _buildError(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  setState(() => _assessmentData = _fetchAssessmentData()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildPreviousAnswersBanner() {
    if (!_hasPreviousAnswers) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue),
          const SizedBox(width: 8),
          const Text('Previous answers loaded',
              style: TextStyle(color: Colors.blue)),
          const Spacer(),
          TextButton(
            onPressed: () => setState(() {
              _selectedAnswers.clear();
              _hasPreviousAnswers = false;
            }),
            child: const Text('Clear answers'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isLast, bool allAnswered) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentSectionIndex > 0)
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _currentSectionIndex--),
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black87,
                ),
              )
            else
              const SizedBox(),
            ElevatedButton.icon(
              onPressed: !allAnswered || _isSubmitting
                  ? null
                  : isLast
                      ? _submitAssessment
                      : () => setState(() => _currentSectionIndex++),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(isLast ? Icons.check : Icons.arrow_forward, size: 16),
              label: Text(
                _isSubmitting
                    ? 'Submitting...'
                    : isLast
                        ? 'Submit Assessment'
                        : 'Next Section',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      );

  // ---------------- BUILD ----------------
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
          final isLast =
              _currentSectionIndex == assessment.sections.length - 1;
          final allAnswered =
              currentSection.mcqs.every((mcq) => _selectedAnswers.containsKey(mcq.id));

          return Column(
            children: [
              _buildPreviousAnswersBanner(),
              LinearProgressIndicator(
                value: (_currentSectionIndex + 1) / assessment.sections.length,
                minHeight: 4,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Section ${_currentSectionIndex + 1} of ${assessment.sections.length}: ${currentSection.title}',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: currentSection.mcqs.length,
                  itemBuilder: (context, i) =>
                      _buildQuestionCard(currentSection.mcqs[i]),
                ),
              ),
              _buildNavigationButtons(isLast, allAnswered),
            ],
          );
        },
      ),
    );
  }
}
