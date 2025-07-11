import 'package:flutter/material.dart';
import 'screens.dart'; // Import all screens via screens.dart

// A class to handle all routes in the application
class AppRoutes {
  // Define route names as constants
  static const String home = '/';
  static const String userManagement = '/userManagement';
  static const String userLogin = '/user_login';
  static const String adminLogin = '/admin_login';
  static const String admin = '/admin';
  static const String userScreen = '/user_screen';

  // Route generator function
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          builder: (context) => const MainMenuScreen(),
        );
      case userManagement:
        return MaterialPageRoute(
          builder: (context) => const UserManagementScreen(),
        );
      case userLogin:
        return MaterialPageRoute(
          builder: (context) => const UserLoginScreen(),
        );
      case adminLogin:
        return MaterialPageRoute(
          builder: (context) => const AdminLogin(),
        );
      case admin:
        return MaterialPageRoute(
          builder: (context) => const AdminScreen(),
        );
      case userScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => UserScreen(
            userId: args?['userId'],
            userName: args?['userName'],
          ),
        );
      default:
        return null;
    }
  }
}
