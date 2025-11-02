import 'package:flutter/material.dart';
import 'package:learning_app/services/api_service.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late Future<Map<String, dynamic>> _progressData;

  @override
  void initState() {
    super.initState();
    _progressData = ApiService.fetchProgressData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress File'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Display your data here
            return ListView(
              children: [
                // Example of displaying data
                ListTile(
                  title: Text('Progress Data'),
                  subtitle: Text(snapshot.data.toString()),
                ),
              ],
            );
          }
          return const Center(child: Text('No data available'));
        },
      ),
    );
  }
}