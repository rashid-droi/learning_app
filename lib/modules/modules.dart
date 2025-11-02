import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../screens/module_screen.dart';

import '../models/assessment_model.dart';

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
      id: json['id'],
      courseId: json['course_id'].toString(),
      order: json['order'].toString(),
      name: json['name'],
      details: json['details'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      assessments: json['assessments'] != null 
          ? (json['assessments'] as List).map((a) => Assessment.fromJson(a)).toList()
          : [],
    );
  }
}

class ModulesScreen extends StatefulWidget {
  final String courseId;
  
  const ModulesScreen({super.key, required this.courseId});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  List<Module> _modules = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late String _baseUrl;
  final String _token = '165|Gs50Y9r5gS21xCyHCtA3yiyFXPdM1nFJY2Fq9B0y264ea167';

  @override
  void initState() {
    super.initState();
    _baseUrl = 'https://teambuilding-selecttraining.com/progressfile/api/api/learner/courses/${widget.courseId}/modules';
    _fetchModules();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Modules'),
      ),
      body: FutureBuilder<List<Module>>(
        future: _fetchModules(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No modules available'));
          }
          
          final modules = snapshot.data!;
          return ListView.builder(
            itemCount: modules.length,
            itemBuilder: (context, index) {
              final module = modules[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModuleScreen(moduleId: module.id.toString()),
                    ),
                  );
                },

                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Module ${module.order}: ${module.name}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        module.details,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Added on ${_formatDate(module.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}