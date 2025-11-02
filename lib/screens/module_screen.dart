import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:html/parser.dart' as html_parser;
import '../models/assessment_model.dart';
import '../models/module_game_model.dart';

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

  Widget _buildAssessmentCard(Assessment assessment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: ListTile(
        title: Text(assessment.title),
        subtitle: Text('Type: ${assessment.type.toUpperCase()}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
        onTap: () {
          // Handle assessment tap
          // Navigator.push(...);
        },
      ),
    );
  }

  Widget _buildGameCard(ModuleGame? game) {
    if (game == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              game.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              _parseHtmlString(game.details),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Module Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _moduleData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Module ${moduleData['order']}: ${moduleData['name']}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8.0),
                      Text(moduleData['details']),
                      const SizedBox(height: 16.0),
                      if (!_isReflectionComplete)
                        ElevatedButton(
                          onPressed: () {
                            // Handle reflection button press
                          },
                          child: const Text('Complete Reflection'),
                        ),
                    ],
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Assessments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...assessments.map((a) => _buildAssessmentCard(a)).toList(),
                const SizedBox(height: 16.0),
                FutureBuilder<ModuleGame?>(
                  future: _moduleGame,
                  builder: (context, gameSnapshot) {
                    if (gameSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildGameCard(gameSnapshot.data);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
