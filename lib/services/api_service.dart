import 'dart:convert';
import 'dart:ffi';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://teambuilding-selecttraining.com/progressfile';
  static const String token = '165|Gs50Y9r5gS21xCyHCtA3yiyFXPdM1nFJY2Fq9B0y264ea167';
  static const String coursesEndpoint = '/learner/courses';
  static const String modulesEndpoint = '/learner/modules';
  static const String progressDataEndpoint = '/learner/progress-data';
  
  // Headers for API requests
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Fetch progress data
  static Future<Map<String, dynamic>> fetchProgressData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };



      final response = await http.get(
        Uri.parse('$baseUrl/api/endpoint'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['message'] ?? 'Registration failed');
    }
  }

  // Login user with email and password
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Attempting login with email: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      // Print full response details
      print('🔍 Login Response:');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ Login successful');
        final token = responseData['token'];
        print('🔑 Token: ${token ?? 'No token received'}');
        print('👤 User: ${responseData['user'] ?? 'No user data'}');
        
        // Store the token in SharedPreferences
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          print('🔐 Token stored in SharedPreferences');
        }
        
        return responseData;
      } else {
        print('❌ Login failed with status: ${response.statusCode}');
        print('Error details: ${responseData.toString()}');
        throw Exception(responseData['message'] ?? 'Login failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error during login: $e');
      rethrow; // Re-throw to be handled by the caller
    }
  }
  Future<Map<String, dynamic>> getModules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };


      final response = await http.get(
        Uri.parse('$baseUrl/1/modules'),
        headers: headers,
      );

      print('Modules Response:');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load modules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching modules: $e');
    }
  }




}
