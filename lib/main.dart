import 'package:flutter/material.dart';
import 'package:learning_app/landing.dart'; 
import 'package:learning_app/register/login.dart';
import 'package:learning_app/register/signup.dart';
import 'package:learning_app/screens/courses_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Check if user is logged in
  Future<bool> checkLogin() async {
    // TODO: Implement actual login check logic
    // For now, we'll return false to show the login screen
    return false;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'Learning App',
  theme: ThemeData(primarySwatch: Colors.blue),
  routes: {
    '/landing': (_) => const LandingScreen(),
    '/login': (_) => const LoginScreen(),
    '/signup': (_) => const SignupScreen(),
    '/courses': (_) => const CoursesScreen(),
  },
  home: FutureBuilder(
    future: checkLogin(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      return snapshot.data! ? const CoursesScreen() : const CoursesScreen();
    },
  ),
);
  }
}
